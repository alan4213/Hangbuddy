import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'profile_detail_screen.dart';
import '../models/matches_model.dart';
import '../services/hangout_service.dart';
import '../models/hangout_request_model.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';
import '../services/location_service.dart';
import '../widgets/premium_dialog.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'hangout_interested_users_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../widgets/skeleton_loading.dart';
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
  static final Map<String, UserModel> _userCache = {};
  double _distanceFilter = 100.0;
  static double? _userLatitude;
  static double? _userLongitude;
  bool _isGettingLocation = false;
  
  // Filter variables
  RangeValues _ageRange = const RangeValues(18, 65);
  String? _genderFilter;
  RangeValues _timeRange = const RangeValues(0, 24);
  
  // Hangout variables - make static to persist across screen recreations
  static List<HangoutRequest> _hangouts = [];
  bool _isLoading = false;
  Set<String> _likedHangouts = {};
  
  // Tutorial keys
  final GlobalKey _filterKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();
  bool _showTutorial = false;
  
  // Refresh timers
  Timer? _idleTimer;
  Timer? _locationCheckTimer;
  DateTime _lastInteraction = DateTime.now();
  static final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    print('DEBUG: initState - _hangouts.length: ${_hangouts.length}');
    // Only get location if we don't have it yet
    if (_userLatitude == null || _userLongitude == null) {
      print('DEBUG: Getting location for first time');
      _getCurrentLocation();
    } else if (_hangouts.isEmpty) {
      // If we have location but no hangouts, load them
      print('DEBUG: Have location, loading hangouts');
      _loadHangouts();
    } else {
      // If we have hangouts, load new ones in background
      print('DEBUG: Have hangouts, loading in background');
      _loadHangoutsInBackground();
    }
    _startIdleTimer();
    _startLocationServiceCheck();
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
    _locationCheckTimer?.cancel();
    super.dispose();
  }
  
  @override
  void didPopNext() {
    print('DEBUG: didPopNext called - _hangouts.length: ${_hangouts.length}, _isLoading: $_isLoading');
    // Refresh silently when returning from other screens
    _loadHangoutsInBackground();
    _startIdleTimer();
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Silent refresh when user returns to app
      _loadHangoutsInBackground();
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
        _loadHangoutsInBackground();
      }
    });
  }
  
  void _resetIdleTimer() {
    _lastInteraction = DateTime.now();
    _startIdleTimer();
  }
  
  void _loadHangoutsQuietly() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    if (_userLatitude == null || _userLongitude == null) {
      return;
    }
    
    try {
      final hangouts = await HangoutService.getActiveHangoutRequests(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        maxDistanceFilter: _distanceFilter,
      ).first;
      
      if (mounted) {
        final filtered = await _applyFilters(hangouts);
        final sorted = await _sortHangoutsByRelevance(filtered);
        setState(() {
          _hangouts = sorted;
        });
      }
      
    } catch (e) {
      print('ERROR loading hangouts quietly: $e');
    }
  }

  void _loadHangoutsInBackground() async {
    print('DEBUG: _loadHangoutsInBackground started');
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    if (_userLatitude == null || _userLongitude == null) {
      print('DEBUG: No location data, skipping background load');
      return;
    }
    
    try {
      print('DEBUG: Fetching hangouts from service...');
      final hangouts = await HangoutService.getActiveHangoutRequests(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        maxDistanceFilter: _distanceFilter,
      ).first;
      
      print('DEBUG: Got ${hangouts.length} hangouts from service');
      
      if (mounted) {
        final filtered = await _applyFilters(hangouts);
        final sorted = await _sortHangoutsByRelevance(filtered);
        print('DEBUG: Background load complete, updating UI with ${sorted.length} hangouts');
        // Always update with new hangouts
        setState(() {
          _hangouts = sorted;
        });
      }
      
    } catch (e) {
      print('ERROR loading hangouts in background: $e');
    }
  }

  void _loadHangouts() async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    
    if (_userLatitude == null || _userLongitude == null) {
      setState(() => _isLoading = false);
      return;
    }
    
    // Only show loading if we don't have hangouts already
    if (_hangouts.isEmpty) {
      setState(() => _isLoading = true);
    }
    
    try {
      final hangouts = await HangoutService.getActiveHangoutRequests(
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        maxDistanceFilter: _distanceFilter,
      ).first;
      
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: FutureBuilder<UserModel?>(
                future: UserService.getUserProfile(),
                builder: (context, snapshot) {
                  final user = snapshot.data;
                  final firstName = user?.firstName ?? 'there';
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hi, $firstName',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "Let's plan something fun",
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Events",
                            style: GoogleFonts.poppins(
                              fontSize: 28,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.grey[200],
                          image: user?.profileImageUrl != null
                              ? DecorationImage(
                                  image: CachedNetworkImageProvider(user!.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.profileImageUrl == null
                            ? const Icon(Icons.person, color: Colors.grey)
                            : null,
                      ),
                    ],
                  );
                },
              ),
            ),
            // Filter chips at top
            Container(
              key: _filterKey,
              height: 54,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.tune, color: Colors.black87, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildFilterChip(
                            _getDistanceLabel() == 'Distance' ? 'Anywhere' : _getDistanceLabel(),
                            Icons.location_on,
                            onTap: _showDistanceFilter,
                            isActive: _isDistanceFilterActive(),
                            hideIcon: true,
                          ),
                          _buildFilterChip(
                            _getAgeLabel() == 'Age' ? 'Age' : _getAgeLabel(),
                            Icons.keyboard_arrow_down,
                            onTap: _showAgeFilter,
                            isActive: _isAgeFilterActive(),
                            iconRight: true,
                          ),
                          _buildFilterChip(
                            _getGenderLabel() == 'Gender' ? 'Gender' : _getGenderLabel(),
                            Icons.keyboard_arrow_down,
                            onTap: _showGenderFilter,
                            isActive: _isGenderFilterActive(),
                            iconRight: true,
                          ),
                          _buildFilterChip(
                            _getTimeLabel() == 'Time' ? 'Time' : _getTimeLabel(),
                            Icons.keyboard_arrow_down,
                            onTap: _showTimeFilter,
                            isActive: _isTimeFilterActive(),
                            iconRight: true,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Hangout cards list
            Expanded(
              child: _buildHangoutsList(),
            ),
          ],
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Shift FAB up to sit above the navigation pill
        child: FloatingActionButton(
          key: _createButtonKey,
          onPressed: () => Navigator.pushNamed(context, '/create'),
          backgroundColor: const Color(0xFF8B5CF6), // Purple color
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_comment, color: Colors.white),
        ),
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

  Widget _buildFilterChip(String label, IconData icon, {VoidCallback? onTap, bool isActive = false, bool hideIcon = false, bool iconRight = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? Colors.black87 : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isActive ? Colors.transparent : Colors.black87,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!hideIcon && !iconRight) ...[
              Icon(icon, size: 16, color: isActive ? Colors.white : Colors.black87),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: isActive ? Colors.white : Colors.black87,
              ),
            ),
            if (!hideIcon && iconRight) ...[
              const SizedBox(width: 6),
              Icon(icon, size: 16, color: isActive ? Colors.white : Colors.black87),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHangoutsList() {
    print('DEBUG: _buildHangoutsList - _isLoading: $_isLoading, _hangouts.length: ${_hangouts.length}');
    // Only show loading if we're actually loading AND don't have hangouts yet
    if (_isLoading && _hangouts.isEmpty) {
      print('DEBUG: Showing skeleton loading');
      return const SkeletonLoading();
    }
    
    if (_hangouts.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async {
          _resetIdleTimer();
          await Future.delayed(const Duration(milliseconds: 500));
          _loadHangoutsQuietly();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: MediaQuery.of(context).size.height - 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Coffee cups image from assets
                  Image.asset(
                    'assets/images/mug_transp.png',
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    'Need a plus one?',
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Everything is better with a company.\nPost a hangout to find a partner.',
                    style: GoogleFonts.poppins(
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
            ),
          ),
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () async {
        _resetIdleTimer(); // Reset idle timer on manual refresh
        await Future.delayed(const Duration(milliseconds: 500));
        _loadHangoutsQuietly();
      },
      child: GestureDetector(
        onTap: _resetIdleTimer, // Reset timer on any interaction
        onPanDown: (_) => _resetIdleTimer(),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 120), // Extra bottom padding for floating navbar
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

  String _formatTimer(DateTime eventTime) {
    final now = DateTime.now();
    final difference = eventTime.difference(now);
    if (difference.isNegative) return "00 : 00 : 00";
    
    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);
    
    if (days > 0) {
      return "${days.toString().padLeft(2, '0')} : ${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')}";
    } else {
      final seconds = difference.inSeconds.remainder(60);
      return "${hours.toString().padLeft(2, '0')} : ${minutes.toString().padLeft(2, '0')} : ${seconds.toString().padLeft(2, '0')}";
    }
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
              color: Colors.grey[50],
            ),
          );
        }
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  image: DecorationImage(
                    image: AssetImage(_getCategoryImagePath(hangout.category)),
                    fit: BoxFit.cover,
                    colorFilter: _isViewed(hangout) ? ColorFilter.mode(
                      Colors.grey.withOpacity(0.3),
                      BlendMode.overlay,
                    ) : null,
                  ),
                ),
                child: Stack(
                  children: [
                    if (_isViewed(hangout))
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            'Viewed',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                          ),
                        ),
                      ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: GestureDetector(
                        onTap: () => _handleLike(hangout),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.4),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _isLiked(hangout) ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Content section
              GestureDetector(
                onTap: () => _showProfile(user, hangout),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Avatars + Timer
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Interested users avatars
                          Row(
                            children: [
                              // Host Avatar First
                              Align(
                                widthFactor: 0.6,
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    color: Colors.grey[300],
                                    image: user.profileImageUrl != null
                                        ? DecorationImage(
                                            image: CachedNetworkImageProvider(user.profileImageUrl!),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: user.profileImageUrl == null
                                      ? const Icon(Icons.person, size: 14, color: Colors.grey)
                                      : null,
                                ),
                              ),
                              // Then Interested Users (take up to 1)
                              if (hangout.interestedUsers.isNotEmpty)
                                ...hangout.interestedUsers.take(1).map((userId) => 
                                  FutureBuilder<UserModel?>(
                                    future: _getUserData(userId),
                                    builder: (context, snapshot) {
                                      final interestedUser = snapshot.data;
                                      return Align(
                                        widthFactor: 0.6,
                                        child: Container(
                                          width: 28,
                                          height: 28,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                            color: Colors.grey[300],
                                            image: interestedUser?.profileImageUrl != null
                                                ? DecorationImage(
                                                    image: CachedNetworkImageProvider(interestedUser!.profileImageUrl!),
                                                    fit: BoxFit.cover,
                                                  )
                                                : null,
                                          ),
                                          child: interestedUser?.profileImageUrl == null
                                              ? const Icon(Icons.person, size: 14, color: Colors.grey)
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                ).toList(),
                              if (hangout.interestedUsers.length > 1)
                                Align(
                                  widthFactor: 0.6,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                      color: const Color(0xFF8B5CF6),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${hangout.interestedUsers.length}+',
                                        style: GoogleFonts.poppins(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                          // Timer Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF9CA3AF), // Lighter grey pill
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatTimer(hangout.dateTime),
                              style: GoogleFonts.poppins(
                                fontSize: 13, 
                                color: Colors.white, 
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0, // Matches the spaced out numbers in mockup
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      // Creator name
                      Text(
                        '${user.firstName} ${user.lastName}',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Title
                      Text(
                        hangout.title,
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF111827),
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Date and Time
                      Row(
                        children: [
                          const Icon(Icons.calendar_today_outlined, size: 15, color: Color(0xFF4B5563)),
                          const SizedBox(width: 6),
                          Text(
                            '${_formatDate(hangout.dateTime)} • ${_formatTime(hangout.dateTime)}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              color: const Color(0xFF4B5563),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Location
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF4B5563)),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              hangout.location,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: const Color(0xFF4B5563),
                                fontWeight: FontWeight.w500,
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

  bool _isViewed(HangoutRequest hangout) {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    return currentUser != null && hangout.viewedByUsers.contains(currentUser.uid);
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

  void _handleAccept(HangoutRequest hangout) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;
    
    setState(() {
      _likedHangouts.add(hangout.id);
    });
    
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (BuildContext context) {
        return PremiumDialog(
          title: 'Interest Sent!',
          subtitle: 'We\'ve notified the creator. Once they accept,\nyou can start chatting and make plans together',
          primaryActionText: 'Got it',
          onPrimaryAction: () => Navigator.of(context).pop(),
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
    setState(() {
      _isGettingLocation = true;
      _isLoading = true;
    });
    
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _isGettingLocation = false;
          _isLoading = false;
        });
        _showLocationServiceDialog();
        return;
      }
      
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
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('ERROR getting location: $e');
      setState(() => _isLoading = false);
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }
  
  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return PremiumDialog(
          title: 'Location Required',
          subtitle: 'Please enable location services to find hangouts near you.',
          primaryActionText: 'Open Settings',
          secondaryActionText: 'Cancel',
          onPrimaryAction: () async {
            Navigator.of(context).pop();
            await Geolocator.openLocationSettings();
            Future.delayed(const Duration(seconds: 2), () {
              _getCurrentLocation();
            });
          },
        );
      },
    );
  }
  
  void _startLocationServiceCheck() {
    _locationCheckTimer = Timer.periodic(const Duration(seconds: 10), (timer) async {
      if (mounted) {
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled && _userLatitude != null) {
          // Location was turned off after being on
          _showLocationServiceDialog();
        }
      }
    });
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PremiumDialog(
          title: '', // Hide standard title
          subtitle: '',
          primaryActionText: 'Apply',
          secondaryActionText: 'Cancel',
          onPrimaryAction: () {
            Navigator.pop(context);
            _loadHangoutsQuietly();
          },
          customContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Distance',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                  Text(
                    _distanceFilter >= 100.0 ? 'Anywhere' : '${_distanceFilter.toInt()} km',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.grey[200],
                  thumbShape: const HollowSliderThumbShape(
                    color: AppTheme.primaryColor,
                    thumbRadius: 10,
                    strokeWidth: 3.5,
                  ),
                  overlayColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
                child: Slider(
                  value: _distanceFilter,
                  min: 1.0,
                  max: 100.0,
                  divisions: 99,
                  onChanged: (value) {
                    setModalState(() => _distanceFilter = value);
                    setState(() => _distanceFilter = value);
                  },
                ),
              ),
            ],
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
      
      // Filter out expired hangouts first
      if (hangout.dateTime.isBefore(DateTime.now())) {
        print('  - FILTERED OUT: Hangout expired at ${hangout.dateTime}');
        continue;
      }
      
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
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PremiumDialog(
          title: '', // Hide standard title
          subtitle: '',
          primaryActionText: 'Apply',
          secondaryActionText: 'Cancel',
          onPrimaryAction: () {
            Navigator.pop(context);
            _loadHangoutsQuietly();
          },
          onSecondaryAction: () {
            Navigator.pop(context);
          },
          customContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Age',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                  Text(
                    '${_ageRange.start.toInt()}-${_ageRange.end.toInt()}',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.grey[200],
                  rangeThumbShape: const HollowRangeSliderThumbShape(
                    color: AppTheme.primaryColor,
                    thumbRadius: 10,
                    strokeWidth: 3.5,
                  ),
                  overlayColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
                child: RangeSlider(
                  values: _ageRange,
                  min: 18,
                  max: 65,
                  divisions: 47,
                  onChanged: (values) {
                    setModalState(() => _ageRange = values);
                    setState(() => _ageRange = values);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showGenderFilter() {
    String? tempGender = _genderFilter;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PremiumDialog(
          title: 'Gender Filter',
          subtitle: '',
          primaryActionText: 'Apply',
          secondaryActionText: 'Cancel',
          onPrimaryAction: () {
            setState(() => _genderFilter = tempGender);
            Navigator.pop(context);
            _loadHangoutsQuietly();
          },
          onSecondaryAction: () => Navigator.pop(context),
          customContent: Column(
            children: ['All', 'Man', 'Woman', 'Transgender', 'Non-binary', 'Other'].map((gender) => ListTile(
              title: Text(gender),
              leading: Radio<String?>(
                value: gender == 'All' ? null : gender,
                groupValue: tempGender,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setModalState(() => tempGender = value);
                },
              ),
            )).toList(),
          ),
        ),
      ),
    );
  }

  void _showTimeFilter() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PremiumDialog(
          title: '', // Hide standard title
          subtitle: '',
          primaryActionText: 'Apply',
          secondaryActionText: 'Reset',
          onPrimaryAction: () {
            Navigator.pop(context);
            _loadHangoutsQuietly();
          },
          onSecondaryAction: () {
            setState(() => _timeRange = const RangeValues(0, 24));
            Navigator.pop(context);
          },
          customContent: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Time',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                  Text(
                    '${_formatHour(_timeRange.start)} - ${_formatHour(_timeRange.end)}',
                    style: GoogleFonts.poppins(fontSize: 18, fontWeight: FontWeight.w600, color: const Color(0xFF111827)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SliderTheme(
                data: SliderThemeData(
                  trackHeight: 8,
                  activeTrackColor: AppTheme.primaryColor,
                  inactiveTrackColor: Colors.grey[200],
                  rangeThumbShape: const HollowRangeSliderThumbShape(
                    color: AppTheme.primaryColor,
                    thumbRadius: 10,
                    strokeWidth: 3.5,
                  ),
                  overlayColor: AppTheme.primaryColor.withOpacity(0.1),
                ),
                child: RangeSlider(
                  values: _timeRange,
                  min: 0,
                  max: 24,
                  divisions: 24,
                  onChanged: (values) {
                    setModalState(() => _timeRange = values);
                    setState(() => _timeRange = values);
                  },
                ),
              ),
            ],
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
    if (_distanceFilter >= 100.0) return 'Anywhere';
    return '${_distanceFilter.toInt()} km';
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

  bool _isDistanceFilterActive() => _distanceFilter != 100.0;
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

class HollowSliderThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double strokeWidth;
  final Color color;

  const HollowSliderThumbShape({
    this.thumbRadius = 10.0,
    this.strokeWidth = 3.5,
    this.color = AppTheme.primaryColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final Canvas canvas = context.canvas;
    
    final paintOuter = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final paintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, paintOuter);
    canvas.drawCircle(center, thumbRadius - strokeWidth, paintInner);
  }
}

class HollowRangeSliderThumbShape extends RangeSliderThumbShape {
  final double thumbRadius;
  final double strokeWidth;
  final Color color;

  const HollowRangeSliderThumbShape({
    this.thumbRadius = 10.0,
    this.strokeWidth = 3.5,
    this.color = AppTheme.primaryColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final Canvas canvas = context.canvas;
    
    final paintOuter = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
      
    final paintInner = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, thumbRadius, paintOuter);
    canvas.drawCircle(center, thumbRadius - strokeWidth, paintInner);
  }
}