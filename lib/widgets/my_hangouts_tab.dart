import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hangout_request_model.dart';
import '../services/hangout_service.dart';
import '../services/match_service.dart';
import '../theme/app_theme.dart';
import '../screens/hangout_interested_users_screen.dart';
import '../screens/profile_detail_screen.dart';

class MyHangoutsTab extends StatelessWidget {
  const MyHangoutsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: StreamBuilder<List<HangoutRequest>>(
        stream: HangoutService.getUserHangouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final hangouts = snapshot.data ?? [];
          
          if (hangouts.isEmpty) {
            return const Center(
              child: Text(
                'No active hangouts yet',
                style: TextStyle(fontSize: 16, color: Colors.grey),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.primaryColor,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'SF Pro Display',
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hangout.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      hangout.location,
                      style: const TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.access_time, color: Colors.white70, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    _formatDateTime(hangout.dateTime),
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.people, color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              '${hangout.interestedUsers.length} interested',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
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
                                        backgroundColor: AppTheme.primaryColor,
                                        child: imageUrl == null ? Text(
                                          (user['firstName'] ?? 'U')[0],
                                          style: const TextStyle(color: Colors.white, fontSize: 14),
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
                                      style: const TextStyle(color: Colors.white, fontSize: 12),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => _deleteHangout(context, hangout.id),
                    icon: const Icon(Icons.delete, color: Colors.white70),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.2),
                    ),
                  ),
                ],
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
      if (currentUser == null) return;
      
      await MatchService.createMatch(
        user1Id: currentUser.uid,
        user2Id: userId,
        hangoutTitle: hangout.title,
        hangoutLocation: hangout.location,
        hangoutDateTime: hangout.dateTime,
      );
      
      // Remove user from interested users list
      await HangoutService.acceptUser(hangout.id, userId);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User accepted! Match created.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
        return AlertDialog(
          title: const Text('Delete Hangout'),
          content: const Text('Are you sure you want to delete this hangout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  await HangoutService.deleteHangout(hangoutId);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hangout deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }
}