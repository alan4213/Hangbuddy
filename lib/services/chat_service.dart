import 'dart:async';
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
    
    try {
      // Mark unread count as 0
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .update({
        'unreadCount_${currentUser.uid}': 0,
      });
      
      // Mark all unread messages from other user as read
      final messagesSnapshot = await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('receiverId', isEqualTo: currentUser.uid)
          .where('status', whereIn: ['sent', 'delivered'])
          .get();
      
      if (messagesSnapshot.docs.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final doc in messagesSnapshot.docs) {
          batch.update(doc.reference, {
            'status': 'read',
            'readAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
        print('✅ Marked ${messagesSnapshot.docs.length} messages as read');
      }
    } catch (e) {
      print('❌ Error marking messages as read: $e');
    }
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
    if (currentUser == null) {
      print('❌ getMessages: No current user');
      return Stream.value([]);
    }
    
    final chatId = _getChatId(currentUser.uid, otherUserId);
    print('🔄 getMessages: Fetching messages for chat $chatId');
    
    // Use a StreamController to manually combine two Firestore streams
    final controller = StreamController<List<ChatMessage>>();
    
    // Cache the latest snapshot from each stream
    QuerySnapshot<Map<String, dynamic>>? latestMessagesSnapshot;
    DocumentSnapshot<Map<String, dynamic>>? latestChatDoc;
    
    // The shared processing function — called whenever either stream fires
    Future<void> processAndEmit() async {
      if (latestMessagesSnapshot == null || latestChatDoc == null) return;
      if (controller.isClosed) return;
      
      final chatData = latestChatDoc!.data();
      
      final deletedByTimestamp = chatData != null
          ? (chatData['deletedBy']?[currentUser.uid] as Timestamp?)?.toDate()
          : null;
      
      final deletedMessagesForMe = chatData != null
          ? List<String>.from(chatData['deletedMessages_${currentUser.uid}'] ?? [])
          : <String>[];
      
      final messages = latestMessagesSnapshot!.docs
          .where((doc) {
            final data = doc.data();
            
            // Check if message was deleted for me (from chat metadata)
            if (deletedMessagesForMe.contains(doc.id)) {
              return false;
            }
            
            // Legacy: Check old per-message deletedFor field
            final deletedFor = data['deletedFor'] as Map<String, dynamic>?;
            if (deletedFor?[currentUser.uid] == true) {
              return false;
            }
            
            // Filter messages before deletedBy timestamp
            if (deletedByTimestamp != null) {
              final messageTime = (data['timestamp'] as Timestamp).toDate();
              if (messageTime.isAfter(deletedByTimestamp)) {
                return false;
              }
            }
            
            return true;
          })
          .map((doc) {
            try {
              return ChatMessage.fromMap(doc.data(), doc.id);
            } catch (e) {
              print('❌ Error parsing message ${doc.id}: $e');
              return null;
            }
          })
          .where((message) => message != null)
          .cast<ChatMessage>()
          .toList();
      
      print('✅ Final messages count: ${messages.length}');
      
      // Auto-update message status to delivered for received messages
      final batch = FirebaseFirestore.instance.batch();
      bool hasUpdates = false;
      
      for (final doc in latestMessagesSnapshot!.docs) {
        final data = doc.data();
        if (data['receiverId'] == currentUser.uid && data['status'] == 'sent') {
          batch.update(doc.reference, {
            'status': 'delivered',
            'deliveredAt': FieldValue.serverTimestamp(),
          });
          hasUpdates = true;
        }
      }
      
      if (hasUpdates) {
        try {
          await batch.commit();
        } catch (e) {
          print('❌ Error updating message statuses: $e');
        }
      }
      
      if (!controller.isClosed) {
        controller.add(messages);
      }
    }
    
    // Listen to messages subcollection
    final msgSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
      latestMessagesSnapshot = snapshot;
      processAndEmit();
    });
    
    // Listen to chat metadata doc (contains deletedMessages list)
    final chatSub = FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .snapshots()
        .listen((snapshot) {
      latestChatDoc = snapshot;
      processAndEmit();
    });
    
    // Clean up both subscriptions when the stream is cancelled
    controller.onCancel = () {
      msgSub.cancel();
      chatSub.cancel();
      controller.close();
    };
    
    return controller.stream;
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
      'timestamp': FieldValue.serverTimestamp(),
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
    
    try {
      final updateData = <String, dynamic>{'status': status};
      
      // Add timestamp based on status
      if (status == 'delivered') {
        updateData['deliveredAt'] = FieldValue.serverTimestamp();
      } else if (status == 'read') {
        updateData['readAt'] = FieldValue.serverTimestamp();
      }
      
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update(updateData);
      
      print('✅ Message $messageId status updated to $status');
    } catch (e) {
      print('❌ Error updating message status: $e');
    }
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
    
    try {
      // First ensure the chat document exists with participants
      final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
      final chatDoc = await chatRef.get();
      
      if (!chatDoc.exists) {
        // Create the chat document first
        await chatRef.set({
          'participants': [currentUser.uid, otherUserId],
          'lastMessage': '',
          'lastMessageTime': 0,
          'typing_${currentUser.uid}': isTyping ? DateTime.now().millisecondsSinceEpoch : null,
        });
      } else {
        // Update existing document
        await chatRef.update({
          'typing_${currentUser.uid}': isTyping ? DateTime.now().millisecondsSinceEpoch : null,
        });
      }
    } catch (e) {
      print('Error setting typing status: $e');
      // Don't rethrow as typing status is not critical
    }
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
          
          final futures = snapshot.docs.map((doc) async {
            final data = doc.data();
            final deletedForCurrentUser = data['deletedFor_${currentUser.uid}'];
            final deletedByCurrentUser = data['deletedBy']?[currentUser.uid];
            
            if (deletedForCurrentUser == true || deletedByCurrentUser != null) return null;
            
            final participants = List<String>.from(data['participants'] ?? []);
            final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
            
            String? userName;
            String? userPhoto;
            
            if (otherUserId.isNotEmpty) {
              if (otherUserId == 'haule_official') {
                // Handle system chat
                userName = 'Haule';
                userPhoto = 'assets/images/haule_logo.png';
              } else {
                // Handle regular user chat
                try {
                  final userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(otherUserId)
                      .get();
                  
                  if (userDoc.exists) {
                    final userData = userDoc.data()!;
                    
                    if (userData['isDeleted'] == true) {
                      userName = 'Deleted User';
                      userPhoto = null; // Use default grey avatar
                    } else {
                      userName = userData['firstName'] ?? '';
                      userPhoto = userData['profileImageUrl'] ?? (userData['photoUrls'] as List?)?.first;
                    }
                  }
                } catch (e) {
                  print('Error fetching user data: $e');
                }
              }
            }
            
            return {
              'chatId': doc.id,
              'participants': participants,
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': (data['lastMessageTime'] is int) 
                  ? data['lastMessageTime'] 
                  : (data['lastMessageTime'] as Timestamp?)?.millisecondsSinceEpoch ?? 0,
              'unreadCount': data['unreadCount_${currentUser.uid}'] ?? 0,
              'otherUserName': userName ?? 'User',
              'otherUserPhoto': data['isSystemChat'] == true ? 'assets/images/haule_logo.png' : userPhoto,
              'isSystemChat': data['isSystemChat'] ?? false,
            };
          });
          
          final results = await Future.wait(futures);
          final chats = results.whereType<Map<String, dynamic>>().toList();
          
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
    
    // Write to the chat metadata doc (both participants have access)
    // instead of the message doc (only sender has access)
    await FirebaseFirestore.instance
        .collection('chats')
        .doc(chatId)
        .set({
      'deletedMessages_${currentUser.uid}': FieldValue.arrayUnion([messageId]),
    }, SetOptions(merge: true));
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
      'messageType': 'deleted',
      'deletedForEveryone': true,
      'photoUrl': FieldValue.delete(),
      'gifUrl': FieldValue.delete(),
      'localPhotoPath': FieldValue.delete(),
      'latitude': FieldValue.delete(),
      'longitude': FieldValue.delete(),
    });
  }
  
  static String _getChatId(String userId1, String userId2) {
    return getChatId(userId1, userId2);
  }
  
  static Future<void> restoreChatAndClearMessages(String user1Id, String user2Id) async {
    final chatId = getChatId(user1Id, user2Id);
    final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
    
    print('🔄 Restoring chat: $chatId');
    print('   User1: $user1Id');
    print('   User2: $user2Id');
    print('   Current user: ${FirebaseAuth.instance.currentUser?.uid}');
    
    try {
      final chatDoc = await chatRef.get();
      if (!chatDoc.exists) {
        print('🆕 Creating new chat document');
        final chatData = {
          'participants': [user1Id, user2Id],
          'lastMessage': '',
          'lastMessageTime': 0,
          'unreadCount_$user1Id': 0,
          'unreadCount_$user2Id': 0,
        };
        print('   Chat data: $chatData');
        
        await chatRef.set(chatData);
        print('✅ New chat document created successfully');
      } else {
        print('🔄 Updating existing chat document');
        final existingData = chatDoc.data();
        print('   Existing data: $existingData');
        
        // Ensure participants field exists and remove deletedBy flags
        await chatRef.update({
          'participants': [user1Id, user2Id],
          'deletedBy.$user1Id': FieldValue.delete(),
          'deletedBy.$user2Id': FieldValue.delete(),
          'deletedFor_$user1Id': FieldValue.delete(),
          'deletedFor_$user2Id': FieldValue.delete(),
        });
        print('✅ Existing chat document updated successfully');
      }
    } catch (e) {
      print('❌ Error in restoreChatAndClearMessages: $e');
      print('   Error type: ${e.runtimeType}');
      rethrow;
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