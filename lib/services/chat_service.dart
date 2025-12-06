import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/chat_model.dart';

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
      final messages = snapshot.docs
          .where((doc) {
            final data = doc.data();
            final deletedFor = data['deletedFor'] as Map<String, dynamic>?;
            return deletedFor?[currentUser.uid] != true;
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
        .map((snapshot) {
          final chats = snapshot.docs.map((doc) {
            final data = doc.data();
            return {
              'chatId': doc.id,
              'participants': data['participants'] ?? [],
              'lastMessage': data['lastMessage'] ?? '',
              'lastMessageTime': data['lastMessageTime'] ?? 0,
              'unreadCount': data['unreadCount_${currentUser.uid}'] ?? 0,
            };
          }).toList();
          
          // Sort by lastMessageTime in memory
          chats.sort((a, b) => (b['lastMessageTime'] as int).compareTo(a['lastMessageTime'] as int));
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
}