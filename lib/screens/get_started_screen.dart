import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/video_service.dart';
import 'phone_number_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  bool _isLoading = false;
  PageController _pageController = PageController();
  int _currentPage = 0;
  final List<String> _images = [
    'assets/images/loginm1.png',
    'assets/images/ymage.png',
  ];

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Full-bleed background with scrollable images
          Positioned.fill(
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index % _images.length;
                });
              },
              itemBuilder: (context, index) {
                final imageIndex = index % _images.length;
                return Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_images[imageIndex]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
          ),
          // Overlay gradient
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
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
            ),
          ),
          // Foreground content
          SafeArea(
            child: Column(
              children: [
                // Heading at top
                Padding(
                  padding: EdgeInsets.only(top: 40, left: 20, right: 20),
                  child: Column(
                    children: [
                      Text(
                        'Haule',
                        style: GoogleFonts.inter(
                          fontSize: (MediaQuery.of(context).size.width * 0.16).clamp(48.0, 64.0),
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Where hangouts begin.',
                        style: GoogleFonts.inter(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                
                Spacer(),
                
                // Bottom sheet container
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular((MediaQuery.of(context).size.width * 0.08).clamp(24.0, 32.0)),
                      topRight: Radius.circular((MediaQuery.of(context).size.width * 0.08).clamp(24.0, 32.0)),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: (MediaQuery.of(context).size.height * 0.02).clamp(16.0, 24.0)),
                      
                      // Page indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: _images.asMap().entries.map((entry) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentPage == entry.key 
                                  ? Colors.white 
                                  : Colors.white.withOpacity(0.4),
                            ),
                          );
                        }).toList(),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Terms and Privacy text
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                            children: [
                              TextSpan(text: 'By tapping "Create an account", you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: TextStyle(
                                  decoration: TextDecoration.underline,
                                  color: Colors.white,
                                ),
                              ),
                              TextSpan(text: '.'),
                            ],
                          ),
                        ),
                      ),
                      
                      SizedBox(height: 16),
                      
                      // Create an account button
                      LoadingButton(
                        isLoading: _isLoading,
                        text: 'Create an account',
                        fontSize: 14,
                        backgroundColor: AppTheme.primaryColor,
                        onPressed: () async {
                          setState(() => _isLoading = true);
                          await Future.delayed(const Duration(milliseconds: 500));
                          if (mounted) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhoneNumberScreen(showGoogleSignIn: false),
                              ),
                            ).then((_) {
                              if (mounted) setState(() => _isLoading = false);
                            });
                          }
                        },
                      ),
                      
                      SizedBox(height: (MediaQuery.of(context).size.height * 0.02).clamp(12.0, 16.0)),
                      
                      // I have an account button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          child: InkWell(
                            onTap: () async {
                              setState(() => _isLoading = true);
                              try {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PhoneNumberScreen(showGoogleSignIn: true),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Sign in failed: $e')),
                                );
                              }
                              if (mounted) setState(() => _isLoading = false);
                            },
                            borderRadius: BorderRadius.circular(28),
                            child: Container(
                              alignment: Alignment.center,
                              child: Text(
                                'I have an account',
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}