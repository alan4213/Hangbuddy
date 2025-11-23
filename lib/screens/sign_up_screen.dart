import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../models/signup_data.dart';
import 'name_screen.dart';

class GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    
    // Blue section
    paint.color = Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.57, // -90 degrees
      1.57,  // 90 degrees
      true,
      paint,
    );
    
    // Red section
    paint.color = Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      0,     // 0 degrees
      1.57,  // 90 degrees
      true,
      paint,
    );
    
    // Yellow section
    paint.color = Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      1.57,  // 90 degrees
      1.57,  // 90 degrees
      true,
      paint,
    );
    
    // Green section
    paint.color = Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      3.14,  // 180 degrees
      1.57,  // 90 degrees
      true,
      paint,
    );
    
    // White center circle
    paint.color = Colors.white;
    canvas.drawCircle(center, radius * 0.4, paint);
    
    // G letter
    paint.color = Color(0xFF4285F4);
    paint.style = PaintingStyle.fill;
    
    final textPainter = TextPainter(
      text: TextSpan(
        text: 'G',
        style: TextStyle(
          color: Color(0xFF4285F4),
          fontSize: size.width * 0.6,
          fontWeight: FontWeight.bold,
          fontFamily: 'Roboto',
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withOpacity(0.1),
                  AppTheme.backgroundColor,
                ],
              ),
            ),
          ),
          Column(
            children: [
              SafeArea(
                child: SizedBox(),
              ),
                // Header
                Padding(
                  padding: EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Gather',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      SizedBox(),
                    ],
                  ),
                ),
                
                // Main content area
                Expanded(
                  child: Container(
                    width: double.infinity,
                    margin: EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: AppTheme.primaryGradient.scale(0.3),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(50),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.favorite,
                              size: 50,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Bottom sheet container
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, -5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start Your Hangout\nJourney',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.2,
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      Text(
                        'Connect with like-minded people and\nexplore amazing experiences together.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                          height: 1.4,
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      

                      // Continue with Google
                      GestureDetector(
                        onTap: _signInWithGoogle,
                        child: Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            border: Border.all(color: Colors.grey[400]!, width: 2),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                child: Stack(
                                  children: [
                                    // Google G logo recreation
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white,
                                      ),
                                      child: CustomPaint(
                                        painter: GoogleLogoPainter(),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: 12),
                              Text(
                                _loading ? 'Signing in...' : 'Sign in with Google',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 12),
                      
                      // Continue with Phone
                      Container(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _loading ? null : () {
                            Navigator.pushNamed(context, '/email');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(25),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.phone, size: 18, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Continue with Phone',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    print('BUTTON CLICKED - _signInWithGoogle method called');
    setState(() => _loading = true);
    try {
      print('Starting Google sign-in...');
      final result = await AuthService.signInWithGoogle();
      if (result != null && mounted) {
        print('Google sign-in successful, checking user profile...');
        // Check if user profile exists
        final userProfile = await UserService.getUserProfile();
        if (userProfile == null) {
          print('New Google user - navigating to name screen with Google info');
          // New user - go to signup flow with Google account info
          final signupData = SignupData();
          if (result.user?.displayName != null) {
            final nameParts = result.user!.displayName!.split(' ');
            signupData.firstName = nameParts.first;
            if (nameParts.length > 1) {
              signupData.lastName = nameParts.skip(1).join(' ');
            }
          }
          signupData.email = result.user?.email;
          
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NameScreen(signupData: signupData),
            ),
          );
        } else {
          print('Existing Google user - navigating to home');
          // Existing user - go to home
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        print('Google sign-in cancelled or failed');
      }
    } catch (e) {
      print('Google sign-in error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
    if (mounted) setState(() => _loading = false);
  }
}