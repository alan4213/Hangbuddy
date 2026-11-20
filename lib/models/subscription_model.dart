class SubscriptionPlan {
  final String id;
  final String name;
  final String duration;
  final int priceInPaise; // Razorpay uses paise
  final int displayPrice; // In rupees
  final int? perMonthPrice; // For showing savings
  final String? badge; // e.g., "POPULAR", "BEST VALUE"
  final int months;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.duration,
    required this.priceInPaise,
    required this.displayPrice,
    this.perMonthPrice,
    this.badge,
    required this.months,
  });

  static const List<SubscriptionPlan> plans = [
    SubscriptionPlan(
      id: 'monthly',
      name: 'Monthly',
      duration: '1 Month',
      priceInPaise: 7900,
      displayPrice: 79,
      perMonthPrice: 79,
      months: 1,
    ),
    SubscriptionPlan(
      id: 'quarterly',
      name: '3 Months',
      duration: '3 Months',
      priceInPaise: 19900,
      displayPrice: 199,
      perMonthPrice: 66,
      badge: 'POPULAR',
      months: 3,
    ),
    SubscriptionPlan(
      id: 'annual',
      name: 'Annual',
      duration: '1 Year',
      priceInPaise: 79900,
      displayPrice: 799,
      perMonthPrice: 67,
      badge: 'BEST VALUE',
      months: 12,
    ),
  ];
}

class UserSubscription {
  final String planId;
  final String status; // 'active', 'expired', 'cancelled'
  final DateTime startDate;
  final DateTime endDate;
  final String paymentId;
  final String orderId;
  final int amountPaid;

  const UserSubscription({
    required this.planId,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.paymentId,
    required this.orderId,
    required this.amountPaid,
  });

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());

  factory UserSubscription.fromMap(Map<String, dynamic> map) {
    return UserSubscription(
      planId: map['planId'] ?? '',
      status: map['status'] ?? 'expired',
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      paymentId: map['paymentId'] ?? '',
      orderId: map['orderId'] ?? '',
      amountPaid: map['amountPaid'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'planId': planId,
      'status': status,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'paymentId': paymentId,
      'orderId': orderId,
      'amountPaid': amountPaid,
    };
  }
}

