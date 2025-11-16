import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/hangout_request_model.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../services/hangout_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import 'profile_detail_screen.dart';

class HangoutInterestedUsersScreen extends StatefulWidget {
  final HangoutRequest hangout;

  const HangoutInterestedUsersScreen({super.key, required this.hangout});

  @override
  State<HangoutInterestedUsersScreen> createState() => _HangoutInterestedUsersScreenState();
}

class _HangoutInterestedUsersScreenState extends State<HangoutInterestedUsersScreen> {
  final Map<String, UserModel> _userCache = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: AppTheme.primaryColor),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('hangout_requests')
            .doc(widget.hangout.id)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text('Hangout not found'),
            );
          }
          
          final hangoutData = snapshot.data!.data() as Map<String, dynamic>;
          final currentHangout = HangoutRequest.fromMap(hangoutData, widget.hangout.id);
          
          return Column(
            children: [
              // Hangout info card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      currentHangout.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentHangout.category,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          currentHangout.location,
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Interested users list
              Expanded(
                child: currentHangout.interestedUsers.isEmpty
                    ? const Center(
                        child: Text(
                          'No one has shown interest yet',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: currentHangout.interestedUsers.length,
                        itemBuilder: (context, index) {
                          final userId = currentHangout.interestedUsers[index];
                          return FutureBuilder<UserModel?>(
                            future: _getUserData(userId),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Card(
                                  child: ListTile(
                                    leading: CircularProgressIndicator(),
                                    title: Text('Loading...'),
                                  ),
                                );
                              }
                              
                              final user = snapshot.data;
                              if (user == null) {
                                return const SizedBox();
                              }
                              
                              return Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProfileDetailScreen(user: user.toMap()),
                                      ),
                                    );
                                  },
                                  leading: CircleAvatar(
                                    backgroundImage: user.profileImageUrl != null
                                        ? NetworkImage(user.profileImageUrl!)
                                        : null,
                                    backgroundColor: AppTheme.primaryColor,
                                    child: user.profileImageUrl == null
                                        ? Text(
                                            user.firstName[0],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        : null,
                                  ),
                                  title: Text(
                                    '${user.firstName} ${user.lastName}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text('Age: ${user.age ?? 'N/A'}'),
                                  trailing: ElevatedButton(
                                    onPressed: () => _acceptUser(user, currentHangout),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppTheme.primaryColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    ),
                                    child: const Text(
                                      'Accept',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

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

  void _acceptUser(UserModel user, HangoutRequest currentHangout) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Create match between hangout creator and interested user
      await MatchService.createMatch(
        user1Id: currentUser.uid,
        user2Id: user.uid,
        hangoutTitle: currentHangout.title,
        hangoutLocation: currentHangout.location,
        hangoutDateTime: currentHangout.dateTime,
      );
      
      // Remove user from interested list but keep hangout active
      await HangoutService.acceptUser(currentHangout.id, user.uid);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Matched with ${user.firstName}! You can accept more users.'),
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
}