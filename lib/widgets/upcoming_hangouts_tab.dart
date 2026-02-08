import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../screens/profile_detail_screen.dart';
import '../screens/chat_window_screen.dart';
import '../theme/app_theme.dart';

class UpcomingHangoutsTab extends StatefulWidget {
  const UpcomingHangoutsTab({super.key});

  @override
  State<UpcomingHangoutsTab> createState() => _UpcomingHangoutsTabState();
}

class _UpcomingHangoutsTabState extends State<UpcomingHangoutsTab> {
  final Map<String, UserModel> _userCache = {};

  Future<UserModel?> _getUserData(String userId) async {
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }
    
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();
      
      if (userDoc.exists) {
        final user = UserModel.fromMap(userDoc.data()!);
        _userCache[userId] = user;
        return user;
      }
    } catch (e) {
      print('Error fetching user data: $e');
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: MatchService.getUserMatches(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final matches = snapshot.data ?? [];
          
          // Sort matches by createdAt in descending order (latest first)
          matches.sort((a, b) {
            final aCreatedAt = a['createdAt'] as Timestamp?;
            final bCreatedAt = b['createdAt'] as Timestamp?;
            if (aCreatedAt == null || bCreatedAt == null) return 0;
            return bCreatedAt.compareTo(aCreatedAt);
          });
          
          if (matches.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Matches empty image from assets
                  Image.asset(
                    'assets/images/matches_empty_transp.png',
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                  const Text(
                    "No upcoming hangouts",
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
                      "Start connecting with people to plan exciting hangouts together!",
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
          
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.6,
            ),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              return _buildMatchCard(match);
            },
          );
        },
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();
    
    final otherUserId = match['user1Id'] == currentUser.uid 
        ? match['user2Id'] 
        : match['user1Id'];
    
    return FutureBuilder<UserModel?>(
      future: _getUserData(otherUserId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final hangoutDateTime = (match['hangoutDateTime'] as Timestamp).toDate();
        final matchData = {
          'firstName': user.firstName,
          'lastName': user.lastName,
          'age': user.age ?? 25,
          'gender': user.gender,
          'education': user.education,
          'occupation': user.occupation,
          'height': user.height,
          'ethnicity': user.ethnicity ?? user.race,
          'religion': user.religion,
          'interests': user.interests,
          'hangout': match['hangoutTitle'],
          'venue': match['hangoutLocation'],
          'dateTime': hangoutDateTime,
          'image': user.profileImageUrl ?? (user.photoUrls?.isNotEmpty == true ? user.photoUrls!.first : null),
          'userId': otherUserId,
          'distance': '0 km away',
        };
        
        return GestureDetector(
          onTap: () async {
            // Fetch category from original hangout if missing
            String category = match['hangoutCategory'] ?? 'Other';
            if (category == 'Other') {
              try {
                final hangoutQuery = await FirebaseFirestore.instance
                    .collection('hangout_requests')
                    .where('title', isEqualTo: match['hangoutTitle'])
                    .where('status', isEqualTo: 'active')
                    .limit(1)
                    .get();
                
                if (hangoutQuery.docs.isNotEmpty) {
                  category = hangoutQuery.docs.first.data()['category'] ?? 'Other';
                }
              } catch (e) {
                print('Error fetching hangout category: $e');
              }
            }
            
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetailScreen(
                  user: matchData,
                  hangout: {
                    'title': match['hangoutTitle'],
                    'location': match['hangoutLocation'],
                    'dateTime': hangoutDateTime.toIso8601String(),
                    'status': match['hangoutStatus'],
                    'category': category,
                  },
                  hangoutId: match['id'],
                  showChatButton: true,
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
                GestureDetector(
                  onTap: () => _showFullImage(context, matchData['image'], user.firstName),
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: matchData['image'] != null
                          ? DecorationImage(
                              image: NetworkImage(matchData['image']),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop&crop=face'),
                              fit: BoxFit.cover,
                            ),
                      gradient: matchData['image'] == null
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            )
                          : null,
                    ),
                    child: null,
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

                // Chat/Delete Icon Button - Top Right
                Positioned(
                  top: 12,
                  right: 12,
                  child: match['hangoutStatus'] == 'deleted' || _isHangoutExpired(matchData['dateTime'])
                      ? GestureDetector(
                          onTap: () => _deleteMatch(match['id']),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ChatWindowScreen(
                                    match: {
                                      'name': '${matchData['firstName']} ${matchData['lastName']}',
                                      'firstName': matchData['firstName'],
                                      'lastName': matchData['lastName'],
                                      ...matchData,
                                    },
                                    otherUserId: matchData['userId'],
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.chat_bubble_outline,
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
                          '${matchData['firstName']} ${matchData['lastName']}, ${matchData['age']}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Colors.black,
                                blurRadius: 3,
                                offset: Offset(1, 1),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: match['hangoutStatus'] == 'deleted' 
                                ? Colors.white
                                : _isHangoutExpired(matchData['dateTime'])
                                ? Colors.white
                                : Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            match['hangoutStatus'] == 'deleted' 
                                ? 'Hangout Cancelled'
                                : _isHangoutExpired(matchData['dateTime'])
                                ? 'Hangout Expired'
                                : matchData['hangout'],
                            style: TextStyle(
                              color: match['hangoutStatus'] == 'deleted'
                                  ? AppTheme.primaryColor
                                  : _isHangoutExpired(matchData['dateTime'])
                                  ? AppTheme.primaryColor
                                  : Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (match['hangoutStatus'] != 'deleted' && !_isHangoutExpired(matchData['dateTime']))
                          const SizedBox(height: 4),
                        if (match['hangoutStatus'] != 'deleted' && !_isHangoutExpired(matchData['dateTime']))
                          Text(
                            matchData['venue'],
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        if (match['hangoutStatus'] != 'deleted' && !_isHangoutExpired(matchData['dateTime']))
                          const SizedBox(height: 2),
                        if (match['hangoutStatus'] != 'deleted' && !_isHangoutExpired(matchData['dateTime']))
                          Text(
                            _formatDateTime(matchData['dateTime']),
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 2,
                                  offset: Offset(1, 1),
                                ),
                              ],
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

  bool _isHangoutExpired(DateTime hangoutDateTime) {
    return DateTime.now().isAfter(hangoutDateTime);
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

  void _deleteMatch(String matchId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline,
                    color: AppTheme.primaryColor,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Delete Match',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Are you sure you want to delete this match? This will remove it from your matches.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          try {
                            final currentUser = FirebaseAuth.instance.currentUser;
                            if (currentUser == null) return;
                            
                            // Get match data to find other user
                            final matchDoc = await FirebaseFirestore.instance
                                .collection('matches')
                                .doc(matchId)
                                .get();
                            
                            if (matchDoc.exists) {
                              final matchData = matchDoc.data()!;
                              final otherUserId = matchData['user1Id'] == currentUser.uid 
                                  ? matchData['user2Id'] 
                                  : matchData['user1Id'];
                              
                              // Mark chat as deleted for current user
                              final sortedIds = [currentUser.uid, otherUserId]..sort();
                              final chatId = '${sortedIds[0]}_${sortedIds[1]}';
                              await FirebaseFirestore.instance
                                  .collection('chats')
                                  .doc(chatId)
                                  .set({
                                'deletedBy': {
                                  currentUser.uid: FieldValue.serverTimestamp(),
                                },
                              }, SetOptions(merge: true));
                            }
                            
                            // Delete match
                            await MatchService.deleteMatch(matchId);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Match deleted successfully'),
                                backgroundColor: AppTheme.primaryColor,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Error deleting match'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
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

  void _showFullImage(BuildContext context, String? imageUrl, String name) {
    if (imageUrl == null) return;
    
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            name[0],
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}