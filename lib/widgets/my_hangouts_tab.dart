import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hangout_request_model.dart';
import '../services/hangout_service.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../screens/hangout_interested_users_screen.dart';
import '../screens/profile_detail_screen.dart';
import '../widgets/tutorial_overlay.dart';
import '../utils/error_handler.dart';
import '../screens/match_notification_screen.dart';

class MyHangoutsTab extends StatefulWidget {
  const MyHangoutsTab({super.key});

  @override
  State<MyHangoutsTab> createState() => _MyHangoutsTabState();
}

class _MyHangoutsTabState extends State<MyHangoutsTab> {
  // Tutorial keys
  final GlobalKey _hangoutCardKey = GlobalKey();
  final GlobalKey _interestedUsersKey = GlobalKey();
  final GlobalKey _acceptButtonKey = GlobalKey();
  bool _showTutorial = false;
  bool _hasHangouts = false;

  void _checkAndShowTutorial(List<HangoutRequest> hangouts) {
    if (hangouts.isNotEmpty && hangouts.any((h) => h.interestedUsers.isNotEmpty) && !_hasHangouts) {
      _hasHangouts = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myHangoutsContent = Padding(
      padding: const EdgeInsets.all(12.0),
      child: StreamBuilder<List<HangoutRequest>>(
        stream: HangoutService.getUserHangouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final hangouts = snapshot.data ?? [];
          _checkAndShowTutorial(hangouts);
          
          if (hangouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F4F8),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: const Icon(
                      Icons.add_circle_outline,
                      size: 80,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    "No hangouts created",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 40),
                    child: Text(
                      "Create your first hangout and start connecting with people!",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: hangouts.length,
            itemBuilder: (context, index) {
              final hangout = hangouts[index];
              return Column(
                children: [
                  _buildHangoutCard(context, hangout, index == 0),
                  if (hangout.interestedUsers.isNotEmpty)
                    GridView.builder(
                      key: index == 0 ? _interestedUsersKey : null,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: hangout.interestedUsers.length,
                      itemBuilder: (context, userIndex) {
                        final userId = hangout.interestedUsers[userIndex];
                        return _buildMatchCard(context, userId, hangout, index == 0 && userIndex == 0);
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
    
    if (_showTutorial) {
      return TutorialOverlay(
        steps: [
          TutorialStep(
            title: 'Accept People',
            description: 'Tap the check button to accept someone into your hangout. This will create a match and start a conversation.',
            targetKey: _acceptButtonKey,
            bubblePosition: const Offset(20, 500),
          ),
        ],
        onComplete: () {
          setState(() {
            _showTutorial = false;
          });
          TutorialService.markTutorialCompleted('my_hangouts');
        },
        child: myHangoutsContent,
      );
    }
    
    return myHangoutsContent;
  }

  Widget _buildHangoutCard(BuildContext context, HangoutRequest hangout, [bool isFirst = false]) {
    return Container(
      key: isFirst ? _hangoutCardKey : null,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.25),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    hangout.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    hangout.category,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.location_on, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    hangout.location,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.access_time, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Text(
                  _formatDateTime(hangout.dateTime),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.people, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            '${hangout.interestedUsers.length} interested',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: hangout.interestedUsers.length > 3 ? 80 : (hangout.interestedUsers.length * 20 + 20),
                      height: 40,
                      child: Stack(
                        children: [
                          ...hangout.interestedUsers.take(3).toList().asMap().entries.map((entry) {
                            final index = entry.key;
                            final userId = entry.value;
                            return Positioned(
                              left: index * 15.0,
                              child: FutureBuilder<Map<String, dynamic>?>(
                                future: _getUserData(userId),
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData) return const SizedBox();
                                  final user = snapshot.data!;
                                  final imageUrl = user['profileImageUrl'] ?? 
                                      (user['photoUrls']?.isNotEmpty == true ? user['photoUrls'][0] : null);
                                  return Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    child: CircleAvatar(
                                      radius: 18,
                                      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                                      backgroundColor: Colors.white.withOpacity(0.3),
                                      child: imageUrl == null ? Text(
                                        (user['firstName'] ?? 'U')[0],
                                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                      ) : null,
                                    ),
                                  );
                                },
                              ),
                            );
                          }).toList(),
                          if (hangout.interestedUsers.length > 3)
                            Positioned(
                              left: 45.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                ),
                                child: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Colors.white.withOpacity(0.3),
                                  child: Text(
                                    '+${hangout.interestedUsers.length - 3}',
                                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: IconButton(
                    onPressed: () => _deleteHangout(context, hangout.id),
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    style: IconButton.styleFrom(
                      padding: const EdgeInsets.all(8),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, String userId, HangoutRequest hangout, [bool isFirst = false]) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: _getUserData(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return Container(
            margin: const EdgeInsets.all(4),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        final user = snapshot.data!;
        final imageUrl = user['profileImageUrl'] ?? 
            (user['photoUrls']?.isNotEmpty == true ? user['photoUrls'][0] : null);
        
        return GestureDetector(
          onTap: () {
            final matchData = {
              'firstName': user['firstName'],
              'lastName': user['lastName'],
              'age': user['age'] ?? 25,
              'gender': user['gender'],
              'education': user['education'],
              'occupation': user['occupation'],
              'height': user['height'],
              'ethnicity': user['ethnicity'],
              'religion': user['religion'],
              'interests': user['interests'],
              'image': user['profileImageUrl'] ?? (user['photoUrls']?.isNotEmpty == true ? user['photoUrls'][0] : null),
              'userId': userId,
              'distance': '0 km away',
            };
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetailScreen(
                  user: matchData,
                  hangout: {
                    'title': hangout.title,
                    'location': hangout.location,
                    'dateTime': hangout.dateTime.toIso8601String(),
                  },
                  hangoutId: hangout.id,
                  onMatch: () {},
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Background Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(imageUrl),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop&crop=face'),
                              fit: BoxFit.cover,
                            ),
                      gradient: imageUrl == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            )
                          : null,
                    ),
                  ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.transparent,
                          Colors.black.withOpacity(0.8),
                        ],
                      ),
                    ),
                  ),
                  // Interest Badge - Top Right
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'Interested',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Accept Button - Bottom Right
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: GestureDetector(
                      onTap: () => _acceptUser(context, userId, hangout),
                      child: Container(
                        key: isFirst ? _acceptButtonKey : null,
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  // User Info at Bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${user['firstName'] ?? 'User'} ${user['lastName'] ?? ''}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Age: ${user['age'] ?? '0'}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
        );
      },
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now).inDays;
    
    if (difference == 0) {
      return 'Today ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference == 1) {
      return 'Tomorrow ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }

  void _acceptUser(BuildContext context, String userId, HangoutRequest hangout) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('No current user found');
        return;
      }
      
      // Get user data for match notification first
      final userData = await _getUserData(userId);
      print('User data for match notification: $userData');
      
      if (userData != null && mounted) {
        final userName = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
        print('Navigating to match notification with user: $userName');
        
        // Show match notification screen immediately
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MatchNotificationScreen(
              user: {
                'name': userName.isEmpty ? 'User' : userName,
                'image': userData['profileImageUrl'],
              },
            ),
          ),
        );
        print('Navigation to match notification completed');
      }
      
      print('Creating match between ${currentUser.uid} and $userId');
      
      // Create match in background
      await MatchService.createMatch(
        user1Id: currentUser.uid,
        user2Id: userId,
        hangoutTitle: hangout.title,
        hangoutLocation: hangout.location,
        hangoutDateTime: hangout.dateTime,
      );
      
      print('Match created successfully');
      
      // Remove user from interested users list
      await HangoutService.acceptUser(hangout.id, userId);
      
      print('User removed from interested list');
      
    } catch (e) {
      print('Error in _acceptUser: $e');
    }
  }

  Future<Map<String, dynamic>?> _getUserData(String userId) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      return doc.exists ? doc.data() : null;
    } catch (e) {
      return null;
    }
  }

  void _deleteHangout(BuildContext context, String hangoutId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Hangout',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Are you sure you want to delete this hangout?',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 44,
                        decoration: BoxDecoration(
                          color: Color(0xFF6366F1),
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: TextButton(
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              await HangoutService.deleteHangout(hangoutId);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Hangout deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ErrorHandler.showErrorSnackBar(
                                context,
                                e,
                                onRetry: () => _deleteHangout(context, hangoutId),
                                retryLabel: 'Try Again',
                              );
                            }
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}