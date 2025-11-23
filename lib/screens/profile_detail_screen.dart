import 'package:flutter/material.dart';
import 'match_notification_screen.dart';
import '../theme/app_theme.dart';

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
  
  List<String> get images {
    final imageUrl = widget.user['image'];
    final validUrl = (imageUrl != null && imageUrl != 'local_photo' && imageUrl.toString().startsWith('http')) 
        ? imageUrl 
        : 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400';
    return [validUrl, validUrl, validUrl];
  }

  @override
  Widget build(BuildContext context) {
    // Debug prints
   
    
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
                // Page indicators
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
                        width: 30,
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
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onTap: () {
                      if (widget.onMatch != null) {
                        widget.onMatch!();
                      }
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchNotificationScreen(user: widget.user),
                        ),
                      );
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.favorite, color: Colors.white, size: 30),
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name and verification
                  Row(
                    children: [
                      Text(
                        '${widget.user['firstName'] ?? ''} ${widget.user['lastName'] ?? ''}',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.verified, color: AppTheme.primaryColor, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '${widget.user['age'] ?? '0'}',
                        style: TextStyle(
                          fontSize: 24,
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
                      fontSize: 14,
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
                        fontSize: 16,
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
        Icon(icon, size: 16, color: Colors.grey[600]),
        SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              color: Colors.black87,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }


}