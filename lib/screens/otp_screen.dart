import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/account_manager.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';

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
        
        // Check if user already has a complete profile
        final userProfile = await UserService.getUserProfile();
        if (userProfile != null && userProfile.firstName.isNotEmpty) {
          print('Existing user with complete profile - navigating to home');
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        } else {
          print('New user or incomplete profile - proceeding to email screen');
          Navigator.pushNamed(context, '/email');
        }
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
        title: const Text('Complete Account Setup'),
        content: const Text('Would you like to link a Google account for easier sign-in, or continue with just your phone number?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/email');
            },
            child: const Text('Continue with Phone'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _linkGoogleAccount();
            },
            child: const Text('Link Google Account'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkGoogleAccount() async {
    try {
      print('Attempting to link Google account...');
      final googleCredential = await AuthService.getGoogleCredential();
      if (googleCredential == null) return;
      
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Store current phone number
      final phoneNumber = currentUser.phoneNumber;
      print('Current phone number: $phoneNumber');
      
      // Check if Google account already exists
      final googleEmail = googleCredential.accessToken != null ? 
        await _getGoogleEmail(googleCredential) : null;
      
      if (googleEmail != null) {
        // Check if this Google account already has a user
        final existingUser = await _checkExistingGoogleUser(googleEmail);
        if (existingUser != null) {
          // Merge accounts instead of creating duplicate
          await _mergeAccounts(currentUser, existingUser, phoneNumber);
          return;
        }
      }
      
      // Link Google account to current phone-verified user
      await currentUser.linkWithCredential(googleCredential);
      print('Google account linked successfully');
      
      // Preserve phone number after linking
      if (phoneNumber != null) {
        await UserService.forceUpdatePhoneNumber(phoneNumber);
      }
      
      // Continue with normal flow
      final userProfile = await UserService.getUserProfile();
      if (userProfile == null) {
        Navigator.pushNamed(context, '/email');
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
      
    } catch (e) {
      print('Error linking Google account: $e');
      
      if (e.toString().contains('credential-already-in-use')) {
        await _handleCredentialAlreadyInUse();
      } else {
        _showLinkingError(e.toString());
        Navigator.pushNamed(context, '/email');
      }
    }
  }
  
  Future<String?> _getGoogleEmail(AuthCredential credential) async {
    try {
      // This is a simplified approach - in practice you'd decode the ID token
      return null; // Implement based on your needs
    } catch (e) {
      return null;
    }
  }
  
  Future<User?> _checkExistingGoogleUser(String email) async {
    try {
      final methods = await FirebaseAuth.instance.fetchSignInMethodsForEmail(email);
      return methods.contains('google.com') ? 
        await FirebaseAuth.instance.currentUser : null;
    } catch (e) {
      return null;
    }
  }
  
  Future<void> _mergeAccounts(User phoneUser, User googleUser, String? phoneNumber) async {
    try {
      print('Merging phone and Google accounts...');
      
      // Sign in with Google account (the existing one)
      final result = await AuthService.signInWithGoogle();
      if (result != null && phoneNumber != null) {
        // Add phone number to the Google account
        await UserService.forceUpdatePhoneNumber(phoneNumber);
        
        // Delete the phone-only account data if needed
        await _cleanupPhoneOnlyAccount(phoneUser.uid);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accounts merged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
      }
    } catch (e) {
      print('Error merging accounts: $e');
      _showLinkingError('Failed to merge accounts');
    }
  }
  
  Future<void> _cleanupPhoneOnlyAccount(String phoneUserUid) async {
    try {
      // Clean up any data from the phone-only account
      // This prevents duplicate user records
      print('Cleaning up phone-only account: $phoneUserUid');
    } catch (e) {
      print('Error cleaning up phone account: $e');
    }
  }
  
  Future<void> _handleCredentialAlreadyInUse() async {
    try {
      print('Google credential already in use, attempting to merge...');
      final result = await AuthService.signInWithGoogle();
      if (result != null) {
        final userProfile = await UserService.getUserProfile();
        if (userProfile == null) {
          Navigator.pushNamed(context, '/email');
        } else {
          Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        }
      }
    } catch (e) {
      _showLinkingError('This Google account is already registered');
      Navigator.pushNamed(context, '/email');
    }
  }
  
  void _showLinkingError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.padding(context, Responsive.mediumPadding),
            vertical: Responsive.padding(context, 0.015),
          ),
          child: Column(
            children: [
              SizedBox(height: Responsive.padding(context, 0.05)),
              // Timer with circle
              Container(
                width: Responsive.padding(context, 0.2),
                height: Responsive.padding(context, 0.2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    "00:${_secondsRemaining.toString().padLeft(2, '0')}",
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              SizedBox(height: Responsive.padding(context, 0.04)),
              Text(
                'Verify Your Number',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, Responsive.titleFontSize),
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: Responsive.padding(context, 0.015)),
              Text(
                'Enter the 6-digit code we sent\nto your phone number',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
                  color: Colors.grey,
                ),
              ),
              SizedBox(height: Responsive.padding(context, 0.06)),
              // OTP boxes
              Padding(
                padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, Responsive.mediumPadding)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) {
                    bool filled = index < _otp.length;
                    return Flexible(
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 0.01)),
                        height: Responsive.padding(context, 0.14),
                        constraints: BoxConstraints(maxWidth: Responsive.padding(context, 0.12)),
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
                            fontSize: Responsive.fontSize(context, Responsive.headingFontSize),
                            fontWeight: FontWeight.bold,
                            color: filled ? Colors.white : Colors.black,
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              SizedBox(height: Responsive.padding(context, 0.06)),
              // Numeric keypad
              Expanded(
                child: GridView.builder(
                  padding: EdgeInsets.symmetric(horizontal: Responsive.padding(context, 0.1)),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: Responsive.padding(context, 0.04),
                    crossAxisSpacing: Responsive.padding(context, 0.04),
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
                    fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
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
              style: TextStyle(
                fontSize: Responsive.fontSize(context, Responsive.titleFontSize),
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
            size: Responsive.fontSize(context, Responsive.titleFontSize),
            color: AppTheme.primaryColor,
          ),
        ),
      ),
    );
  }
}