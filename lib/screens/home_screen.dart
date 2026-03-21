import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'package:google_fonts/google_fonts.dart';
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
      floatingActionButton: FloatingActionButton(
        key: _createButtonKey,
        onPressed: () => Navigator.pushNamed(context, '/create'),
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
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
          border: Border.all(
            color: isActive ? AppTheme.primaryColor : Colors.grey[300]!,
            width: 1,
          ),
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
              style: GoogleFonts.poppins(
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
          // Show a minimal placeholder instead of loading widget
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
                    // Viewed indicator
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
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
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
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Host info
                    GestureDetector(
                      onTap: () => _showProfile(user, hangout),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.primaryColor,
                                  width: 2,
                                ),
                                image: user.profileImageUrl != null
                                    ? DecorationImage(
                                        image: NetworkImage(user.profileImageUrl!),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                                color: user.profileImageUrl == null ? Colors.grey[300] : null,
                              ),
                              child: user.profileImageUrl == null
                                  ? Icon(Icons.person, size: 24, color: Colors.grey[600])
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${user.firstName} ${user.lastName}',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Host',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: Colors.grey[400], size: 20),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Date and time
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.calendar_today, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _formatDate(hangout.dateTime),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Icon(Icons.access_time, size: 18, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(hangout.dateTime),
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.black87,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.location_on, size: 18, color: Colors.grey[700]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              hangout.location,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.black87,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Join button
                    Row(
                      children: [
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
                            style: GoogleFonts.poppins(
                              fontSize: 16,
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
        return Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.location_off,
                    color: AppTheme.primaryColor,
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Location Required',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Please enable location services to find hangouts near you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await Geolocator.openLocationSettings();
                          Future.delayed(const Duration(seconds: 2), () {
                            _getCurrentLocation();
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Open Settings',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
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
                  _distanceFilter >= 100.0 

                      ? 'Show hangouts anywhere'
                      : 'Show hangouts within ${_distanceFilter.toInt()} km',
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Slider(
                  value: _distanceFilter,
                  min: 1.0,
                  max: 100.0,
                  divisions: 99,
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
                          _loadHangoutsQuietly();
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
                    _loadHangoutsQuietly();
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
                    _loadHangoutsQuietly();
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
                          _loadHangoutsQuietly();
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