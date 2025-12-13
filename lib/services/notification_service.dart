import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/chat_window_screen.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Function(int)? onTabChange;
  static Function(int)? onMatchesTabChange;

  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Get FCM token and save to user profile
    String? token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(token);
    }

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Foreground message received: ${message.notification?.title}');
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    
    // Handle notification taps when app is in background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNotificationTap(message.data);
    });
    
    // Handle notification tap when app is terminated
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationTap(initialMessage.data);
    }
  }
  
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
        print('FCM token saved for user: ${user.uid}');
      } catch (e) {
        print('Error saving FCM token: $e');
      }
    }
  }

  static Future<String?> getToken() async {
    return await _messaging.getToken();
  }
  
  static Future<void> _sendDeviceNotification(String userId, String title, String body, [Map<String, dynamic>? data]) async {
    try {
      // Get user's FCM token
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
      final fcmToken = userDoc.data()?['fcmToken'];
      
      print('Sending notification to user: $userId');
      print('FCM Token found: ${fcmToken != null}');
      
      if (fcmToken != null) {
        // Send direct FCM notification
        await FirebaseFirestore.instance.collection('fcm_messages').add({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('FCM message queued: $title for user: $userId');
      } else {
        print('No FCM token found for user: $userId');
      }
    } catch (e) {
      print('Error sending FCM notification: $e');
    }
  }
  
  static Future<void> sendMatchNotification(String userId, String matchName) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'New Match! 🎉',
        'message': 'You matched with $matchName! Start chatting now.',
        'type': 'match',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'type': 'match',
          'screen': 'matches',
        },
      });
      
      await _sendDeviceNotification(
        userId,
        'New Match! 🎉',
        'You matched with $matchName! Start chatting now.',
        {'type': 'match', 'screen': 'matches'}
      );
    } catch (e) {
      print('Error sending match notification: $e');
    }
  }
  
  static Future<void> sendHangoutInterestNotification(String creatorId, String hangoutTitle, String hangoutId, [String interestedUserName = 'Someone']) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': creatorId,
        'title': 'Someone is interested! 🙋♂️',
        'message': '$interestedUserName wants to join your "$hangoutTitle" hangout!',
        'type': 'hangout_interest',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'type': 'hangout_interest',
          'screen': 'my_hangouts',
          'hangoutId': hangoutId,
        },
      });
      
      await _sendDeviceNotification(
        creatorId,
        'Someone is interested! 🙋♂️',
        '$interestedUserName wants to join your "$hangoutTitle" hangout!',
        {'type': 'hangout_interest', 'screen': 'my_hangouts', 'hangoutId': hangoutId}
      );
    } catch (e) {
      print('Error sending hangout interest notification: $e');
    }
  }
  
  static Future<void> sendMessageNotification(String userId, String senderName, String message, [String? senderId]) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': userId,
        'title': 'New Message 💬',
        'message': '$senderName: $message',
        'type': 'message',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'type': 'message',
          'screen': 'chat',
          'senderId': senderId,
        },
      });
      
      await _sendDeviceNotification(
        userId,
        'New Message 💬',
        '$senderName: $message',
        {'type': 'message', 'screen': 'chat', 'senderId': senderId}
      );
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
  
  static void _handleNotificationTap(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    print('Handling notification tap: $data');
    final notificationType = data['type'];
    final senderId = data['senderId'];
    print('Notification type: $notificationType');
    print('Sender ID: $senderId');
    
    // Navigate to home first
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
    
    // For message notifications, open specific chat if senderId available
    if (notificationType == 'message' && senderId != null) {
      print('Opening chat with sender: $senderId');
      
      Future.delayed(Duration(milliseconds: 200), () {
        if (onTabChange != null) {
          onTabChange!(2); // Go to chat tab first
        }
      });
      
      // Open specific chat window
      Future.delayed(Duration(milliseconds: 500), () async {
        try {
          final chatDetailScreen = await _getChatDetailScreen(senderId);
          if (chatDetailScreen != null && navigatorKey.currentContext != null) {
            Navigator.push(
              navigatorKey.currentContext!,
              MaterialPageRoute(builder: (context) => chatDetailScreen),
            );
          }
        } catch (e) {
          print('Error opening specific chat: $e');
        }
      });
    } else if (data.isEmpty || notificationType == 'message') {
      print('Going to chat tab (no senderId in notification)');
      
      Future.delayed(Duration(milliseconds: 200), () {
        if (onTabChange != null) {
          onTabChange!(2); // Just go to chat tab
        }
      });
    } else if (notificationType == 'hangout_interest') {
      print('Going to My Hangouts tab for hangout interest notification');
      
      Future.delayed(Duration(milliseconds: 200), () {
        if (onMatchesTabChange != null) {
          onMatchesTabChange!(0); // Go to "My Hangouts" tab (index 0)
        }
      });
    } else if (notificationType == 'match') {
      print('Going to Upcoming Hangouts tab for match notification');
      
      Future.delayed(Duration(milliseconds: 200), () {
        if (onMatchesTabChange != null) {
          onMatchesTabChange!(1); // Go to "Upcoming Hangouts" tab (index 1)
        }
      });
    } else {
      // Go to home tab for other notifications
      Future.delayed(Duration(milliseconds: 200), () {
        if (onTabChange != null) {
          onTabChange!(0);
        }
      });
    }
  }
  
  static Future<Widget?> _getChatDetailScreen(String senderId) async {
    try {
      print('Getting chat detail screen for sender: $senderId');
      
      // Get sender's user data
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(senderId).get();
      print('User doc exists: ${userDoc.exists}');
      
      if (!userDoc.exists) {
        print('User document not found for: $senderId');
        return null;
      }
      
      final userData = userDoc.data()!;
      final firstName = userData['firstName'] ?? '';
      final lastName = userData['lastName'] ?? '';
      print('Creating chat screen for: $firstName $lastName');
      
      // Create ChatWindowScreen with sender's data
      return ChatWindowScreen(
        match: {'name': '$firstName $lastName'},
        otherUserId: senderId,
      );
    } catch (e) {
      print('Error getting chat detail screen: $e');
      return null;
    }
  }
  
  static void setTabChangeCallback(Function(int) callback) {
    onTabChange = callback;
  }
  
  static void setMatchesTabCallback(Function(int) callback) {
    onMatchesTabChange = callback;
  }
  
  static Future<void> refreshFCMToken() async {
    try {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _saveTokenToDatabase(token);
        print('FCM token refreshed and saved');
      }
    } catch (e) {
      print('Error refreshing FCM token: $e');
    }
  }
  

  

}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}