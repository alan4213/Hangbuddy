import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

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
    
    // Handle notification taps
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('Notification tapped: ${message.data}');
    });
  }
  
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/ic_notification');
    
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    
    await _localNotifications.initialize(initializationSettings);
    
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
  
  static Future<void> _sendDeviceNotification(String userId, String title, String body) async {
    // Cloud Function will handle FCM push notifications automatically
    // when notification document is created in Firestore
    print('Notification document created - Cloud Function will send FCM: $title');
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
      });
      
      await _sendDeviceNotification(
        userId,
        'New Match! 🎉',
        'You matched with $matchName! Start chatting now.'
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
      });
      
      await _sendDeviceNotification(
        creatorId,
        'Someone is interested! 🙋♂️',
        'Someone wants to join your "$hangoutTitle" hangout!'
      );
    } catch (e) {
      print('Error sending hangout interest notification: $e');
    }
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message: ${message.notification?.title}');
}