import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
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

  @override
  void initState() {
    super.initState();
    // Start playing preloaded video with reduced frame rate
    // VideoService.play();
    // Reduce video processing load
    // if (VideoService.controller != null) {
    //   VideoService.controller!.setPlaybackSpeed(0.8); // Slightly slower
    // }
  }

  @override
  void dispose() {
    // Pause video to free up buffers
    // VideoService.pause();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            child: Column(
              children: [
              // Main content area - centered text
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Haule',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.12).clamp(32.0, 48.0),
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: (MediaQuery.of(context).size.height * 0.02).clamp(12.0, 16.0)),
                    Text(
                      'Your people are closer than you think',
                      style: TextStyle(
                        fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0),
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              
              // Bottom sheet container
              Container(
                width: double.infinity,

                padding: EdgeInsets.fromLTRB(
                  20,
                  16,
                  20,
                  0
                ),
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
                        color: Colors.white.withOpacity(0.1),
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
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
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