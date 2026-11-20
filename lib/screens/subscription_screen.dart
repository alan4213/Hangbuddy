import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../models/subscription_model.dart';
import '../services/payment_service.dart';
import '../services/subscription_service.dart';
import '../widgets/premium_dialog.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 1; // Default to "POPULAR" plan (3 months)
  bool _isLoading = false;
  bool _isAlreadyPremium = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  final List<SubscriptionPlan> _plans = SubscriptionPlan.plans;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
    _checkExistingSubscription();
  }

  void _checkExistingSubscription() async {
    final isActive = await SubscriptionService.hasActiveSubscription();
    if (mounted) {
      setState(() => _isAlreadyPremium = isActive);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    PaymentService.dispose();
    super.dispose();
  }

  void _handleSubscribe() {
    if (_isAlreadyPremium) {
      _showAlreadyPremiumDialog();
      return;
    }

    final selectedPlan = _plans[_selectedIndex];
    setState(() => _isLoading = true);

    PaymentService.startPayment(
      plan: selectedPlan,
      onSuccess: (paymentId) {
        if (mounted) {
          setState(() => _isLoading = false);
          _showSuccessDialog(selectedPlan);
        }
      },
      onFailure: (message) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                message,
                style: GoogleFonts.poppins(fontSize: 14),
              ),
              backgroundColor: Colors.red[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );
        }
      },
    );
  }

  void _showSuccessDialog(SubscriptionPlan plan) {
    HapticFeedback.heavyImpact();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PremiumDialog(
        title: 'Welcome to Premium! 🎉',
        subtitle:
            'Your ${plan.name} plan is now active. Enjoy unlimited access to all Haule features.',
        primaryActionText: 'Let\'s Go',
        onPrimaryAction: () {
          Navigator.pop(context); // Close dialog
          Navigator.pop(context); // Go back
        },
      ),
    );
  }

  void _showAlreadyPremiumDialog() {
    showDialog(
      context: context,
      builder: (context) => PremiumDialog(
        title: 'Already Premium ✨',
        subtitle: 'You already have an active subscription. Enjoy your premium features!',
        primaryActionText: 'Got it',
        onPrimaryAction: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 120.0,
              floating: false,
              pinned: true,
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: Text(
                  'Go Premium',
                  style: GoogleFonts.poppins(
                    color: Colors.black87,
                    fontWeight: FontWeight.w700,
                    fontSize: 24,
                  ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),

                    // Hero Section
                    _buildHeroSection(),

                    const SizedBox(height: 32),

                    // Features List
                    _buildFeaturesSection(),

                    const SizedBox(height: 32),

                    // Plan Cards
                    Text(
                      'CHOOSE YOUR PLAN',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[500],
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),

                    ...List.generate(_plans.length, (index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _buildPlanCard(index),
                      );
                    }),

                    const SizedBox(height: 24),

                    // Subscribe Button
                    _buildSubscribeButton(),

                    const SizedBox(height: 16),

                    // Terms text
                    Center(
                      child: Text(
                        'By subscribing, you agree to our Terms of Service.\nCancel anytime from your profile settings.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Colors.grey[400],
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.secondaryColor,
            const Color(0xFFA78BFA),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Unlock the full\nHaule experience',
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Get more matches, unlimited hangouts, and premium features.',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.white.withOpacity(0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturesSection() {
    final features = [
      {
        'icon': Icons.all_inclusive_rounded,
        'title': 'Unlimited Hangouts',
        'subtitle': 'Create as many hangouts as you want',
      },
      {
        'icon': Icons.visibility_rounded,
        'title': 'See Who Likes You',
        'subtitle': 'Know who expressed interest first',
      },
      {
        'icon': Icons.flash_on_rounded,
        'title': 'Priority Matching',
        'subtitle': 'Your profile shown first to others',
      },
      {
        'icon': Icons.verified_rounded,
        'title': 'Premium Badge',
        'subtitle': 'Stand out with a verified premium tag',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WHAT YOU GET',
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[500],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        ...features.map((f) => _buildFeatureItem(
              f['icon'] as IconData,
              f['title'] as String,
              f['subtitle'] as String,
            )),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(int index) {
    final plan = _plans[index];
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedIndex = index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            // Radio indicator
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppTheme.primaryColor : Colors.grey[300]!,
                  width: 2,
                ),
                color: isSelected ? AppTheme.primaryColor : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 16),

            // Plan details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        plan.duration,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.black87 : Colors.black54,
                        ),
                      ),
                      if (plan.badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            gradient: plan.badge == 'BEST VALUE'
                                ? AppTheme.accentGradient
                                : AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            plan.badge!,
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  if (plan.months > 1)
                    Text(
                      '₹${plan.perMonthPrice}/month',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.grey[500],
                      ),
                    ),
                ],
              ),
            ),

            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '₹${plan.displayPrice}',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? AppTheme.primaryColor : Colors.black87,
                  ),
                ),
                if (plan.months > 1)
                  Text(
                    _getSavingsText(plan),
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF10B981),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSavingsText(SubscriptionPlan plan) {
    final monthlyTotal = 79 * plan.months;
    final savings = monthlyTotal - plan.displayPrice;
    if (savings <= 0) return '';
    final percent = ((savings / monthlyTotal) * 100).round();
    return 'Save $percent%';
  }

  Widget _buildSubscribeButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSubscribe,
      child: Container(
        height: 60,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(colors: [Colors.grey[400]!, Colors.grey[500]!])
              : AppTheme.primaryGradient,
          borderRadius: BorderRadius.circular(30),
          boxShadow: _isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: _isLoading
                  ? Row(
                      children: [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Processing...',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      'Subscribe — ₹${_plans[_selectedIndex].displayPrice}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
            if (!_isLoading)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: AppTheme.primaryColor,
                    size: 22,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

