import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'profile_detail_screen.dart';
import '../models/matches_model.dart';
import '../services/hangout_service.dart';
import '../models/hangout_request_model.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../services/location_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'hangout_interested_users_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../utils/responsive.dart';
import 'dart:math' as math;
import '../widgets/tutorial_overlay.dart';
import '../utils/error_handler.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final Map<String, UserModel> _userCache = {};
  double _distanceFilter = 40.0;
  double? _userLatitude;
  double? _userLongitude;
  bool _isGettingLocation = false;
  
  // Filter variables
  RangeValues _ageRange = const RangeValues(18, 65);
  String? _genderFilter;
  RangeValues _timeRange = const RangeValues(0, 24); // 0-24 hours
  
  // Swipe variables
  PageController _pageController = PageController();
  int _currentIndex = 0;
  List<HangoutRequest> _hangouts = [];
  bool _isLoading = true;
  Set<String> _likedHangouts = {}; // Track locally liked hangouts
  
  // Tutorial keys
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();
  final GlobalKey _likeButtonKey = GlobalKey();
  final GlobalKey _hangoutDetailsCardKey = GlobalKey();
  bool _showTutorial = false;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }
  
  void _checkAndShowTutorial() async {
    // Show tutorial only if hangouts are loaded and not empty
    if (!_isLoading && _hangouts.isNotEmpty && mounted) {
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  
  void _loadHangouts() async {
    if (_userLatitude == null || _userLongitude == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final hangouts = await HangoutService.getActiveHangoutRequests(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        maxDistanceFilter: _distanceFilter,
      ).first;
      
      final filtered = await _applyFilters(hangouts);
      setState(() {
        _hangouts = filtered;
        _isLoading = false;
      });
      
      // Show tutorial after hangouts are loaded
      _checkAndShowTutorial();
    } catch (e) {
      print('Error loading hangouts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeContent = Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Full-bleed background
          Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.white,
          ),
          // Foreground content
          SafeArea(
            child: Column(
              children: [
                // Filter chips at top
                Container(
                  key: _filterKey,
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip(
                          _getDistanceLabel(),
                          Icons.location_on,
                          onTap: _showDistanceFilter,
                          isActive: _isDistanceFilterActive(),
                        ),
                        _buildFilterChip(
                          _getAgeLabel(),
                          Icons.person,
                          onTap: _showAgeFilter,
                          isActive: _isAgeFilterActive(),
                        ),
                        _buildFilterChip(
                          _getGenderLabel(),
                          Icons.people,
                          onTap: _showGenderFilter,
                          isActive: _isGenderFilterActive(),
                        ),
                        _buildFilterChip(
                          _getTimeLabel(),
                          Icons.access_time,
                          onTap: _showTimeFilter,
                          isActive: _isTimeFilterActive(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Swipeable cards
                Expanded(
                  child: _buildSwipeableCards(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
    if (_showTutorial) {
      return TutorialOverlay(
        steps: [
          TutorialStep(
            title: 'Welcome to Discover',
            description: 'This is where you\'ll find hangouts created by people near you. Swipe through profiles and find activities you\'d like to join.',
            bubblePosition: const Offset(20, 200),
          ),
          TutorialStep(
            title: 'Hangout Details Card',
            description: 'This white card shows the hangout information - what activity, where, and when. This is what you\'ll be joining.',
            targetKey: _hangoutDetailsCardKey,
            bubblePosition: const Offset(20, 150),
            highlightAsRectangle: true,
          ),
          TutorialStep(
            title: 'Filter Your Matches',
            description: 'Use these filters to find hangouts that match your preferences - distance, age, gender, and time.',
            targetKey: _filterKey,
            bubblePosition: const Offset(20, 120),
          ),
          TutorialStep(
            title: 'Show Interest',
            description: 'Tap the heart button to show interest in a hangout. The creator will see your interest and can accept you.',
            targetKey: _likeButtonKey,
            bubblePosition: const Offset(20, 200),
          ),
          TutorialStep(
            title: 'Create Your Own Hangout',
            description: 'Tap the + button to create your own hangout and invite people to join you.',
            targetKey: _createButtonKey,
            bubblePosition: const Offset(20, 500),
          ),
        ],
        onComplete: () {
          setState(() {
            _showTutorial = false;
          });
          TutorialService.markTutorialCompleted('home_screen');
        },
        child: homeContent,
      );
    }
    
    return homeContent;
  }

  Widget _buildCreateHangoutButton(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/create'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Create Hangout',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, IconData icon, {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: Responsive.padding(context, Responsive.smallPadding)),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.padding(context, Responsive.mediumPadding),
          vertical: Responsive.padding(context, 0.012)
        ),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon, 
              color: isActive ? Colors.white : AppTheme.primaryColor, 
              size: Responsive.fontSize(context, Responsive.bodyFontSize)
            ),
            SizedBox(width: Responsive.padding(context, 0.015)),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
                  fontWeight: FontWeight.w500,
                  color: isActive ? Colors.white : Color(0xFF334155),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHangoutCard(BuildContext context, HangoutRequest hangout) {
    return FutureBuilder<UserModel?>(
      future: _getUserData(hangout.creatorId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return Container(
            margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
              color: Colors.grey[100],
            ),
            child: const LoadingWidget(message: 'Loading user...'),
          );
        }
        
        final userName = '${user.firstName} ${user.lastName}';
        final userAge = user.age ?? 0;
        
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileDetailScreen(
                  user: {
                    'firstName': user.firstName,
                    'lastName': user.lastName,
                    'age': userAge,
                    'gender': user.gender,
                    'education': user.education,
                    'occupation': user.occupation,
                    'height': user.height,
                    'ethnicity': user.ethnicity ?? user.race,
                    'religion': user.religion,
                    'interests': user.interests,
                    'image': user.profileImageUrl,
                    'hangout': hangout.title,
                    'venue': hangout.location,
                    'dateTime': hangout.dateTime,
                    'userId': hangout.creatorId,
                    'distance': '${_calculateDistance(hangout.latitude, hangout.longitude)} km away',
                  },
                  onMatch: () {},
                ),
              ),
            );
          },
          child: Container(
            margin: EdgeInsets.all(MediaQuery.of(context).size.width * 0.01),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.05),
              child: Stack(
                children: [
                  // Background Image
                  Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      image: user.profileImageUrl != null || user.photoUrls?.isNotEmpty == true
                          ? DecorationImage(
                              image: NetworkImage(user.profileImageUrl ?? user.photoUrls!.first),
                              fit: BoxFit.cover,
                            )
                          : const DecorationImage(
                              image: NetworkImage('https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&h=600&fit=crop&crop=face'),
                              fit: BoxFit.cover,
                            ),
                      gradient: user.profileImageUrl == null && user.photoUrls?.isEmpty != false
                          ? const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                            )
                          : null,
                    ),
                  ),
                  // Gradient overlay
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

                  // User info at bottom
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  "$userName${userAge > 0 ? ', $userAge' : ''}",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0),
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 1,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  final currentUser = auth.FirebaseAuth.instance.currentUser;
                                  if (currentUser != null && !hangout.interestedUsers.contains(currentUser.uid) && !_likedHangouts.contains(hangout.id)) {
                                    _handleAccept(hangout);
                                  }
                                },
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: () {
                                      final currentUser = auth.FirebaseAuth.instance.currentUser;
                                      if (currentUser != null && (hangout.interestedUsers.contains(currentUser.uid) || _likedHangouts.contains(hangout.id))) {
                                        return Colors.grey;
                                      }
                                      return AppTheme.primaryColor;
                                    }(),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.white, 
                                    size: 20
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: MediaQuery.of(context).size.height * 0.007),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width * 0.025,
                              vertical: MediaQuery.of(context).size.height * 0.005
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getHangoutIcon(hangout.category),
                                  size: 16,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 6),
                                Flexible(
                                  child: Text(
                                    hangout.title,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          FutureBuilder<String>(
                            future: _getFormattedLocation(hangout),
                            builder: (context, locationSnapshot) {
                              final locationText = locationSnapshot.data ?? _cleanLocation(hangout.location);
                              return Row(
                                children: [
                                  const Icon(Icons.location_on, size: 14, color: Colors.white70),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      locationText,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.access_time, size: 14, color: Colors.white70),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  "${_formatDate(hangout.dateTime)} ${_formatTime(hangout.dateTime)}",
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
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

  void _handleAccept(HangoutRequest hangout) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    // Add to local liked set immediately
    setState(() {
      _likedHangouts.add(hangout.id);
    });
    
    // Show popup dialog immediately
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite,
                color: AppTheme.primaryColor,
                size: 50,
              ),
              const SizedBox(height: 16),
              const Text(
                'Interest Sent!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Wait for hangout creator to respond',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text(
                  'Got it!',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );
      },
    );
    
    // Handle database operations in background
    try {
      // Mark as viewed first (this will hide it from discover feed)
      await HangoutService.markAsViewed(hangout.id);
      
      // Only express interest, don't create match yet
      await HangoutService.expressInterest(hangout.id);
    } catch (e) {
      // If there's an error, remove from local set and show error
      setState(() {
        _likedHangouts.remove(hangout.id);
      });
      
      Future.delayed(Duration(milliseconds: 500), () {
        if (mounted) {
          ErrorHandler.showErrorSnackBar(
            context,
            e,
            onRetry: () => _handleAccept(hangout),
            retryLabel: 'Try Again',
          );
        }
      });
    }
  }

  void _handleReject(HangoutRequest hangout) async {
    try {
      // Mark as viewed (this will hide it from discover feed)
      await HangoutService.markAsViewed(hangout.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Passed on "${hangout.title}"'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        e,
        onRetry: () => _handleReject(hangout),
        retryLabel: 'Try Again',
      );
    }
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

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (date == today) {
      return 'Today';
    } else if (date == tomorrow) {
      return 'Tomorrow';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }

  String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour;
    final minute = dateTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  Widget _buildSwipeableCards() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(
          message: 'Loading hangouts...',
          size: 32,
        ),
      );
    }
    
    if (_hangouts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AnimatedMeetingScene(),
            const SizedBox(height: 20),
            const Text(
              'Looking for company?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Check back later or create your own hangout',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
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
    
    return PageView.builder(
      controller: _pageController,
      onPageChanged: (index) {
        setState(() => _currentIndex = index);
      },
      itemCount: _hangouts.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildHingeCard(_hangouts[index]),
        );
      },
    );
  }



  void _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
        // Load hangouts after getting location
        _loadHangouts();
      }
    } catch (e) {
      print('Error getting location: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _showDistanceFilter() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 120, left: 20, right: 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Distance Filter',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Show hangouts within ${_distanceFilter.toInt()} km',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _distanceFilter,
                  min: 1.0,
                  max: 40.0,
                  divisions: 39,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setModalState(() => _distanceFilter = value);
                    setState(() => _distanceFilter = value);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadHangouts(); // Apply filter
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        child: const Text(
                          'Apply',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<List<HangoutRequest>> _applyFilters(List<HangoutRequest> hangouts) async {
    List<HangoutRequest> filtered = [];
    
    for (final hangout in hangouts) {
      final user = await _getUserData(hangout.creatorId);
      if (user == null) continue;
      
      // Age filter
      if (user.age != null) {
        if (user.age! < _ageRange.start || user.age! > _ageRange.end) continue;
      }
      
      // Gender filter
      if (_genderFilter != null) {
        final userGender = user.gender?.toLowerCase();
        final filterGender = _genderFilter!.toLowerCase();
        
        // Handle different gender format variations
        bool genderMatches = false;
        if (filterGender == 'man' && (userGender == 'male' || userGender == 'man')) {
          genderMatches = true;
        } else if (filterGender == 'woman' && (userGender == 'female' || userGender == 'woman')) {
          genderMatches = true;
        } else if (userGender == filterGender) {
          genderMatches = true;
        }
        
        if (!genderMatches) continue;
      }
      
      // Time filter
      final hangoutHour = hangout.dateTime.hour + (hangout.dateTime.minute / 60.0);
      if (hangoutHour < _timeRange.start || hangoutHour > _timeRange.end) continue;
      
      filtered.add(hangout);
    }
    
    return filtered;
  }

  void _showAgeFilter() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 120, left: 20, right: 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Age Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('${_ageRange.start.toInt()} - ${_ageRange.end.toInt()} years'),
                RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 65,
                  divisions: 47,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (values) {
                    setModalState(() => _ageRange = values);
                    setState(() => _ageRange = values);
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _loadHangouts(); // Apply filter
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                  child: const Text('Apply', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showGenderFilter() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 120, left: 20, right: 20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Gender Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ...['All', 'Man', 'Woman', 'Transgender', 'Non-binary', 'Other'].map((gender) => ListTile(
                title: Text(gender),
                leading: Radio<String?>(
                  value: gender == 'All' ? null : gender,
                  groupValue: _genderFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() => _genderFilter = value);
                    Navigator.pop(context);
                    _loadHangouts(); // Apply filter
                  },
                ),
              )),
            ],
          ),
        ),
      ),
    );
  }

  void _showTimeFilter() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        alignment: Alignment.topCenter,
        insetPadding: const EdgeInsets.only(top: 120, left: 20, right: 20),
        child: StatefulBuilder(
          builder: (context, setModalState) => Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Time Range', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                Text('${_formatHour(_timeRange.start)} - ${_formatHour(_timeRange.end)}'),
                RangeSlider(
                  values: _timeRange,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (values) {
                    setModalState(() => _timeRange = values);
                    setState(() => _timeRange = values);
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          setState(() => _timeRange = const RangeValues(0, 24));
                          Navigator.pop(context);
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _loadHangouts(); // Apply filter
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
                        child: const Text('Apply', style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatHour(double hour) {
    final h = hour.toInt();
    return h == 24 ? '12:00 AM' : h == 0 ? '12:00 AM' : h > 12 ? '${h - 12}:00 PM' : '$h:00 AM';
  }

  // Filter label helpers
  String _getDistanceLabel() {
    return _distanceFilter != 40.0 ? '${_distanceFilter.toInt()} km' : 'Distance';
  }

  String _getAgeLabel() {
    return (_ageRange.start != 18 || _ageRange.end != 65) 
        ? '${_ageRange.start.toInt()}-${_ageRange.end.toInt()} yrs' 
        : 'Age';
  }

  String _getGenderLabel() {
    return _genderFilter ?? 'Gender';
  }

  String _getTimeLabel() {
    return (_timeRange.start != 0 || _timeRange.end != 24)
        ? '${_formatHour(_timeRange.start)}-${_formatHour(_timeRange.end)}'
        : 'Time';
  }

  // Filter active state helpers
  bool _isDistanceFilterActive() => _distanceFilter != 40.0;
  bool _isAgeFilterActive() => _ageRange.start != 18 || _ageRange.end != 65;
  bool _isGenderFilterActive() => _genderFilter != null;
  bool _isTimeFilterActive() => _timeRange.start != 0 || _timeRange.end != 24;

  double _calculateDistance(double? lat, double? lng) {
    if (_userLatitude == null || _userLongitude == null || lat == null || lng == null) {
      return 0.0;
    }
    return Geolocator.distanceBetween(_userLatitude!, _userLongitude!, lat, lng) / 1000;
  }

  Future<String> _getFormattedLocation(HangoutRequest hangout) async {
    // First check if original location is already user-friendly
    final cleanedOriginal = _cleanLocation(hangout.location);
    
    // If original location is user-friendly (contains common place names), use it
    if (_isUserFriendlyLocation(cleanedOriginal)) {
      return cleanedOriginal;
    }
    
    // Otherwise, try reverse geocoding if coordinates are available
    if (hangout.latitude != null && hangout.longitude != null) {
      try {
        final address = await LocationService.getAddressFromCoordinates(
          hangout.latitude!,
          hangout.longitude!,
        );
        if (address != null && address.isNotEmpty) {
          return address;
        }
      } catch (e) {
        print('Error formatting location: $e');
      }
    }
    
    // Fallback to cleaned location text
    return cleanedOriginal;
  }
  
  bool _isUserFriendlyLocation(String location) {
    final lowerLocation = location.toLowerCase();
    
    // Check if location contains common place indicators
    final friendlyKeywords = [
      'mall', 'market', 'center', 'centre', 'plaza', 'complex',
      'road', 'street', 'avenue', 'lane', 'drive',
      'hotel', 'restaurant', 'cafe', 'hospital', 'school',
      'park', 'beach', 'station', 'airport', 'temple',
      'church', 'mosque', 'stadium', 'theatre', 'cinema'
    ];
    
    // If location contains friendly keywords and doesn't look like coordinates/codes
    return friendlyKeywords.any((keyword) => lowerLocation.contains(keyword)) &&
           !RegExp(r'^[A-Z0-9-]+$').hasMatch(location.toUpperCase()) &&
           !location.contains('+');
  }

  String _cleanLocation(String location) {
    final parts = location.split(',');
    List<String> cleanParts = [];
    
    for (String part in parts) {
      String cleanPart = part.trim();
      // Skip Plus Codes
      bool isPlusCode = cleanPart.contains('+') && 
          RegExp(r'^[A-Z0-9+]+$').hasMatch(cleanPart.toUpperCase());
      
      if (!isPlusCode && cleanPart.isNotEmpty) {
        cleanParts.add(cleanPart);
      }
    }
    
    if (cleanParts.isEmpty) {
      return 'Location';
    }
    
    String result = cleanParts.join(', ');
    
    // If too long, use just the last part (usually city)
    if (result.length > 25 && cleanParts.length > 1) {
      result = cleanParts.last;
    }
    
    return result;
  }

  IconData _getHangoutIcon(String category) {
    switch (category.toLowerCase()) {
      case 'coffee':
        return Icons.local_cafe;
      case 'food':
      case 'dinner':
      case 'lunch':
        return Icons.restaurant;
      case 'movie':
      case 'cinema':
        return Icons.movie;
      case 'sports':
      case 'gym':
        return Icons.sports;
      case 'music':
      case 'concert':
        return Icons.music_note;
      case 'shopping':
        return Icons.shopping_bag;
      case 'travel':
      case 'adventure':
        return Icons.explore;
      case 'party':
      case 'nightlife':
        return Icons.celebration;
      case 'study':
      case 'work':
        return Icons.school;
      case 'outdoor':
      case 'nature':
        return Icons.nature;
      default:
        return Icons.group;
    }
  }

  Widget _buildHingeCard(HangoutRequest hangout) {
    return FutureBuilder<UserModel?>(
      future: _getUserData(hangout.creatorId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return const Center(child: LoadingWidget(message: 'Loading...'));
        }
        
        return Stack(
          children: [
            // Scrollable content
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // User photo section
                    Container(
                      width: double.infinity,
                      height: 400,
                      decoration: BoxDecoration(
                        image: user.profileImageUrl != null
                            ? DecorationImage(
                                image: NetworkImage(user.profileImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                        color: user.profileImageUrl == null ? Colors.grey[300] : null,
                      ),
                      child: user.profileImageUrl == null
                          ? const Icon(Icons.person, size: 80, color: Colors.grey)
                          : null,
                    ),
                    // User info and hangout details
                    Container(
                      width: double.infinity,
                      color: Colors.white,
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name, age and like button
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${user.firstName} ${user.lastName}${user.age != null ? ', ${user.age}' : ''}',
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    if (user.gender != null)
                                      Text(
                                        user.gender!,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                key: _showTutorial && _currentIndex == 0 ? _likeButtonKey : null,
                                onTap: () {
                                  final currentUser = auth.FirebaseAuth.instance.currentUser;
                                  if (currentUser != null && !hangout.interestedUsers.contains(currentUser.uid) && !_likedHangouts.contains(hangout.id)) {
                                    _handleAccept(hangout);
                                  }
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: () {
                                      final currentUser = auth.FirebaseAuth.instance.currentUser;
                                      if (currentUser != null && (hangout.interestedUsers.contains(currentUser.uid) || _likedHangouts.contains(hangout.id))) {
                                        return Colors.grey;
                                      }
                                      return AppTheme.primaryColor;
                                    }(),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.white, 
                                    size: 24
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Hangout details card
                          Container(
                            key: _showTutorial && _currentIndex == 0 ? _hangoutDetailsCardKey : null,
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
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Let\'s hang out at',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  hangout.title.toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 20, color: Colors.grey[700]),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _cleanLocation(hangout.location),
                                        style: const TextStyle(
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
                                    Icon(Icons.access_time, size: 20, color: Colors.grey[700]),
                                    const SizedBox(width: 12),
                                    Text(
                                      '${_formatDate(hangout.dateTime)} at ${_formatTime(hangout.dateTime)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Second image card
                          if (user.photoUrls != null && user.photoUrls!.length > 1)
                            Container(
                              width: double.infinity,
                              height: 300,
                              margin: const EdgeInsets.only(bottom: 16),
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
                                  user.photoUrls![1],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image, size: 80, color: Colors.grey),
                                  ),
                                ),
                              ),
                            ),
                          // Profile details card
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
                                // Basic info row
                                Row(
                                  children: [
                                    if (user.age != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.cake, size: 20, color: Colors.grey[700]),
                                            const SizedBox(width: 8),
                                            Text('${user.age}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                    if (user.gender != null)
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Icon(Icons.person, size: 20, color: Colors.grey[700]),
                                            const SizedBox(width: 8),
                                            Text(user.gender!, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                // Other details
                                if (user.occupation != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.work, size: 20, color: Colors.grey[700]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          user.occupation!,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (user.education != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.school, size: 20, color: Colors.grey[700]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          user.education!,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (user.religion != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.church, size: 20, color: Colors.grey[700]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          user.religion!,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                if (user.ethnicity != null || user.race != null) ...[
                                  Row(
                                    children: [
                                      Icon(Icons.public, size: 20, color: Colors.grey[700]),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          user.ethnicity ?? user.race!,
                                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Additional photo cards
                          if (user.photoUrls != null && user.photoUrls!.length > 2)
                            ...user.photoUrls!.skip(2).map((photoUrl) => Container(
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
            // Create hangout button (bottom-right)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                key: _showTutorial && _currentIndex == 0 ? _createButtonKey : null,
                onTap: () => Navigator.pushNamed(context, '/create'),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.primaryColor,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 30),
                ),
              ),
            ),
            // Page indicator dots
            if (_hangouts.length > 1)
              Positioned(
                bottom: 90,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_hangouts.length, (index) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index == _currentIndex 
                            ? AppTheme.primaryColor 
                            : Colors.grey.withOpacity(0.5),
                      ),
                    );
                  }),
                ),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildActionButtons() {
    if (_hangouts.isEmpty) return const SizedBox();
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Pass button
          GestureDetector(
            onTap: _passCurrentHangout,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.close,
                color: Colors.red,
                size: 30,
              ),
            ),
          ),
          // Like button
          GestureDetector(
            onTap: _likeCurrentHangout,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.favorite,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  void _passCurrentHangout() {
    if (_currentIndex < _hangouts.length) {
      _handleReject(_hangouts[_currentIndex]);
      _nextCard();
    }
  }
  
  void _likeCurrentHangout() {
    if (_currentIndex < _hangouts.length) {
      _handleAccept(_hangouts[_currentIndex]);
      _nextCard();
    }
  }
  
  void _nextCard() {
    if (_currentIndex < _hangouts.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // No more cards, reload
      _loadHangouts();
    }
  }
  

}

class HangoutIllustrationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    
    // Background
    paint.color = const Color(0xFFF8F9FA);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Trees
    // Left tree trunk
    paint.color = const Color(0xFF8B4513);
    canvas.drawRect(Rect.fromLTWH(30, 120, 8, 40), paint);
    // Left tree foliage
    paint.color = const Color(0xFFFBBF24);
    canvas.drawCircle(const Offset(34, 110), 25, paint);
    
    // Right tree trunk
    paint.color = const Color(0xFF8B4513);
    canvas.drawRect(Rect.fromLTWH(260, 120, 8, 40), paint);
    // Right tree foliage
    paint.color = const Color(0xFF10B981);
    canvas.drawCircle(const Offset(264, 110), 25, paint);
    
    // Bench
    paint.color = const Color(0xFFDC2626);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(100, 150, 100, 8),
        const Radius.circular(4),
      ),
      paint,
    );
    
    // Bench legs
    canvas.drawRect(Rect.fromLTWH(105, 158, 4, 15), paint);
    canvas.drawRect(Rect.fromLTWH(191, 158, 4, 15), paint);
    
    // Ground
    paint.color = const Color(0xFF22C55E);
    canvas.drawRect(Rect.fromLTWH(0, 170, size.width, 50), paint);
    
    // Left person
    // Head
    paint.color = const Color(0xFFFFDBB5);
    canvas.drawCircle(const Offset(120, 130), 12, paint);
    // Hair
    paint.color = const Color(0xFF8B4513);
    canvas.drawCircle(const Offset(120, 125), 10, paint);
    // Body
    paint.color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(110, 142, 20, 25),
        const Radius.circular(10),
      ),
      paint,
    );
    // Legs
    paint.color = const Color(0xFF1E40AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(112, 167, 7, 20),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(121, 167, 7, 20),
        const Radius.circular(3),
      ),
      paint,
    );
    
    // Right person
    // Head
    paint.color = const Color(0xFFFFDBB5);
    canvas.drawCircle(const Offset(180, 130), 12, paint);
    // Hair
    paint.color = const Color(0xFF4C1D95);
    canvas.drawCircle(const Offset(180, 125), 10, paint);
    // Body
    paint.color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(170, 142, 20, 25),
        const Radius.circular(10),
      ),
      paint,
    );
    // Legs
    paint.color = const Color(0xFF1E40AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(172, 167, 7, 20),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(181, 167, 7, 20),
        const Radius.circular(3),
      ),
      paint,
    );
    
    // Chat bubbles
    // Left chat bubble
    paint.color = const Color(0xFFFBBF24);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(80, 40, 30, 20),
        const Radius.circular(10),
      ),
      paint,
    );
    
    // Right chat bubble
    paint.color = const Color(0xFF6366F1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(190, 40, 30, 20),
        const Radius.circular(10),
      ),
      paint,
    );
    
    // Hearts
    paint.color = const Color(0xFFEF4444);
    _drawHeart(canvas, const Offset(60, 30), 8);
    _drawHeart(canvas, const Offset(240, 30), 8);
  }
  
  void _drawHeart(Canvas canvas, Offset center, double size) {
    final paint = Paint()..color = const Color(0xFFEF4444);
    final path = Path();
    
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 0.6, center.dy - size * 0.3,
      center.dx - size * 0.6, center.dy - size * 0.8,
      center.dx, center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size * 0.6, center.dy - size * 0.8,
      center.dx + size * 0.6, center.dy - size * 0.3,
      center.dx, center.dy + size * 0.3,
    );
    
    canvas.drawPath(path, paint);
  }
  
  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class _AnimatedMeetingScene extends StatefulWidget {
  @override
  _AnimatedMeetingSceneState createState() => _AnimatedMeetingSceneState();
}

class _AnimatedMeetingSceneState extends State<_AnimatedMeetingScene>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _person1Animation;
  late Animation<double> _person2Animation;
  late Animation<double> _heartAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _person1Animation = Tween<double>(begin: -100, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _person2Animation = Tween<double>(begin: 100, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _heartAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.elasticOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          width: 200,
          height: 120,
          child: CustomPaint(
            painter: _MeetingScenePainter(
              person1Offset: _person1Animation.value,
              person2Offset: _person2Animation.value,
              heartScale: _heartAnimation.value,
            ),
          ),
        );
      },
    );
  }
}

