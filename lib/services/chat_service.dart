import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';
import 'notification_service.dart';
import 'user_service.dart';

class ChatService {
  static Stream<int> getUnreadMessageCount() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(0);
    
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      int totalUnread = 0;
      
      for (var doc in snapshot.docs) {
        final chatData = doc.data();
        final unreadCount = chatData['unreadCount_${currentUser.uid}'] ?? 0;
        totalUnread += unreadCount as int;
      }
      
      return totalUnread;
    });
  }
  
  static Future<void> markAsRead(String chatId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    // Mark unread count as 0
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .update({
      'unreadCount_${currentUser.uid}': 0,
    });
    
    // Mark all messages from other user as read
    final messagesSnapshot = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUser.uid)
        .where('status', whereIn: ['sent', 'delivered'])
        .get();
    
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in messagesSnapshot.docs) {
      batch.update(doc.reference, {'status': 'read'});
    }
    await batch.commit();
  }
  
  static Future<String> sendMessageWithId({
    required String receiverId, 
    required String message,
    String? replyToId,
    String? replyToMessage,
    String messageType = 'text',
    double? latitude,
    double? longitude,
    String? locationName,
    String? gifUrl,
    String? photoUrl,
    String? localPhotoPath,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('No user logged in');
    
    final chatId = _getChatId(currentUser.uid, receiverId);
    final timestamp = DateTime.now();
    
    final batch = FirebaseFirestore.instance.batch();
    
    // Add message
    final messageRef = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();
    
    batch.set(messageRef, {
      'senderId': currentUser.uid,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': 'sent',
      'reactions': {},
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'messageType': messageType,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'gifUrl': gifUrl,
      'photoUrl': photoUrl,
      'localPhotoPath': localPhotoPath,
    });
    
    // Update chat metadata
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    batch.set(chatRef, {
      'participants': [currentUser.uid, receiverId],
      'lastMessage': message,
      'lastMessageTime': timestamp.millisecondsSinceEpoch,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
    
    await batch.commit();
    
    // Send notification
    try {
      final senderProfile = await UserService.getUserProfile();
      final senderName = senderProfile != null 
          ? '${senderProfile.firstName} ${senderProfile.lastName}'.trim()
          : 'Someone';
      
      print('sendMessageWithId: From ${currentUser.uid} to $receiverId');
      await NotificationService.sendMessageNotification(
        receiverId,
        senderName.isEmpty ? 'Someone' : senderName,
        message,
        currentUser.uid,
      );
    } catch (e) {
      print('Error sending message notification: $e');
    }
    
    return messageRef.id;
  }
  
  static Future<void> updateMessagePhoto(String otherUserId, String messageId, String photoUrl) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'photoUrl': photoUrl});
  }
  
  static Future<void> updateMessagePhotoComplete(String otherUserId, String messageId, String photoUrl) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'photoUrl': photoUrl,
      'localPhotoPath': FieldValue.delete(), // Clean up local path
    });
  }
  
  static Stream<List<ChatMessage>> getMessages(String otherUserId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      // Get chat metadata to check deletedBy timestamp
      final chatDoc = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .get();
      
      final deletedByTimestamp = chatDoc.exists 
          ? (chatDoc.data()?['deletedBy']?[currentUser.uid] as Timestamp?)?.toDate()
          : null;
      
      final messages = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final deletedFor = data['deletedFor'] as Map<String, dynamic>?;
            if (deletedFor?[currentUser.uid] == true) return false;
            
            // Filter messages after deletedBy timestamp
            if (deletedByTimestamp != null) {
              final messageTime = (data['timestamp'] as Timestamp).toDate();
              if (messageTime.isAfter(deletedByTimestamp)) return false;
            }
            
            return true;
          })
          .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
          .toList();
      
      // Auto-update message status to delivered for received messages
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        if (data['receiverId'] == currentUser.uid && data['status'] == 'sent') {
          batch.update(doc.reference, {'status': 'delivered'});
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        await batch.commit();
      }
      
      return messages;
    });
  }
  
  static Future<void> sendMessage({
    required String receiverId, 
    required String message,
    String? replyToId,
    String? replyToMessage,
    String messageType = 'text',
    double? latitude,
    double? longitude,
    String? locationName,
    String? gifUrl,
    String? photoUrl,
  }) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, receiverId);
    final timestamp = DateTime.now();
    
    // Add message
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'senderId': currentUser.uid,
      'receiverId': receiverId,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'status': 'sent',
      'reactions': {},
      'replyToId': replyToId,
      'replyToMessage': replyToMessage,
      'messageType': messageType,
      'latitude': latitude,
      'longitude': longitude,
      'locationName': locationName,
      'gifUrl': gifUrl,
      'photoUrl': photoUrl,
    });
    
    // Update chat metadata
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .set({
      'participants': [currentUser.uid, receiverId],
      'lastMessage': message,
      'lastMessageTime': timestamp.millisecondsSinceEpoch,
      'unreadCount_$receiverId': FieldValue.increment(1),
    }, SetOptions(merge: true));
    
    // Send notification
    try {
      final senderProfile = await UserService.getUserProfile();
      final senderName = senderProfile != null 
          ? '${senderProfile.firstName} ${senderProfile.lastName}'.trim()
          : 'Someone';
      
      print('sendMessage: From ${currentUser.uid} to $receiverId');
      await NotificationService.sendMessageNotification(
        receiverId,
        senderName.isEmpty ? 'Someone' : senderName,
        message,
        currentUser.uid,
      );
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
  
  static Future<void> updateMessageStatus(String otherUserId, String messageId, String status) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({'status': status});
  }
  
  static Future<void> addReaction(String otherUserId, String messageId, String emoji) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'reactions.${currentUser.uid}': emoji,
    });
  }
  
  static Future<void> setTyping(String otherUserId, bool isTyping) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .set({
      'typing_${currentUser.uid}': isTyping ? DateTime.now().millisecondsSinceEpoch : null,
    }, SetOptions(merge: true));
  }
  
  static Stream<bool> getTypingStatus(String otherUserId) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value(false);
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    return FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      
      final data = doc.data()!;
      final typingTimestamp = data['typing_$otherUserId'];
      
      if (typingTimestamp == null) return false;
      
      final now = DateTime.now().millisecondsSinceEpoch;
      return (now - typingTimestamp) < 3000; // 3 seconds timeout
    });
  }
  
  static Stream<List<Map<String, dynamic>>> getChatsWithLastMessage() {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return Stream.value([]);
    
    return FirebaseFirestore.instance
        .collection('chats')
        .where('participants', arrayContains: currentUser.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          print('Debug - Total chat documents found: ${snapshot.docs.length}');
          final chats = <Map<String, dynamic>>[];
          
          for (final doc in snapshot.docs) {
            final data = doc.data();
            final deletedForCurrentUser = data['deletedFor_${currentUser.uid}'];
            print('Debug - Chat ${doc.id}: deletedFor_${currentUser.uid} = $deletedForCurrentUser');
            
            if (deletedForCurrentUser == true) continue;
            
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
            
            String? userName;
            String? userPhoto;
            
            if (otherUserId.isNotEmpty) {
              try {
                final userDoc = await FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUserId)
                    .get();
                
                if (userDoc.exists) {
                  final userData = userDoc.data()!;
                  userName = userData['firstName'] ?? '';
                  userPhoto = userData['profileImageUrl'] ?? (userData['photoUrls'] as List?)?.first;
                }
              } catch (e) {
                print('Error fetching user data: $e');
              }
            }
            
            chats.add({
              'chatId': doc.id,
              'participants': participants,
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': data['lastMessageTime'] ?? 0,
              'unreadCount': data['unreadCount_${currentUser.uid}'] ?? 0,
              'otherUserName': userName ?? 'User',
              'otherUserPhoto': userPhoto,
            });
          }
          
          chats.sort((a, b) => (b['lastMessageTime'] as int).compareTo(a['lastMessageTime'] as int));
          print('Debug - Final filtered chats count: ${chats.length}');
          return chats;
        });
  }
  
  static String getChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
  
  static Future<void> deleteMessageForMe(String otherUserId, String messageId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'deletedFor.${currentUser.uid}': true,
    });
  }
  
  static Future<void> deleteMessageForEveryone(String otherUserId, String messageId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': 'This message was deleted',
      'deletedForEveryone': true,
    });
  }
  
  static String _getChatId(String userId1, String userId2) {
    return getChatId(userId1, userId2);
  }
  
  static Future<void> restoreChatAndClearMessages(String user1Id, String user2Id) async {
    final chatId = getChatId(user1Id, user2Id);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    
    final chatDoc = await chatRef.get();
    if (!chatDoc.exists) {
      await chatRef.set({
        'participants': [user1Id, user2Id],
        'lastMessage': '',
        'lastMessageTime': 0,
      });
    } else {
      // Remove deletedBy flags when matching again
      await chatRef.update({
        'deletedBy.$user1Id': FieldValue.delete(),
        'deletedBy.$user2Id': FieldValue.delete(),
      });
    }
  }
  
  static Future<bool> checkIfOtherUserDeleted(String otherUserId) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    final chatDoc = await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .get();
    
    if (!chatDoc.exists) return false;
    
    final deletedBy = chatDoc.data()?['deletedBy'] as Map<String, dynamic>?;
    return deletedBy?.containsKey(otherUserId) ?? false;
  }
}