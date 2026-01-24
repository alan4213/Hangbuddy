import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
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
import '../widgets/verified_badge.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin, WidgetsBindingObserver, RouteAware {
  final Map<String, UserModel> _userCache = {};
  double _distanceFilter = 40.0;
  double? _userLatitude;
  double? _userLongitude;
  bool _isGettingLocation = false;
  
  // Filter variables
  RangeValues _ageRange = const RangeValues(18, 65);
  String? _genderFilter;
  RangeValues _timeRange = const RangeValues(0, 24);
  
  // Hangout variables
  List<HangoutRequest> _hangouts = [];
  bool _isLoading = true;
  Set<String> _likedHangouts = {};
  
  // Tutorial keys
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();
  bool _showTutorial = false;
  
  // Refresh timers
  Timer? _idleTimer;
  DateTime _lastInteraction = DateTime.now();
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _getCurrentLocation();
    _startIdleTimer();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }
  
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    routeObserver.unsubscribe(this);
    _idleTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didPopNext() {
    // Refresh when returning from other screens
    _loadHangouts();
    _startIdleTimer();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Condition 1: Refresh when user returns to app
      _loadHangouts();
      _startIdleTimer();
    } else if (state == AppLifecycleState.paused) {
      _idleTimer?.cancel();
    }
  }
  
  void _startIdleTimer() {
    _idleTimer?.cancel();
    _lastInteraction = DateTime.now();
    
    // Condition 2: Refresh every 3 minutes of idle time
    _idleTimer = Timer.periodic(const Duration(minutes: 3), (timer) {
      if (mounted) {
        _loadHangouts();
      }
    });
  }
  
  void _resetIdleTimer() {
    _lastInteraction = DateTime.now();
    _startIdleTimer();
  }
  
  void _loadHangouts() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    if (_userLatitude == null || _userLongitude == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      // Convert stream to single read
      final hangouts = await HangoutService.getActiveHangoutRequests(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        maxDistanceFilter: _distanceFilter,
      ).first; // Get first emission from stream
      
      if (mounted) {
        final filtered = await _applyFilters(hangouts);
        final sorted = await _sortHangoutsByRelevance(filtered);
        setState(() {
          _hangouts = sorted;
          _isLoading = false;
        });
      }
      
    } catch (e) {
      print('ERROR loading hangouts: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final homeContent = Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
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
            // Hangout cards list
            Expanded(
              child: _buildHangoutsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Debug button (temporary)
          FloatingActionButton(
            mini: true,
            onPressed: debugCheckAllHangouts,
            backgroundColor: Colors.orange,
            child: const Icon(Icons.bug_report, color: Colors.white, size: 16),
          ),
          const SizedBox(height: 8),
          // Main create button
          FloatingActionButton(
            key: _createButtonKey,
            onPressed: () => Navigator.pushNamed(context, '/create'),
            backgroundColor: AppTheme.primaryColor,
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ],
      ),
    );
    
    if (_showTutorial) {
      return TutorialOverlay(
        screenName: 'home_screen',
        steps: [
          TutorialStep(
            title: 'Welcome to Discover',
            description: 'This is where you\'ll find hangouts created by people near you.',
            bubblePosition: const Offset(20, 200),
          ),
          TutorialStep(
            title: 'Filter Your Matches',
            description: 'Use these filters to find hangouts that match your preferences.',
            targetKey: _filterKey,
            bubblePosition: const Offset(20, 120),
          ),
          TutorialStep(
            title: 'Create Your Own Hangout',
            description: 'Tap the + button to create your own hangout.',
            targetKey: _createButtonKey,
            bubblePosition: const Offset(20, 500),
          ),
        ],
        onComplete: () {
          setState(() {
            _showTutorial = false;
          });
        },
        child: homeContent,
      );
    }
    
    return homeContent;
  }

  Widget _buildFilterChip(String label, IconData icon, {VoidCallback? onTap, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              size: 16
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : const Color(0xFF334155),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHangoutsList() {
    if (_isLoading) {
      return const Center(
        child: LoadingWidget(
          message: 'Loading hangouts...',
          size: 32,
        ),
      );
    }
    
    if (_hangouts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _resetIdleTimer();
          await Future.delayed(const Duration(milliseconds: 500));
          _loadHangouts();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
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
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _resetIdleTimer(); // Reset idle timer on manual refresh
        await Future.delayed(const Duration(milliseconds: 500));
        _loadHangouts();
      },
      child: GestureDetector(
        onTap: _resetIdleTimer, // Reset timer on any interaction
        onPanDown: (_) => _resetIdleTimer(),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _hangouts.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHangoutCard(_hangouts[index]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHangoutCard(HangoutRequest hangout) {
    return FutureBuilder<UserModel?>(
      future: _getUserData(hangout.creatorId),
      builder: (context, userSnapshot) {
        final user = userSnapshot.data;
        if (user == null) {
          return Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: Colors.grey[100],
            ),
            child: const LoadingWidget(message: 'Loading...'),
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  image: DecorationImage(
                    image: NetworkImage(_getCategoryImageUrl(hangout.category)),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Stack(
                  children: [
                    // Favorite button
                    Positioned(
                      top: 12,
                      right: 12,
                      child: GestureDetector(
                        onTap: () => _handleLike(hangout),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            _isLiked(hangout) ? Icons.favorite : Icons.favorite_border,
                            color: _isLiked(hangout) ? Colors.red : Colors.grey[600],
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Text(
                      hangout.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Host info
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _showProfile(user, hangout),
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: user.profileImageUrl != null
                                  ? DecorationImage(
                                      image: NetworkImage(user.profileImageUrl!),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: user.profileImageUrl == null ? Colors.grey[300] : null,
                            ),
                            child: user.profileImageUrl == null
                                ? Icon(Icons.person, size: 16, color: Colors.grey[600])
                                : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hosted by ${user.firstName} ${user.lastName}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Date and time
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          _formatDate(hangout.dateTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(Icons.access_time, size: 16, color: AppTheme.primaryColor),
                        const SizedBox(width: 6),
                        Text(
                          _formatTime(hangout.dateTime),
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            _cleanLocation(hangout.location),
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Join button
                    Row(
                      children: [
                        if (hangout.interestedUsers.isNotEmpty)
                          Text(
                            '+${hangout.interestedUsers.length} interested',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        const Spacer(),
                        ElevatedButton(
                          onPressed: () => _handleJoin(hangout),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isLiked(hangout) ? Colors.grey : AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            _isLiked(hangout) ? 'Interested' : 'Join',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Helper methods
  bool _isLiked(HangoutRequest hangout) {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    return currentUser != null && 
           (hangout.interestedUsers.contains(currentUser.uid) || 
            _likedHangouts.contains(hangout.id));
  }

  void _handleLike(HangoutRequest hangout) {
    if (!_isLiked(hangout)) {
      _handleAccept(hangout);
    }
  }

  void _handleJoin(HangoutRequest hangout) {
    if (!_isLiked(hangout)) {
      _handleAccept(hangout);
    }
  }

  void _showProfile(UserModel user, HangoutRequest hangout) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProfileDetailScreen(
          user: {
            'firstName': user.firstName,
            'lastName': user.lastName,
            'age': user.age ?? 0,
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
  }

  String _getCategoryImageUrl(String category) {
    switch (category.toLowerCase()) {
      case 'food & drink':
        return 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=600&fit=crop';
      case 'coffee & tea':
        return 'https://images.unsplash.com/photo-1501339847302-ac426a4a7cbb?w=800&h=600&fit=crop';
      case 'movies & cinema':
        return 'https://images.unsplash.com/photo-1440404653325-ab127d49abc1?w=800&h=600&fit=crop';
      case 'sports & fitness':
        return 'https://images.unsplash.com/photo-1571019613454-1cb2f99b2d8b?w=800&h=600&fit=crop';
      case 'music & concerts':
        return 'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop';
      default:
        return 'https://images.unsplash.com/photo-1414235077428-338989a2e8c0?w=800&h=600&fit=crop';
    }
  }

  void _handleAccept(HangoutRequest hangout) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    setState(() {
      _likedHangouts.add(hangout.id);
    });
    
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
    
    try {
      await HangoutService.markAsViewed(hangout.id);
      await HangoutService.expressInterest(hangout.id);
    } catch (e) {
      setState(() {
        _likedHangouts.remove(hangout.id);
      });
      
      if (mounted) {
        ErrorHandler.showErrorSnackBar(
          context,
          e,
          onRetry: () => _handleAccept(hangout),
          retryLabel: 'Try Again',
        );
      }
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

  void _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        print('DEBUG: Got user location: ${position.latitude}, ${position.longitude}');
        setState(() {
          _userLatitude = position.latitude;
          _userLongitude = position.longitude;
        });
        _loadHangouts();
      } else {
        print('DEBUG: Failed to get user location');
      }
    } catch (e) {
      print('ERROR getting location: $e');
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  // Debug method to check all hangouts in database
  void debugCheckAllHangouts() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('hangout_requests')
          .where('status', isEqualTo: 'active')
          .get();
      
      print('=== DEBUG: All Active Hangouts in Database ===');
      print('Total active hangouts: ${snapshot.docs.length}');
      
      for (final doc in snapshot.docs) {
        final data = doc.data();
        print('Hangout ID: ${doc.id}');
        print('  Title: ${data['title']}');
        print('  Creator: ${data['creatorId']}');
        print('  Location: ${data['location']}');
        print('  Coordinates: ${data['latitude']}, ${data['longitude']}');
        print('  Max Distance: ${data['maxDistance']} km');
        print('  Created: ${data['createdAt']}');
        print('  Viewed by: ${data['viewedByUsers'] ?? []}');
        print('---');
      }
    } catch (e) {
      print('ERROR checking hangouts: $e');
    }
  }

  // Debug method to clear viewed status (for testing)
  void debugClearViewedStatus() async {
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      final snapshot = await FirebaseFirestore.instance
          .collection('hangout_requests')
          .where('status', isEqualTo: 'active')
          .get();
      
      for (final doc in snapshot.docs) {
        await doc.reference.update({
          'viewedByUsers': FieldValue.arrayRemove([currentUser.uid])
        });
      }
      
      print('DEBUG: Cleared viewed status for all hangouts');
      _loadHangouts(); // Reload hangouts
    } catch (e) {
      print('ERROR clearing viewed status: $e');
    }
  }

  void _showDistanceFilter() {
    _resetIdleTimer(); // Reset timer on filter interaction
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
                          _loadHangouts();
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
    print('DEBUG: _applyFilters - Input: ${hangouts.length} hangouts');
    List<HangoutRequest> filtered = [];
    
    for (final hangout in hangouts) {
      print('DEBUG: Filtering hangout "${hangout.title}"');
      final user = await _getUserData(hangout.creatorId);
      if (user == null) {
        print('  - FILTERED OUT: User data not found');
        continue;
      }
      
      print('  - User: ${user.firstName} ${user.lastName}, Age: ${user.age}, Gender: ${user.gender}');
      
      // Age filter
      if (user.age != null) {
        if (user.age! < _ageRange.start || user.age! > _ageRange.end) {
          print('  - FILTERED OUT: Age ${user.age} not in range ${_ageRange.start}-${_ageRange.end}');
          continue;
        } else {
          print('  - Age filter PASSED: ${user.age}');
        }
      } else {
        print('  - Age filter SKIPPED: No age data');
      }
      
      // Gender filter
      if (_genderFilter != null) {
        final userGender = user.gender?.toLowerCase();
        final filterGender = _genderFilter!.toLowerCase();
        
        bool genderMatches = false;
        if (filterGender == 'man' && (userGender == 'male' || userGender == 'man')) {
          genderMatches = true;
        } else if (filterGender == 'woman' && (userGender == 'female' || userGender == 'woman')) {
          genderMatches = true;
        } else if (userGender == filterGender) {
          genderMatches = true;
        }
        
        if (!genderMatches) {
          print('  - FILTERED OUT: Gender "$userGender" does not match filter "$filterGender"');
          continue;
        } else {
          print('  - Gender filter PASSED: "$userGender" matches "$filterGender"');
        }
      } else {
        print('  - Gender filter SKIPPED: No gender filter set');
      }
      
      // Time filter
      final hangoutHour = hangout.dateTime.hour + (hangout.dateTime.minute / 60.0);
      if (hangoutHour < _timeRange.start || hangoutHour > _timeRange.end) {
        print('  - FILTERED OUT: Time ${hangoutHour.toStringAsFixed(1)}h not in range ${_timeRange.start}-${_timeRange.end}');
        continue;
      } else {
        print('  - Time filter PASSED: ${hangoutHour.toStringAsFixed(1)}h');
      }
      
      print('  - PASSED ALL FILTERS: Adding to results');
      filtered.add(hangout);
    }
    
    print('DEBUG: _applyFilters - Output: ${filtered.length} hangouts');
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
                    _loadHangouts();
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
                    _loadHangouts();
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
                          _loadHangouts();
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

  String _cleanLocation(String location) {
    final parts = location.split(',');
    List<String> cleanParts = [];
    
    for (String part in parts) {
      String cleanPart = part.trim();
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
    
    if (result.length > 25 && cleanParts.length > 1) {
      result = cleanParts.last;
    }
    
    return result;
  }

  Future<List<HangoutRequest>> _sortHangoutsByRelevance(List<HangoutRequest> hangouts) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return hangouts;

    // Get current user's interests
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser.uid)
        .get();
    
    final userInterests = userDoc.exists 
        ? List<String>.from(userDoc.data()?['interests'] ?? [])
        : <String>[];

    // Calculate relevance score for each hangout
    final scoredHangouts = <MapEntry<HangoutRequest, double>>[];
    
    for (final hangout in hangouts) {
      double score = 0.0;
      
      // Distance score (closer = higher score, max 40 points)
      final distance = _calculateDistance(hangout.latitude, hangout.longitude);
      final distanceScore = math.max(0, 40 - distance);
      score += distanceScore;
      
      // Interest match score (max 60 points)
      final creator = await _getUserData(hangout.creatorId);
      if (creator?.interests != null) {
        final creatorInterests = List<String>.from(creator!.interests!);
        final commonInterests = userInterests.where((interest) => 
            creatorInterests.contains(interest)).length;
        final interestScore = (commonInterests / math.max(1, userInterests.length)) * 60;
        score += interestScore;
      }
      
      // Category match bonus (20 points if user has related interest)
      if (userInterests.any((interest) => 
          interest.toLowerCase().contains(hangout.category.toLowerCase()) ||
          hangout.category.toLowerCase().contains(interest.toLowerCase()))) {
        score += 20;
      }
      
      // Time relevance (prefer hangouts happening soon, max 10 points)
      final hoursUntil = hangout.dateTime.difference(DateTime.now()).inHours;
      final timeScore = hoursUntil <= 24 ? 10 : math.max(0, 10 - (hoursUntil / 24));
      score += timeScore;
      
      scoredHangouts.add(MapEntry(hangout, score));
    }
    
    // Sort by score (highest first)
    scoredHangouts.sort((a, b) => b.value.compareTo(a.value));
    
    return scoredHangouts.map((entry) => entry.key).toList();
  }
}