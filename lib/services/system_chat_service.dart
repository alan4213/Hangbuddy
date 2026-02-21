import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SystemChatService {
  static const String SYSTEM_USER_ID = 'haule_official';
  static const String SYSTEM_USER_NAME = 'Haule';
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  /// Create system chat for a new user
  static Future<void> createSystemChatForUser(String userId) async {
    try {
      final chatId = _getChatId(SYSTEM_USER_ID, userId);
      
      // Create chat document
      await _firestore.collection('chats').doc(chatId).set({
        'participants': [SYSTEM_USER_ID, userId],
        'lastMessage': 'Welcome to Haule! 🎉',
        'lastMessageTime': DateTime.now().millisecondsSinceEpoch,
        'unreadCount_$userId': 1,
        'isSystemChat': true,
      });
      
      // Send welcome message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': SYSTEM_USER_ID,
        'receiverId': userId,
        'message': 'Welcome to Haule! 🎉\n\nWe\'re excited to have you here. Start creating hangouts and connecting with amazing people nearby!\n\nNeed help? Just send us a message anytime.',
        'timestamp': Timestamp.now(),
        'status': 'sent',
        'reactions': {},
        'messageType': 'text',
      });
      
      print('System chat created for user: $userId');
    } catch (e) {
      print('Error creating system chat: $e');
    }
  }
  
  /// Check if system chat exists for user
  static Future<bool> systemChatExists(String userId) async {
    try {
      final chatId = _getChatId(SYSTEM_USER_ID, userId);
      final doc = await _firestore.collection('chats').doc(chatId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking system chat: $e');
      return false;
    }
  }
  
  /// Send a system message to a specific user
  static Future<void> sendSystemMessage(String userId, String message) async {
    try {
      final chatId = _getChatId(SYSTEM_USER_ID, userId);
      final timestamp = DateTime.now();
      
      // Add message
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add({
        'senderId': SYSTEM_USER_ID,
        'receiverId': userId,
        'message': message,
        'timestamp': Timestamp.fromDate(timestamp),
        'status': 'sent',
        'reactions': {},
        'messageType': 'text',
      });
      
      // Update chat metadata
      await _firestore.collection('chats').doc(chatId).update({
        'lastMessage': message,
        'lastMessageTime': timestamp.millisecondsSinceEpoch,
        'unreadCount_$userId': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error sending system message: $e');
    }
  }
  
  /// Broadcast message to all users
  static Future<void> broadcastMessage(String message) async {
    try {
      final usersSnapshot = await _firestore.collection('users').get();
      
      for (final userDoc in usersSnapshot.docs) {
        await sendSystemMessage(userDoc.id, message);
      }
      
      print('Broadcast message sent to ${usersSnapshot.docs.length} users');
    } catch (e) {
      print('Error broadcasting message: $e');
    }
  }
  
  static String _getChatId(String userId1, String userId2) {
    final sortedIds = [userId1, userId2]..sort();
    return '${sortedIds[0]}_${sortedIds[1]}';
  }
}
