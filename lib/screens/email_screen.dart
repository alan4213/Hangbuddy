import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'name_screen.dart';

class EmailScreen extends StatefulWidget {
  const EmailScreen({super.key});

  @override
  State<EmailScreen> createState() => _EmailScreenState();
}

class _EmailScreenState extends State<EmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  bool _otpSent = false;

  @override
  void initState() {
    super.initState();
    _checkEmailVerification();
  }

  void _checkEmailVerification() async {
    setState(() => _isLoading = true);
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
        final updatedUser = FirebaseAuth.instance.currentUser;
        
        if (updatedUser != null && updatedUser.emailVerified) {
          // Email is verified, store email and proceed
          await UserService.updateUserProfile(email: _emailController.text);
          
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => NameScreen(signupData: SignupData()),
              ),
            );
          }
        } else {
          // Email not verified yet
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Email not verified yet. Please check your email and click the verification link.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error checking verification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    setState(() => _isLoading = false);
  }

  // Check if there's a phone-verified account that should be merged
  Future<User?> _checkForPhoneAccount(String? email) async {
    if (email == null) return null;
    
    try {
      // This is a simplified check - you might want to implement more sophisticated logic
      // based on your app's requirements
      return null;
    } catch (e) {
      print('Error checking for phone account: $e');
      return null;
    }
  }
  
  // Merge phone-verified account with Google account
  Future<void> _mergePhoneWithGoogle(User phoneUser, User googleUser) async {
    try {
      print('Merging phone account with Google account...');
      
      // Get phone number from the phone user
      final phoneNumber = phoneUser.phoneNumber;
      
      if (phoneNumber != null) {
        // Add phone number to Google account
        await AuthService.mergePhoneAndGoogleAccounts(phoneNumber);
        
        // Clean up the old phone-only account
        await AuthService.cleanupDuplicateAccount(phoneUser.uid);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accounts merged successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error merging accounts: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to merge accounts: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _otpSent ? 'Verify Email' : 'Connect Your Account',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.07,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                'Link your Google account for seamless sign-in and backup.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.06),
              
              // Google sign-in button
                Container(
                  width: double.infinity,
                  height: MediaQuery.of(context).size.height * 0.06,
                  margin: EdgeInsets.only(bottom: MediaQuery.of(context).size.height * 0.02),
                  child: ElevatedButton(
                    onPressed: () async {
                      setState(() => _isLoading = true);
                      try {
                        final GoogleSignIn googleSignIn = GoogleSignIn();
                        await googleSignIn.signOut();
                        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
                        
                        if (googleUser != null) {
                          final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
                          final AuthCredential credential = GoogleAuthProvider.credential(
                            accessToken: googleAuth.accessToken,
                            idToken: googleAuth.idToken,
                          );
                          
                          final currentUser = FirebaseAuth.instance.currentUser;
                          if (currentUser != null) {
                            // Link Google to existing phone account
                            await currentUser.linkWithCredential(credential);
                            await UserService.updateUserProfile(email: googleUser.email!);
                          }
                          
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => NameScreen(signupData: SignupData()),
                            ),
                          );
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Google sign-in failed: $e')),
                        );
                      }
                      setState(() => _isLoading = false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppTheme.primaryColor,
                      elevation: 0,
                      side: BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          child: Text(
                            'G',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Continue with Google',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              
              SizedBox(height: MediaQuery.of(context).size.height * 0.04),
              
              Container(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => NameScreen(signupData: SignupData()),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  child: Text(
                    'Skip for now',
                    style: TextStyle(
                      color: AppTheme.primaryColor,
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      fontWeight: FontWeight.w600,
                    ),
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
}