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
      android: {
        notification: {
          channelId: 'hangbuddy_notifications',
          priority: 'high',
        },
      },
    };
    
    await getMessaging().send(message);
    console.log('Push notification sent');
    
  } catch (error) {
    console.error('Error:', error);
  }
});