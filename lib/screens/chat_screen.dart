import 'package:flutter/material.dart';
import '../services/match_service.dart';
import '../services/chat_service.dart';
import '../models/user_model.dart';
import 'chat_window_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final Map<String, UserModel> _userCache = {};
  final List<Color> avatarColors = [
    Color(0xFF8B5CF6),
    Color(0xFF3B82F6),
    Color(0xFFEC4899),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all((MediaQuery.of(context).size.width * 0.05).clamp(12.0, 20.0)),
          child: Column(
            children: [
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width * 0.05).clamp(16.0, 24.0)),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search conversations...',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    prefixIcon: Icon(Icons.search, color: AppTheme.primaryColor),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: (MediaQuery.of(context).size.height * 0.02).clamp(12.0, 20.0)),
                  ),
                ),
              ),
              
              SizedBox(height: (MediaQuery.of(context).size.height * 0.03).clamp(16.0, 24.0)),
            
              // Chats and Matches List
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ChatService.getChatsWithLastMessage(),
                builder: (context, chatSnapshot) {
                  if (chatSnapshot.connectionState == ConnectionState.waiting) {
                    return const LoadingWidget(
                      message: 'Loading chats...',
                      size: 32,
                    );
                  }
                  
                  final chats = chatSnapshot.data ?? [];
                  print('Debug - Chats found: ${chats.length}');
                  if (chats.isNotEmpty) {
                    print('Debug - First chat: ${chats.first}');
                  }
                  
                  if (chats.isNotEmpty) {
                    return ListView.builder(
                      itemCount: chats.length,
                      itemBuilder: (context, index) {
                        final chat = chats[index];
                        return _buildChatCard(chat);
                      },
                    );
                  }
                  
                  // Show matches if no chats exist
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: MatchService.getUserMatches(),
                    builder: (context, matchSnapshot) {
                      if (matchSnapshot.connectionState == ConnectionState.waiting) {
                        return const LoadingWidget(
                          message: 'Loading matches...',
                          size: 32,
                        );
                      }
                      
                      final matches = matchSnapshot.data ?? [];
                      
                      if (matches.isEmpty) {
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
                                  Icons.chat_bubble_outline,
                                  size: 80,
                                  color: Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(height: 24),
                              const Text(
                                "No conversations yet",
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
                                  "Accept hangout requests to start chatting with your matches!",
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
                        itemCount: matches.length,
                        itemBuilder: (context, index) {
                          final match = matches[index];
                          return _buildMatchCard(match);
                        },
                      );
                    },
                  );
                },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatCard(Map<String, dynamic> chat) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();
    
    final participants = List<String>.from(chat['participants'] ?? []);
    final otherUserId = participants.firstWhere((id) => id != currentUser.uid, orElse: () => '');
    
    print('Debug - Chat participants: $participants, otherUserId: $otherUserId');
    if (otherUserId.isEmpty) return const SizedBox();
    
    return FutureBuilder<UserModel?>(
      future: _getUserData(otherUserId),
      builder: (context, userSnapshot) {
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                CircleAvatar(radius: 28, backgroundColor: Colors.grey),
                SizedBox(width: 12),
                LoadingWidget(size: 16),
              ],
            ),
          );
        }
        
        final user = userSnapshot.data;
        if (user == null) {
          print('Debug - User not found for: $otherUserId');
          return Container(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(radius: 25, backgroundColor: Colors.red),
                SizedBox(width: 12),
                Text('User: $otherUserId'),
              ],
            ),
          );
        }
        
        final unreadCount = chat['unreadCount'] as int;
        final lastMessage = chat['lastMessage'] as String;
        
        return GestureDetector(
          onTap: () {
            ChatService.markAsRead(chat['chatId']);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatWindowScreen(
                  match: {'name': '${user.firstName} ${user.lastName}'},
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: avatarColors[otherUserId.hashCode % avatarColors.length],
                        shape: BoxShape.circle,
                        image: user.profileImageUrl != null || user.photoUrls?.isNotEmpty == true
                            ? DecorationImage(
                                image: NetworkImage(user.profileImageUrl ?? user.photoUrls!.first),
                                fit: BoxFit.cover,
                              )
                            : DecorationImage(
                                image: NetworkImage('https://picsum.photos/100/100?random=${otherUserId.hashCode % 100}'),
                                fit: BoxFit.cover,
                              ),
                      ),
                      child: user.profileImageUrl == null 
                          ? Center(
                              child: Text(
                                user.firstName[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          : null,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 0,
                        top: 0,
                        child: Container(
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 9 ? '9+' : unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lastMessage.isEmpty ? 'Start a conversation' : lastMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: unreadCount > 0 ? FontWeight.w600 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Text(
                  _formatTime(chat['lastMessageTime']),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        if (user == null) return const SizedBox();
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatWindowScreen(
                  match: {'name': '${user.firstName} ${user.lastName}'},
                  otherUserId: otherUserId,
                ),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F9FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: avatarColors[otherUserId.hashCode % avatarColors.length],
                    shape: BoxShape.circle,
                    image: user.profileImageUrl != null || user.photoUrls?.isNotEmpty == true
                        ? DecorationImage(
                            image: NetworkImage(user.profileImageUrl ?? user.photoUrls!.first),
                            fit: BoxFit.cover,
                          )
                        : DecorationImage(
                            image: NetworkImage('https://picsum.photos/100/100?random=${otherUserId.hashCode % 100}'),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: user.profileImageUrl == null 
                      ? Center(
                          child: Text(
                            user.firstName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Matched for: ${match['hangoutTitle']}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chat_bubble_outline,
                  color: Color(0xFFEF4C5E),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  String _formatTime(int timestamp) {
    if (timestamp == 0) return '';
    
    final messageTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final difference = now.difference(messageTime);
    
    if (difference.inMinutes < 1) {
      return 'now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }
}