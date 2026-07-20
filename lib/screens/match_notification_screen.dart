import 'package:flutter/material.dart';
import 'chat_window_screen.dart';
import '../theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';

class MatchNotificationScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final String otherUserId;
  
  const MatchNotificationScreen({super.key, required this.user, required this.otherUserId});

  @override
  State<MatchNotificationScreen> createState() => _MatchNotificationScreenState();
}

class _MatchNotificationScreenState extends State<MatchNotificationScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  String? _currentUserImage;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserImage();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 1200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.bounceOut),
    );
    
    // Start animation after a short delay
    Future.delayed(Duration(milliseconds: 100), () {
      if (mounted) {
        _animationController.forward();
      }
    });
  }
  
  void _loadCurrentUserImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists && mounted) {
          final userData = userDoc.data()!;
          setState(() {
            _currentUserImage = userData['profileImageUrl'];
          });
        }
      } catch (e) {
        print('Error loading current user image: $e');
      }
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Overlapping profile circles
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: SizedBox(
                    width: 200,
                    height: 120,
                    child: Stack(
                      children: [
                        // Current user's profile (left circle)
                        Positioned(
                          left: 0,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 47,
                              backgroundImage: _currentUserImage != null 
                                  ? CachedNetworkImageProvider(_currentUserImage!) 
                                  : null,
                              backgroundColor: AppTheme.primaryColor,
                              child: _currentUserImage == null
                                  ? Text(
                                      'You',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        // Match's profile (right circle)
                        Positioned(
                          right: 0,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: CircleAvatar(
                              radius: 47,
                              backgroundImage: widget.user['image'] != null 
                                  ? CachedNetworkImageProvider(widget.user['image']!) 
                                  : null,
                              backgroundColor: AppTheme.secondaryColor,
                              child: widget.user['image'] == null 
                                  ? Text(
                                      (widget.user['name'] ?? 'U')[0],
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ),
                        // Handshake icon in center
                        Positioned(
                          left: 77, // Adjusted slightly left for the larger size (100 - 46/2)
                          top: 37, // Adjusted slightly down (120/2 - 46/2)
                          child: Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(2.0),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: Text(
                                    '🤝',
                                    style: TextStyle(fontSize: 18),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Congrats text
                Text(
                  'Congrats!',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryColor,
                  ),
                ),
                
                SizedBox(height: 16),
                
                Text(
                  'It\'s a Match!',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                
                SizedBox(height: 8),
                
                Text(
                  'Start a conversation now with each other',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
                
                SizedBox(height: 40),
                
                // Action buttons
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24), // Reduced from 40 for more room
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushNamedAndRemoveUntil(
                                context,
                                '/home',
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[200],
                              foregroundColor: Colors.grey[600],
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Discover Hangouts',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatWindowScreen(
                                    match: {
                                      'name': widget.user['name'] ?? 'User',
                                      'image': widget.user['image'],
                                    },
                                    otherUserId: widget.otherUserId,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Say Hello',
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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