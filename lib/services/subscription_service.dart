import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  static final _firestore = FirebaseFirestore.instance;
  static UserSubscription? _cachedSubscription;

  /// Check if current user has an active subscription
  static Future<bool> hasActiveSubscription() async {
    final subscription = await getCurrentSubscription();
    return subscription != null && subscription.isActive;
  }

  /// Get the current user's subscription
  static Future<UserSubscription?> getCurrentSubscription() async {
    if (_cachedSubscription != null && _cachedSubscription!.isActive) {
      return _cachedSubscription;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .orderBy('endDate', descending: true)
          .limit(1)
          .get();

      if (doc.docs.isEmpty) return null;

      final subscription = UserSubscription.fromMap(doc.docs.first.data());
      
      // If subscription has expired, update status
      if (!subscription.isActive) {
        await doc.docs.first.reference.update({'status': 'expired'});
        _cachedSubscription = null;
        return null;
      }

      _cachedSubscription = subscription;
      return subscription;
    } catch (e) {
      print('Error getting subscription: $e');
      return null;
    }
  }

  /// Save subscription after successful payment
  static Future<void> saveSubscription({
    required String planId,
    required String paymentId,
    required String orderId,
    required int amountPaid,
    required int months,
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');

    final now = DateTime.now();
    final endDate = DateTime(now.year, now.month + months, now.day);

    final subscriptionData = {
      'planId': planId,
      'status': 'active',
      'startDate': now.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'paymentId': paymentId,
      'orderId': orderId,
      'amountPaid': amountPaid,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Save to subscriptions subcollection
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .add(subscriptionData);

    // Also update user doc for quick access
    await _firestore.collection('users').doc(uid).update({
      'isPremium': true,
      'subscriptionPlanId': planId,
      'subscriptionEndDate': endDate.toIso8601String(),
    });

    // Clear cache so it re-fetches
    _cachedSubscription = null;
  }

  /// Stream subscription status for real-time UI updates
  static Stream<bool> subscriptionStatusStream() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(false);

    return _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return false;
      final sub = UserSubscription.fromMap(snapshot.docs.first.data());
      return sub.isActive;
    });
  }

  /// Clear cached subscription (on logout)
  static void clearCache() {
    _cachedSubscription = null;
  }
}

