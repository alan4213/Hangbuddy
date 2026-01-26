import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:video_player/video_player.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/video_service.dart';
import '../theme/app_theme.dart';

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
  void initState() {
    super.initState();
    // VideoService.play();
  }

  void _showEmailSignInDialog() {
    final emailController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign in with Email'),
        content: TextField(
          controller: emailController,
          decoration: InputDecoration(
            labelText: 'Email Address',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _signInWithEmail(emailController.text);
            },
            child: Text('Send Link'),
          ),
        ],
      ),
    );
  }
  
  Future<void> _signInWithEmail(String email) async {
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid email')),
      );
      return;
    }
    
    setState(() => _isLoading = true);
    
    try {
      await AuthService.sendEmailLink(email);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign-in link sent to $email. Check your email and click the link to sign in.'),
          duration: Duration(seconds: 5),
          backgroundColor: Colors.green,
        ),
      );
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send sign-in link: $e')),
      );
    }
    
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Full-bleed background - use preloaded video or fallback
          // VideoService.isInitialized && VideoService.controller != null
          //     ? SizedBox.expand(
          //         child: FittedBox(
          //           fit: BoxFit.cover,
          //           child: SizedBox(
          //             width: VideoService.controller!.value.size.width,
          //             height: VideoService.controller!.value.size.height,
          //             child: VideoPlayer(VideoService.controller!),
          //           ),
          //         ),
          //       )
          //     : 
          Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage('assets/images/coffee_hangout.png'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
          // Overlay gradient - also ignores system insets
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
          // Foreground content - respects system insets
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  SizedBox(height: 20),
                  // Back button
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Icon(Icons.arrow_back, color: Colors.white, size: 24),
                      ),
                    ],
                  ),
              
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                    // Gather logo
                    Container(
                      margin: EdgeInsets.only(bottom: 60),
                      child: Text(
                        'Gather',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    
                    // Terms text
                    Container(
                      margin: EdgeInsets.only(bottom: 40),
                      child: Text(
                        'By tapping Create Account or Sign In, you agree to our\nTerms. Learn how we process your data in our Privacy\nPolicy and Cookies Policy.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.4,
                        ),
                      ),
                    ),
                    
                    // Sign in buttons
                    if (widget.showGoogleSignIn) ...[
                      // Google sign-in button
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: EdgeInsets.only(bottom: 16),
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            setState(() => _isLoading = true);
                            try {
                              final result = await AuthService.signInWithGoogle();
                              if (result != null && mounted) {
                                final userProfile = await UserService.getUserProfile();
                                if (userProfile == null) {
                                  Navigator.pushNamed(context, '/email');
                                } else {
                                  Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                                }
                              }
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Google sign-in failed: $e'), backgroundColor: Colors.red),
                              );
                            }
                            if (mounted) setState(() => _isLoading = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  color: Color(0xFF4285F4),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Center(
                                  child: Text('G', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                ),
                              ),
                              Text(
                                _isLoading ? 'SIGNING IN...' : 'SIGN IN WITH GOOGLE',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      // Continue with phone number button
                      Container(
                        width: double.infinity,
                        height: 50,
                        margin: EdgeInsets.only(bottom: 16),
                        child: OutlinedButton(
                          onPressed: _isLoading ? null : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneNumberScreen(showGoogleSignIn: false),
                              ),
                            );
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(color: Colors.white, width: 2),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'CONTINUE WITH PHONE',
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      

                    ] else ...[
                      // Phone input for new users
                      Container(
                        margin: EdgeInsets.only(bottom: 20),
                        child: IntlPhoneField(
                          controller: _controller,
                          style: TextStyle(color: Colors.white),
                          dropdownTextStyle: TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            labelText: 'Phone Number',
                            labelStyle: TextStyle(color: Colors.white.withOpacity(0.8)),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(25),
                              borderSide: BorderSide(color: Colors.white, width: 2),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          ),
                          initialCountryCode: 'IN',
                          dropdownIcon: Icon(Icons.arrow_drop_down, color: Colors.white),
                          onChanged: (phone) => _fullPhoneNumber = phone.completeNumber,
                        ),
                      ),
                      
                      // Continue button
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : () async {
                            if (_fullPhoneNumber.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Please enter a valid phone number')),
                              );
                              return;
                            }
                            
                            setState(() => _isLoading = true);
                            
                            try {
                              print('=== PHONE CHECK DEBUG ===');
                              print('Phone number to check: $_fullPhoneNumber');
                              
                              // Check if phone number already exists
                              bool phoneExists = await UserService.checkPhoneNumberExists(_fullPhoneNumber);
                              print('Phone exists result: $phoneExists');
                              
                              if (phoneExists) {
                                print('Phone exists - showing error');
                                await showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: Row(
                                      children: [
                                        Container(
                                          width: 40,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            gradient: AppTheme.primaryGradient,
                                            borderRadius: BorderRadius.circular(20),
                                          ),
                                          child: Icon(Icons.phone_locked, color: Colors.white, size: 24),
                                        ),
                                        SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Phone Already Registered',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.textPrimary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    content: Text(
                                      'This phone number is already registered. Please use a different number or sign in with your existing account.',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: AppTheme.textSecondary,
                                        height: 1.4,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                        ),
                                        child: Text(
                                          'OK',
                                          style: TextStyle(
                                            color: AppTheme.primaryColor,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                                setState(() => _isLoading = false);
                                return;
                              }
                              
                              print('Phone is unique - sending OTP');
                              await AuthService.sendOTP(_fullPhoneNumber);
                              if (mounted) {
                                Navigator.pushNamed(context, '/otp');
                              }
                            } catch (e) {
                              print('=== ERROR IN PHONE CHECK ===');
                              print('Error: $e');
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Error: $e'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                setState(() => _isLoading = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                            elevation: 0,
                          ),
                          child: Text(
                            _isLoading ? 'SENDING...' : 'CONTINUE',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.5),
                          ),
                        ),
                      ),
                    ],
                      SizedBox(height: 20),
                      
                      // Trouble signing in
                      if (widget.showGoogleSignIn)
                        GestureDetector(
                          onTap: () {
                            // Handle trouble signing in
                          },
                          child: Padding(
                            padding: EdgeInsets.only(bottom: 20),
                            child: Text(
                              'Trouble Signing In?',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}