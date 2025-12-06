import 'package:flutter/material.dart';
import 'match_notification_screen.dart';
import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../services/user_service.dart';
import '../services/match_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfileDetailScreen extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback? onMatch;

  const ProfileDetailScreen({super.key, required this.user, this.onMatch});

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  PageController _pageController = PageController();
  int _currentIndex = 0;
  Map<String, dynamic>? _freshUserData;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    print('ProfileDetailScreen initState called');
    _loadFreshUserData();
  }
  
  Future<void> _loadFreshUserData() async {
    try {
      print('Widget user data: ${widget.user}');
      
      // Try to find UID in widget.user or use phone number to find user
      String? targetUid = widget.user['uid'] ?? widget.user['userId'];
      
      if (targetUid == null || targetUid.isEmpty) {
        print('No UID found, searching by phone number: ${widget.user['phoneNumber']}');
        if (widget.user['phoneNumber'] != null) {
          final querySnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('phoneNumber', isEqualTo: widget.user['phoneNumber'])
              .limit(1)
              .get();
          
          if (querySnapshot.docs.isNotEmpty) {
            targetUid = querySnapshot.docs.first.id;
            print('Found user by phone: $targetUid');
          }
        }
      }
      
      if (targetUid == null) {
        print('Could not determine target user UID');
        return;
      }
      
      print('Loading fresh data for UID: $targetUid');
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(targetUid)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        print('=== FIRESTORE DATA ===');
        print('photoUrls: ${data['photoUrls']}');
        print('profileImageUrl: ${data['profileImageUrl']}');
        print('image: ${data['image']}');
        print('=== END FIRESTORE ===');
        setState(() {
          _freshUserData = data;
        });
      } else {
        print('Document does not exist or widget unmounted');
      }
    } catch (e) {
      print('Error loading fresh user data: $e');
    }
  }
  
  Map<String, dynamic> get currentUser => _freshUserData ?? widget.user;
  
  List<String> get images {
    final List<String> userImages = [];
    
    print('=== PHOTO DEBUG ===');
    print('photoUrls: ${currentUser['photoUrls']}');
    print('profileImageUrl: ${currentUser['profileImageUrl']}');
    print('image: ${currentUser['image']}');
    
    // Get photos from photoUrls array first
    final photoUrls = currentUser['photoUrls'] as List?;
    if (photoUrls != null && photoUrls.isNotEmpty) {
      print('Found ${photoUrls.length} photos in photoUrls');
      for (final photo in photoUrls) {
        if (photo != null && photo.toString().startsWith('http')) {
          userImages.add(photo);
          print('Added photo: ${photo.toString().substring(0, 50)}...');
        }
      }
    }
    
    // If no photoUrls, get from profileImageUrl or image field
    if (userImages.isEmpty) {
      final mainImage = currentUser['profileImageUrl'] ?? currentUser['image'];
      if (mainImage != null && mainImage.toString().startsWith('http')) {
        userImages.add(mainImage);
        print('Added main image: ${mainImage.toString().substring(0, 50)}...');
      }
    }
    
    print('Total images: ${userImages.length}');
    print('=== END DEBUG ===');
    
    // If still no valid images, use placeholder
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
          // Image section with swipe
          Expanded(
            flex: 2,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  physics: images.length > 1 ? const PageScrollPhysics() : const NeverScrollableScrollPhysics(),
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    return Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: NetworkImage(images[index]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    );
                  },
                ),
                // Top bar
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.arrow_back, color: Colors.white),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.3),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.more_horiz, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Page indicators - only show if multiple images
                if (images.length > 1)
                  Positioned(
                    top: 100,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        images.length,
                        (index) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 2),
                          width: MediaQuery.of(context).size.width * 0.08,
                          height: 3,
                          decoration: BoxDecoration(
                            color: _currentIndex == index ? Colors.white : Colors.white.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ),
                  ),
                // Match button
                Positioned(
                  bottom: MediaQuery.of(context).size.height * 0.025,
                  right: MediaQuery.of(context).size.width * 0.05,
                  child: GestureDetector(
                    onTap: () async {
                      if (widget.onMatch != null) {
                        widget.onMatch!();
                      }
                      
                      final currentUser = FirebaseAuth.instance.currentUser;
                      if (currentUser == null) return;
                      
                      try {
                        // Create match in database
                        await MatchService.createMatch(
                          user1Id: currentUser.uid,
                          user2Id: widget.user['userId'] ?? widget.user['uid'] ?? '',
                          hangoutTitle: 'General Match',
                          hangoutLocation: 'To be decided',
                          hangoutDateTime: DateTime.now().add(Duration(days: 7)),
                        );
                        
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => MatchNotificationScreen(user: widget.user),
                          ),
                        );
                      } catch (e) {
                        print('Error creating match: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Error creating match: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: MediaQuery.of(context).size.width * 0.15,
                      height: MediaQuery.of(context).size.width * 0.15,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, color: Colors.white, size: MediaQuery.of(context).size.width * 0.075),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Profile info section
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.05),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and verification
                  Row(
                    children: [
                      Text(
                        '${widget.user['firstName'] ?? ''} ${widget.user['lastName'] ?? ''}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '${widget.user['age'] ?? '0'}',
                        style: TextStyle(
                          fontSize: MediaQuery.of(context).size.width * 0.06,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Looking for new friends',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: MediaQuery.of(context).size.width * 0.035,
                    ),
                  ),
                  SizedBox(height: 16),
                  
                  // Gender
                  if (widget.user['gender'] != null)
                    _buildInfoRow(Icons.person, 'Gender', widget.user['gender']),
                  if (widget.user['gender'] != null)
                    SizedBox(height: 8),
                  
                  // Height
                  if (widget.user['height'] != null)
                    _buildInfoRow(Icons.height, 'Height', widget.user['height']),
                  if (widget.user['height'] != null)
                    SizedBox(height: 8),
                  
                  // Education
                  if (widget.user['education'] != null)
                    _buildInfoRow(Icons.school, 'Education', widget.user['education']),
                  if (widget.user['education'] != null)
                    SizedBox(height: 8),
                  
                  // Occupation
                  if (widget.user['occupation'] != null)
                    _buildInfoRow(Icons.work, 'Occupation', widget.user['occupation']),
                  if (widget.user['occupation'] != null)
                    SizedBox(height: 8),
                  
                  // Ethnicity
                  if (widget.user['ethnicity'] != null)
                    _buildInfoRow(Icons.public, 'Ethnicity', widget.user['ethnicity']),
                  if (widget.user['ethnicity'] != null)
                    SizedBox(height: 8),
                  
                  // Religion
                  if (widget.user['religion'] != null)
                    _buildInfoRow(Icons.church, 'Religion', widget.user['religion']),
                  if (widget.user['religion'] != null)
                    SizedBox(height: 8),
                  
                  // Location
                  _buildInfoRow(Icons.location_on, 'Distance', widget.user['distance'] ?? '10 miles away'),
                  SizedBox(height: 8),
                  
                  // Join Date
                  _buildInfoRow(Icons.calendar_today, 'Member since', '2023'),
                  
                  // Interests
                  if (widget.user['interests'] != null && (widget.user['interests'] as List).isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      'Interests',
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (widget.user['interests'] as List).map<Widget>((interest) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            interest.toString(),
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: MediaQuery.of(context).size.width * 0.04, color: Colors.grey[600]),
        SizedBox(width: MediaQuery.of(context).size.width * 0.02),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: MediaQuery.of(context).size.width * 0.035,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: MediaQuery.of(context).size.width * 0.035,
            ),
          ),
        ),
      ],
    );
  }


}