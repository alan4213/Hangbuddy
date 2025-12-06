import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static Function(int)? onTabChange;

  static Future<void> initialize() async {
    // Initialize local notifications
    await _initializeLocalNotifications();
    
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

    // Handle foreground messages - show local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      _showLocalNotification(message);
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
  
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null) {
          final data = Map<String, dynamic>.from(
            Uri.splitQueryString(response.payload!)
          );
          _handleNotificationTap(data);
        }
      },
    );
    
    // Create notification channel
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'hangbuddy_notifications',
      'Hangbuddy Notifications',
      description: 'Notifications for matches, messages, and hangouts',
      importance: Importance.high,
    );
    
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }
  
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    final payload = Uri(queryParameters: message.data).query;
    
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'hangbuddy_notifications',
      'Hangbuddy Notifications',
      channelDescription: 'Notifications for matches, messages, and hangouts',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title ?? 'Hangbuddy',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: payload,
    );
  }
  
  static Future<void> _saveTokenToDatabase(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fcmToken': token,
        }, SetOptions(merge: true));
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
      
      if (fcmToken != null) {
        // Send direct FCM notification
        await FirebaseFirestore.instance.collection('fcm_messages').add({
          'token': fcmToken,
          'title': title,
          'body': body,
          'data': data ?? {},
          'timestamp': FieldValue.serverTimestamp(),
        });
        print('FCM message queued: $title');
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
  
  static Future<void> sendHangoutInterestNotification(String creatorId, String hangoutTitle) async {
    try {
      await FirebaseFirestore.instance.collection('notifications').add({
        'userId': creatorId,
        'title': 'Someone is interested! 🙋♂️',
        'message': 'Someone wants to join your "$hangoutTitle" hangout!',
        'type': 'hangout_interest',
        'read': false,
        'timestamp': FieldValue.serverTimestamp(),
        'data': {
          'type': 'hangout_interest',
          'screen': 'notifications',
        },
      });
      
      await _sendDeviceNotification(
        creatorId,
        'Someone is interested! 🙋♂️',
        'Someone wants to join your "$hangoutTitle" hangout!',
        {'type': 'hangout_interest', 'screen': 'notifications'}
      );
    } catch (e) {
      print('Error sending hangout interest notification: $e');
    }
  }
  
  static Future<void> sendMessageNotification(String userId, String senderName, String message) async {
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
        },
      });
      
      await _sendDeviceNotification(
        userId,
        'New Message 💬',
        '$senderName: $message',
        {'type': 'message', 'screen': 'chat'}
      );
    } catch (e) {
      print('Error sending message notification: $e');
    }
  }
  
  static void _handleNotificationTap(Map<String, dynamic> data) {
    final context = navigatorKey.currentContext;
    if (context == null) return;
    
    final type = data['type'];
    
    // Navigate to home first
    Navigator.pushNamedAndRemoveUntil(
      context,
      '/home',
      (route) => false,
    );
    
    // Then navigate to appropriate tab
    Future.delayed(Duration(milliseconds: 200), () {
      if (onTabChange != null) {
        switch (type) {
          case 'match':
            onTabChange!(1); // Matches tab
            break;
          case 'hangout_interest':
            onTabChange!(3); // Profile tab (notifications)
            break;
          case 'message':
            onTabChange!(2); // Chat tab
            break;
          default:
            onTabChange!(0); // Home tab
            break;
        }
      }
    });
  }
  
  static void setTabChangeCallback(Function(int) callback) {
    onTabChange = callback;
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}