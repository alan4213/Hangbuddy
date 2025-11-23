import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';

class PhoneNumberScreen extends StatefulWidget {
  final bool showGoogleSignIn;
  const PhoneNumberScreen({super.key, this.showGoogleSignIn = false});

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController _controller = TextEditingController();
  String _fullPhoneNumber = '';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const SizedBox(height: 60),
              // Gather Brand Name
              Text(
                'Gather',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Welcome',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.showGoogleSignIn 
                    ? 'Sign in to your account'
                    : 'Enter your phone number to get started',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 48),
              // Phone input field - only for new users
              if (!widget.showGoogleSignIn) ...[
                IntlPhoneField(
                  controller: _controller,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: TextStyle(color: AppTheme.primaryColor),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  initialCountryCode: 'US',
                  onChanged: (phone) {
                    _fullPhoneNumber = phone.completeNumber;
                  },
                ),
              ],
              const SizedBox(height: 24),
              
              // Google sign-in button for existing users only
              if (widget.showGoogleSignIn) ...[
                Container(
                  width: double.infinity,
                  height: 50,
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        final result = await AuthService.signInWithGoogle();
                        if (result != null && mounted) {
                          final userProfile = await UserService.getUserProfile();
                          if (userProfile == null) {
                            // New Google user - continue with signup
                            Navigator.pushNamed(context, '/email');
                          } else {
                            // Existing user - go to home
                            Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                          }
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Google sign-in failed: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                      if (mounted) setState(() => _isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                      elevation: 0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              ],
              
              const Spacer(),
              // Continue button - only for new users
              if (!widget.showGoogleSignIn)
                LoadingButton(
                  isLoading: _isLoading,
                  text: 'Continue',
                  onPressed: () async {
                    if (_fullPhoneNumber.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a valid phone number')),
                      );
                      return;
                    }
                    
                    setState(() => _isLoading = true);
                    try {
                      await AuthService.sendOTP(_fullPhoneNumber);
                      if (mounted) {
                        Navigator.pushNamed(context, '/otp');
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    } finally {
                      if (mounted) {
                        setState(() => _isLoading = false);
                      }
                    }
                  },
                ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}