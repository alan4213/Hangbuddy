import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hangout_request_model.dart';
import '../services/hangout_service.dart';
import '../services/match_service.dart';
import '../services/chat_service.dart';
import '../theme/app_theme.dart';
import '../screens/hangout_interested_users_screen.dart';
import '../screens/profile_detail_screen.dart';
import '../utils/error_handler.dart';
import '../screens/match_notification_screen.dart';

class MyHangoutsTab extends StatefulWidget {
  const MyHangoutsTab({super.key});

  @override
  State<MyHangoutsTab> createState() => _MyHangoutsTabState();
}

class _MyHangoutsTabState extends State<MyHangoutsTab> {
  List<HangoutRequest> _cachedHangouts = [];
  bool _isInitialLoad = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: StreamBuilder<List<HangoutRequest>>(
        stream: HangoutService.getUserHangouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && _isInitialLoad) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final hangouts = snapshot.data ?? _cachedHangouts;
          
          // Update cache and initial load state
          if (snapshot.hasData) {
            _cachedHangouts = snapshot.data!;
            _isInitialLoad = false;
          }
          
          if (hangouts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Coffee cups image from assets
                  Image.asset(
                    'assets/images/mug_transp.png',
                    width: 280,
                    height: 280,
                    fit: BoxFit.contain,
                  ),
                  const Text(
                    'Need a plus one?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Everything is better with company.\nPost a hangout to find a partner.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/create'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text(
                      'Create Hangout',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                  _buildHangoutCard(context, hangout),
                  if (hangout.interestedUsers.isNotEmpty)
                    GridView.builder(
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
                        return _buildMatchCard(context, userId, hangout);
                      },
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildHangoutCard(BuildContext context, HangoutRequest hangout) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category image section
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_getCategoryImagePath(hangout.category)),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  // Dark overlay for better text visibility
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.3),
                        ],
                      ),
                    ),
                  ),
                  // Category badge
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
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
                  ),
                  // Delete button
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        onPressed: () => _deleteHangout(context, hangout.id),
                        icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                        style: IconButton.styleFrom(
                          padding: const EdgeInsets.all(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content section
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title
                  Text(
                    hangout.title,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Location
                  Row(
                    children: [
                      Icon(Icons.location_on, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hangout.location,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Time
                  Row(
                    children: [
                      Icon(Icons.access_time, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _formatDateTime(hangout.dateTime),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Interested users count with avatars
                  Row(
                    children: [
                      Icon(Icons.people, color: AppTheme.primaryColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        '${hangout.interestedUsers.length} interested',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (hangout.interestedUsers.isNotEmpty) const SizedBox(width: 12),
                      if (hangout.interestedUsers.isNotEmpty)
                        SizedBox(
                          height: 40,
                          width: hangout.interestedUsers.length > 3 ? 100 : (hangout.interestedUsers.length * 20 + 20),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              ...hangout.interestedUsers.take(3).toList().asMap().entries.map((entry) {
                                final index = entry.key;
                                final userId = entry.value;
                                return Positioned(
                                  left: index * 16.0,
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
                                          border: Border.all(color: AppTheme.primaryColor, width: 2),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppTheme.primaryColor.withOpacity(0.3),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: CircleAvatar(
                                          radius: 16,
                                          backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                                          backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                          child: imageUrl == null ? Text(
                                            (user['firstName'] ?? 'U')[0],
                                            style: TextStyle(color: AppTheme.primaryColor, fontSize: 12, fontWeight: FontWeight.bold),
                                          ) : null,
                                        ),
                                      );
                                    },
                                  ),
                                );
                              }).toList(),
                              if (hangout.interestedUsers.length > 3)
                                Positioned(
                                  left: 48.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: AppTheme.primaryColor, width: 2),
                                      boxShadow: [
                                        BoxShadow(
                                          color: AppTheme.primaryColor.withOpacity(0.3),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: CircleAvatar(
                                      radius: 16,
                                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                                      child: Text(
                                        '+${hangout.interestedUsers.length - 3}',
                                        style: TextStyle(color: AppTheme.primaryColor, fontSize: 10, fontWeight: FontWeight.bold),
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMatchCard(BuildContext context, String userId, HangoutRequest hangout) {
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
                    'category': hangout.category,
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
              otherUserId: userId,
            ),
          ),
        );
        print('Navigation to match notification completed');
      }
      
      print('Creating match between ${currentUser.uid} and $userId');
      
      // Restore chat and clear old messages if it was deleted
      await ChatService.restoreChatAndClearMessages(currentUser.uid, userId);
      
      // Create match in background
      await MatchService.createMatch(
        user1Id: currentUser.uid,
        user2Id: userId,
        hangoutTitle: hangout.title,
        hangoutLocation: hangout.location,
        hangoutDateTime: hangout.dateTime,
        hangoutCategory: hangout.category,
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

  String _getCategoryImagePath(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
      case 'food and drinks':
        return 'assets/images/hangout_categories/food and drinks.png';
      case 'coffee & tea':
      case 'coffee and tea':
        return 'assets/images/hangout_categories/coffee and tea.png';
      case 'movies & cinema':
      case 'movies and cinema':
        return 'assets/images/hangout_categories/movies  and cinema.png';
      case 'sports & fitness':
      case 'sports and fitness':
        return 'assets/images/hangout_categories/sports and fitness.png';
      case 'music & concerts':
      case 'music and concert':
        return 'assets/images/hangout_categories/music and concert.png';
      case 'books & reading':
      case 'books and reading':
        return 'assets/images/hangout_categories/books and reading.png';
      case 'cooking':
        return 'assets/images/hangout_categories/cooking.png';
      case 'gaming':
        return 'assets/images/hangout_categories/gaming.png';
      case 'party & nightlife':
      case 'paty and nighlife':
        return 'assets/images/hangout_categories/paty and nighlife.png';
      case 'photography':
        return 'assets/images/hangout_categories/photography.png';
      case 'shopping':
        return 'assets/images/hangout_categories/shopping.png';
      case 'study & work':
      case 'study and work':
        return 'assets/images/hangout_categories/study and work.png';
      case 'travel & adventure':
      case 'travel and adventure':
        return 'assets/images/hangout_categories/travel and adventure.png';
      case 'volunteering':
        return 'assets/images/hangout_categories/volunteering.png';
      default:
        return 'assets/images/hangout_categories/food and drinks.png';
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