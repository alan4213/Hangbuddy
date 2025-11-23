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
      print('Starting OTP verification...');
      bool success = await AuthService.verifyOTP(_otp);
      print('OTP verification result: $success');
      
      if (success && mounted) {
        print('Phone verification successful');
        // Ensure phone number is stored in user profile
        await UserService.updatePhoneNumberFromAuth();
        print('Phone number stored in profile');
        
        // Now prompt for Google sign-in to link accounts
        _showGoogleLinkDialog();
      } else if (mounted) {
        print('OTP verification failed');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid OTP. Please check and try again.'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _otp = '');
      }
    } catch (e) {
      print('Exception during OTP verification: $e');
      if (mounted) {
        String errorMessage = 'Verification failed. Please try again.';
        if (e.toString().contains('invalid-verification-code')) {
          errorMessage = 'Invalid verification code. Please try again.';
        } else if (e.toString().contains('session-expired')) {
          errorMessage = 'Verification session expired. Please request a new code.';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _otp = '');
      }
    }
  }

  void _showGoogleLinkDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Link Google Account'),
        content: const Text('Please sign in with Google to complete your account setup and access all features.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/email');
            },
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _linkGoogleAccount();
            },
            child: const Text('Sign in with Google'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkGoogleAccount() async {
    try {
      print('Linking Google account to phone-verified user...');
      final googleCredential = await AuthService.getGoogleCredential();
      if (googleCredential != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Get phone number before linking
          final phoneNumber = currentUser.phoneNumber;
          print('Phone number before linking: $phoneNumber');
          
          await currentUser.linkWithCredential(googleCredential);
          print('Google account linked successfully');
          
          // Force update phone number after linking
          if (phoneNumber != null && phoneNumber.isNotEmpty) {
            await UserService.forceUpdatePhoneNumber(phoneNumber);
            print('Phone number preserved after linking: $phoneNumber');
          }
          
          // Check if user profile exists
          final userProfile = await UserService.getUserProfile();
          if (userProfile == null) {
            // New user - go to signup flow
            Navigator.pushNamed(context, '/email');
          } else {
            // Existing user - go to home
            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
          }
        }
      }
    } catch (e) {
      print('Error linking Google account: $e');
      
      if (e.toString().contains('credential-already-in-use')) {
        // Google account already exists - sign in with it instead
        try {
          print('Google account already exists, signing in with Google...');
          final result = await AuthService.signInWithGoogle();
          if (result != null) {
            // Successfully signed in with existing Google account
            final userProfile = await UserService.getUserProfile();
            if (userProfile == null) {
              Navigator.pushNamed(context, '/email');
            } else {
              Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
            }
            return;
          }
        } catch (googleError) {
          print('Error signing in with Google: $googleError');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This Google account is already registered. Please use a different Google account or continue without linking.'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to link Google account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      
      // Continue to signup even if Google linking fails
      Navigator.pushNamed(context, '/email');
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