import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class OTPScreen extends StatefulWidget {
  const OTPScreen({super.key});

  @override
  State<OTPScreen> createState() => _OTPScreenState();
}

class _OTPScreenState extends State<OTPScreen> {
  int _secondsRemaining = 60;
  Timer? _timer;
  String _otp = "";

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    _secondsRemaining = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _verifyOTP() async {
    try {
      bool success = await AuthService.verifyOTP(_otp);
      if (success && mounted) {
        // Check if user profile exists
        final userProfile = await UserService.getUserProfile();
        if (userProfile == null) {
          // New user - go to signup flow
          Navigator.pushNamed(context, '/email');
        } else {
          // Existing user - go to home
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invalid OTP')),
        );
        setState(() => _otp = '');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification failed. Please try again.')),
        );
        setState(() => _otp = '');
      }
    }
  }

  void _onNumberTap(String value) {
    if (_otp.length < 6) {
      HapticFeedback.selectionClick();
      setState(() {
        _otp += value;
      });
      if (_otp.length == 6) {
        HapticFeedback.mediumImpact();
        _verifyOTP();
      }
    }
  }

  void _onDelete() {
    if (_otp.isNotEmpty) {
      HapticFeedback.lightImpact();
      setState(() {
        _otp = _otp.substring(0, _otp.length - 1);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Timer with circle
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "00:${_secondsRemaining.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Verify Your Number',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Enter the 6-digit code we sent\nto your phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              // OTP boxes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    bool filled = index < _otp.length;
                    return Flexible(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 56,
                        constraints: const BoxConstraints(maxWidth: 48),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: filled ? AppTheme.primaryColor : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: filled ? AppTheme.primaryColor : Colors.grey.shade300,
                            width: 2,
                          ),
                        ),
                        child: Text(
                          filled ? _otp[index] : "",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: filled ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 48),
              // Numeric keypad
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 1.2,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index < 9) {
                      return _buildNumberButton((index + 1).toString());
                    } else if (index == 9) {
                      return const SizedBox.shrink();
                    } else if (index == 10) {
                      return _buildNumberButton('0');
                    } else {
                      return _buildDeleteButton();
                    }
                  },
                ),
              ),
              // Send again
              GestureDetector(
                onTap: _secondsRemaining == 0 ? () => startTimer() : null,
                child: Text(
                  _secondsRemaining == 0 ? 'Resend Code' : 'Resend in ${_secondsRemaining}s',
                  style: TextStyle(
                    color: _secondsRemaining == 0 ? AppTheme.primaryColor : Colors.grey,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberButton(String number) {
    return AnimatedScale(
      scale: 1.0,
      duration: const Duration(milliseconds: 100),
      child: InkWell(
        onTap: () => _onNumberTap(number),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return InkWell(
      onTap: _onDelete,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(
            Icons.backspace_outlined,
            size: 24,
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}