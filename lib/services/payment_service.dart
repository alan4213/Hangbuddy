import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/subscription_model.dart';
import 'subscription_service.dart';
import 'user_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PaymentService {
  static Razorpay? _razorpay;
  static Function(String paymentId)? _onSuccess;
  static Function(String message)? _onFailure;
  static SubscriptionPlan? _currentPlan;

  /// Initialize Razorpay instance
  static void initialize() {
    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  /// Open Razorpay checkout for a subscription plan
  static Future<void> startPayment({
    required SubscriptionPlan plan,
    required Function(String paymentId) onSuccess,
    required Function(String message) onFailure,
  }) async {
    if (_razorpay == null) initialize();

    _onSuccess = onSuccess;
    _onFailure = onFailure;
    _currentPlan = plan;

    final user = FirebaseAuth.instance.currentUser;
    final userProfile = UserService.cachedProfile;

    final razorpayKey = dotenv.env['RAZORPAY_KEY_ID'] ?? '';
    if (razorpayKey.isEmpty) {
      onFailure('Payment configuration error. Please try again later.');
      return;
    }

    var options = {
      'key': razorpayKey,
      'amount': plan.priceInPaise,
      'name': 'Haule Premium',
      'description': '${plan.name} Subscription',
      'currency': 'INR',
      'prefill': {
        'contact': user?.phoneNumber ?? '',
        'email': userProfile?.email ?? user?.email ?? '',
      },
      'theme': {
        'color': '#6366F1',
      },
      'notes': {
        'planId': plan.id,
        'userId': user?.uid ?? '',
        'months': plan.months.toString(),
      },
    };

    try {
      _razorpay!.open(options);
    } catch (e) {
      onFailure('Could not open payment gateway. Please try again.');
    }
  }

  static void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    final paymentId = response.paymentId ?? '';
    final orderId = response.orderId ?? '';

    try {
      if (_currentPlan != null) {
        await SubscriptionService.saveSubscription(
          planId: _currentPlan!.id,
          paymentId: paymentId,
          orderId: orderId,
          amountPaid: _currentPlan!.displayPrice,
          months: _currentPlan!.months,
        );
      }
      _onSuccess?.call(paymentId);
    } catch (e) {
      _onFailure?.call('Payment succeeded but subscription save failed. Contact support with ID: $paymentId');
    }
  }

  static void _handlePaymentError(PaymentFailureResponse response) {
    final message = response.message ?? 'Payment failed';
    _onFailure?.call(message);
  }

  static void _handleExternalWallet(ExternalWalletResponse response) {
    // External wallet selected — payment will complete via wallet flow
  }

  /// Dispose Razorpay instance
  static void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}

