import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/video_service.dart';
import '../services/user_service.dart';
import 'get_started_screen.dart';
import '../main.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    
    _animationController.forward();
    
    // Preload video during splash delay
    VideoService.preloadVideo();
    
    _checkAuthState();
  }
  
  void _checkAuthState() async {
    await Future.delayed(Duration(seconds: 2));
    
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // User is signed in, check if profile is complete
      final userProfile = await UserService.getUserProfile();
      if (userProfile != null && userProfile.firstName.isNotEmpty) {
        // Complete profile - go to home
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainNavigation()),
        );
      } else {
        // Incomplete profile - continue signup
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => GetStartedScreen()),
        );
      }
    } else {
      // No user signed in - show get started
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => GetStartedScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Gather",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Connect. Meet. Hangout.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white70,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}