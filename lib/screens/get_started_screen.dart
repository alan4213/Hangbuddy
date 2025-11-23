import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import 'phone_number_screen.dart';

class GetStartedScreen extends StatefulWidget {
  const GetStartedScreen({super.key});

  @override
  State<GetStartedScreen> createState() => _GetStartedScreenState();
}

class _GetStartedScreenState extends State<GetStartedScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/coffee_hangout.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay gradient
          Container(
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
              
              // Main content area - spacer
              Expanded(
                child: SizedBox(),
              ),
              
              // Bottom sheet container
              Container(
                width: double.infinity,
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.45,
                ),
                padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 16),
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
                      'Your ideal hangout. Your\nideal buddy.',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width > 600 ? 28 : 24,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                        height: 1.2,
                      ),
                    ),
                    
                    SizedBox(height: 12),
                    
                    Text(
                      'Find amazing people to explore\nactivities and create memories together.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    
                    SizedBox(height: 32),
                    
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
                    
                    SizedBox(height: 12),
                    
                    // I have an account button
                    Container(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton(
                        onPressed: () async {
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
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: AppTheme.primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Text(
                          'I have an account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
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

}