class _MeetingScenePainter extends CustomPainter {
  final double person1Offset;
  final double person2Offset;
  final double heartScale;

  _MeetingScenePainter({
    required this.person1Offset,
    required this.person2Offset,
    required this.heartScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // Draw bench
    paint.color = const Color(0xFF8B4513);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center + const Offset(0, 20), width: 80, height: 8),
        const Radius.circular(4),
      ),
      paint,
    );
    
    // Bench legs
    canvas.drawRect(Rect.fromLTWH(center.dx - 35, center.dy + 24, 4, 15), paint);
    canvas.drawRect(Rect.fromLTWH(center.dx + 31, center.dy + 24, 4, 15), paint);

    // Person 1 (left)
    final person1Center = center + Offset(-25 + person1Offset, 0);
    _drawPerson(canvas, person1Center, AppTheme.primaryColor);

    // Person 2 (right)
    final person2Center = center + Offset(25 + person2Offset, 0);
    _drawPerson(canvas, person2Center, const Color(0xFFE91E63));

    // Heart between them
    if (heartScale > 0) {
      _drawHeart(canvas, center + const Offset(0, -10), heartScale);
    }
  }

  void _drawPerson(Canvas canvas, Offset center, Color color) {
    final paint = Paint();
    
    // Head
    paint.color = const Color(0xFFFFDBB5);
    canvas.drawCircle(center + const Offset(0, -15), 8, paint);
    
    // Body
    paint.color = color;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 12, height: 20),
        const Radius.circular(6),
      ),
      paint,
    );
    
    // Legs
    paint.color = const Color(0xFF1E40AF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx - 4, center.dy + 10, 3, 12),
        const Radius.circular(2),
      ),
      paint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(center.dx + 1, center.dy + 10, 3, 12),
        const Radius.circular(2),
      ),
      paint,
    );
  }

  void _drawHeart(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..color = const Color(0xFFEF4444);
    final path = Path();
    final size = 6 * scale;
    
    path.moveTo(center.dx, center.dy + size * 0.3);
    path.cubicTo(
      center.dx - size * 0.6, center.dy - size * 0.3,
      center.dx - size * 0.6, center.dy - size * 0.8,
      center.dx, center.dy - size * 0.5,
    );
    path.cubicTo(
      center.dx + size * 0.6, center.dy - size * 0.8,
      center.dx + size * 0.6, center.dy - size * 0.3,
      center.dx, center.dy + size * 0.3,
    );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}