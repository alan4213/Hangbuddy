const {onDocumentCreated} = require('firebase-functions/v2/firestore');
const {initializeApp} = require('firebase-admin/app');
const {getFirestore} = require('firebase-admin/firestore');
const {getMessaging} = require('firebase-admin/messaging');

initializeApp();

exports.sendPushNotification = onDocumentCreated('notifications/{notificationId}', async (event) => {
  const notification = event.data.data();
  
  try {
    const userDoc = await getFirestore()
      .collection('users')
      .doc(notification.userId)
      .get();
    
    if (!userDoc.exists) return;
    
    const fcmToken = userDoc.data().fcmToken;
    if (!fcmToken) return;
    
    const message = {
      token: fcmToken,
      notification: {
        title: notification.title,
        body: notification.message,
      },
      data: notification.data || {},
      android: {
        notification: {
          channelId: 'hangbuddy_notifications',
          priority: 'high',
        },
      },
    };
    
    console.log('Sending notification with data:', notification.data);
    await getMessaging().send(message);
    console.log('Push notification sent');
    
  } catch (error) {
    console.error('Error:', error);
  }
});

exports.sendFCMNotifications = onDocumentCreated('fcm_messages/{messageId}', async (event) => {
  const data = event.data.data();
  
  try {
    const message = {
      token: data.token,
      notification: {
        title: data.title,
        body: data.body,
      },
      data: data.data || {},
      android: {
        notification: {
          channelId: 'hangbuddy_notifications',
          priority: 'high',
        },
      },
    };
    
    console.log('Sending FCM with data:', data.data);
    await getMessaging().send(message);
    console.log('FCM notification sent');
    
    // Delete the processed message
    await event.data.ref.delete();
    
  } catch (error) {
    console.error('FCM Error:', error);
  }
});