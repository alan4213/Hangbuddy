import 'package:flutter/material.dart';
import 'match_notification_screen.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/match_service.dart';
import '../services/hangout_service.dart';
import 'chat_window_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onMatch;
  final Map<String, dynamic>? hangout;
  final String? hangoutId;
  final bool showChatButton;

  const ProfileDetailScreen({super.key, required this.user, this.onMatch, this.hangout, this.hangoutId, this.showChatButton = false});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  Map<String, dynamic>? _freshUserData;
  
  @override
  void initState() {
    super.initState();
    _loadFreshUserData();
  }
  
  Future<void> _loadFreshUserData() async {
    try {
      String? targetUid = widget.user['uid'] ?? widget.user['userId'];
      
      if (targetUid == null || targetUid.isEmpty) {
        if (widget.user['phoneNumber'] != null) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('phoneNumber', isEqualTo: widget.user['phoneNumber'])
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            targetUid = querySnapshot.docs.first.id;
          }
        }
      }
      
      if (targetUid == null) return;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _freshUserData = doc.data()!;
        });
      }
    } catch (e) {
      print('Error loading fresh user data: $e');
    }
  }
  
  Map<String, dynamic> get currentUser => _freshUserData ?? widget.user;
  
  List<String> get images {
    final List<String> userImages = [];
    
    final photoUrls = currentUser['photoUrls'] as List?;
    if (photoUrls != null && photoUrls.isNotEmpty) {
      for (final photo in photoUrls) {
        if (photo != null && photo.toString().startsWith('http')) {
          userImages.add(photo);
        }
      }
    }
    
    if (userImages.isEmpty) {
      final mainImage = currentUser['profileImageUrl'] ?? currentUser['image'];
      if (mainImage != null && mainImage.toString().startsWith('http')) {
        userImages.add(mainImage);
      }
    }
    
    if (userImages.isEmpty) {
      userImages.add('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400');
    }
    
    return userImages;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.arrow_back, color: Colors.black),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                        Container(
                          width: double.infinity,
                          height: 400,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: images.isEmpty
                                ? Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.person, size: 80, color: Colors.grey),
                                  )
                                : Container(
                                    width: double.infinity,
                                    height: double.infinity,
                                    decoration: BoxDecoration(
                                      image: DecorationImage(
                                        image: NetworkImage(images[0]),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          color: Colors.white,
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${widget.user['firstName'] ?? ''} ${widget.user['lastName'] ?? ''}${widget.user['age'] != null ? ', ${widget.user['age']}' : ''}',
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        if (widget.user['gender'] != null)
                                          Text(
                                            widget.user['gender']!,
                                            style: TextStyle(
                                              fontSize: 16,
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  if (widget.hangout != null && widget.hangoutId != null && !widget.showChatButton)
                                    GestureDetector(
                                      onTap: () async {
                                        final currentUser = FirebaseAuth.instance.currentUser;
                                        if (currentUser == null) return;
                                        
                                        try {
                                          await MatchService.createMatch(
                                            user1Id: currentUser.uid,
                                            user2Id: widget.user['userId'] ?? widget.user['uid'] ?? '',
                                            hangoutTitle: widget.hangout!['title'],
                                            hangoutLocation: widget.hangout!['location'],
                                            hangoutDateTime: DateTime.parse(widget.hangout!['dateTime']),
                                          );
                                          
                                          await HangoutService.acceptUser(widget.hangoutId!, widget.user['userId'] ?? widget.user['uid'] ?? '');
                                          
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Matched with ${widget.user['firstName'] ?? 'User'}! You can accept more users.'),
                                              backgroundColor: Colors.green,
                                            ),
                                          );
                                          
                                          Navigator.pop(context);
                                        } catch (e) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Error: $e'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.check, color: Colors.white, size: 28),
                                      ),
                                    ),
                                  if (widget.showChatButton)
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) => ChatWindowScreen(
                                              match: {
                                                'name': '${widget.user['firstName']} ${widget.user['lastName']}',
                                                'firstName': widget.user['firstName'],
                                                'lastName': widget.user['lastName'],
                                                ...widget.user,
                                              },
                                              otherUserId: widget.user['userId'] ?? widget.user['uid'] ?? '',
                                            ),
                                          ),
                                        );
                                      },
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryColor,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.2),
                                              blurRadius: 8,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: const Icon(Icons.chat_bubble_outline, color: Colors.white, size: 28),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              if (widget.hangout != null && widget.showChatButton)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Matched Hangout',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: AppTheme.textSecondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        widget.hangout!['title'] ?? 'Hangout',
                                        style: TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Icon(Icons.location_on, size: 16, color: AppTheme.textSecondary),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              widget.hangout!['location'] ?? 'Location',
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 16, color: AppTheme.textSecondary),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.hangout!['dateTime'] != null
                                                ? _formatDateTime(DateTime.parse(widget.hangout!['dateTime']))
                                                : 'Date & Time',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        if (widget.user['age'] != null)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(Icons.cake, size: 20, color: AppTheme.textSecondary),
                                                const SizedBox(width: 8),
                                                Text('${widget.user['age']}', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                                              ],
                                            ),
                                          ),
                                        if (widget.user['gender'] != null)
                                          Expanded(
                                            child: Row(
                                              children: [
                                                Icon(Icons.person, size: 20, color: AppTheme.textSecondary),
                                                const SizedBox(width: 8),
                                                Text(widget.user['gender']!, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary)),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    if (widget.user['occupation'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.work, size: 20, color: AppTheme.textSecondary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.user['occupation']!,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (widget.user['education'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.school, size: 20, color: AppTheme.textSecondary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.user['education']!,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (widget.user['religion'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.church, size: 20, color: AppTheme.textSecondary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.user['religion']!,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (widget.user['ethnicity'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.public, size: 20, color: AppTheme.textSecondary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.user['ethnicity']!,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                    ],
                                    if (widget.user['height'] != null) ...[
                                      Row(
                                        children: [
                                          Icon(Icons.height, size: 20, color: AppTheme.textSecondary),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              widget.user['height']!,
                                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppTheme.textPrimary),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (images.length > 1)
                                Container(
                                  width: double.infinity,
                                  height: 300,
                                  margin: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      images[1],
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                ),
                              if (currentUser['interests'] != null && (currentUser['interests'] as List).isNotEmpty)
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  margin: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.favorite, size: 20, color: AppTheme.textSecondary),
                                          const SizedBox(width: 12),
                                          Text(
                                            'Interests',
                                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: (currentUser['interests'] as List).map<Widget>((interest) {
                                          return Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.grey[100],
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(color: Colors.grey[300]!),
                                            ),
                                            child: Text(
                                              interest.toString(),
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),
                              if (images.length > 2)
                                ...images.skip(2).map((photoUrl) => Container(
                                  width: double.infinity,
                                  height: 300,
                                  margin: const EdgeInsets.only(top: 16),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.network(
                                      photoUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Container(
                                        color: Colors.grey[300],
                                        child: const Icon(Icons.image, size: 80, color: Colors.grey),
                                      ),
                                    ),
                                  ),
                                )),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
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
}