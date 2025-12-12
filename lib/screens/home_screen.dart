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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, UserModel> _userCache = {};
  double _distanceFilter = 40.0;
  double? _userLatitude;
  double? _userLongitude;
  bool _isGettingLocation = false;
  
  // Filter variables
  RangeValues _ageRange = const RangeValues(18, 65);
  String? _genderFilter;
  RangeValues _timeRange = const RangeValues(0, 24); // 0-24 hours

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: Responsive.padding(context, 0.02)),
            // Filter bar
            Container(
            padding: EdgeInsets.symmetric(
              horizontal: Responsive.padding(context, Responsive.mediumPadding),
              vertical: Responsive.padding(context, 0.012)
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('Distance', Icons.location_on, onTap: _showDistanceFilter),
                  _buildFilterChip('Age', Icons.person, onTap: _showAgeFilter),
                  _buildFilterChip('Gender', Icons.people, onTap: _showGenderFilter),
                  _buildFilterChip('Time', Icons.access_time, onTap: _showTimeFilter),
                ],
              ),
            ),
          ),
            Expanded(child: _buildDiscoverTab()),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Create Hangout',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
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

  Widget _buildFilterChip(String label, IconData icon, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(right: Responsive.padding(context, Responsive.smallPadding)),
        padding: EdgeInsets.symmetric(
          horizontal: Responsive.padding(context, Responsive.mediumPadding),
          vertical: Responsive.padding(context, 0.012)
        ),
        decoration: BoxDecoration(
          color: Colors.white,
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
            Icon(icon, color: AppTheme.primaryColor, size: Responsive.fontSize(context, Responsive.bodyFontSize)),
            SizedBox(width: Responsive.padding(context, 0.015)),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF334155),
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
                          Text(
                            "$userName${userAge > 0 ? ', $userAge' : ''}",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0),
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
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
                                Expanded(
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
                                  Expanded(
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
                              Text(
                                "${_formatDate(hangout.dateTime)} ${_formatTime(hangout.dateTime)}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _handleReject(hangout),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                                    ),
                                    child: const Icon(Icons.close, color: Colors.white, size: 20),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _handleAccept(hangout),
                                  child: Container(
                                    height: 40,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
                                      ),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: const Icon(Icons.favorite, color: Colors.white, size: 20),
                                  ),
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
    try {
      final currentUser = auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) return;
      
      // Mark as viewed first (this will hide it from discover feed)
      await HangoutService.markAsViewed(hangout.id);
      
      // Only express interest, don't create match yet
      await HangoutService.expressInterest(hangout.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Interest sent! Wait for hangout creator to accept.'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
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

  Widget _buildDiscoverTab() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: StreamBuilder<List<HangoutRequest>>(
        stream: HangoutService.getActiveHangoutRequests(
          userLatitude: _userLatitude,
          userLongitude: _userLongitude,
          maxDistanceFilter: _distanceFilter,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _userLatitude == null) {
            return LoadingWidget(
              message: _isGettingLocation ? 'Getting your location...' : 'Loading hangouts...',
              size: 32,
            );
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          
          final allHangouts = snapshot.data ?? [];
          
          return FutureBuilder<List<HangoutRequest>>(
            future: _applyFilters(allHangouts),
            builder: (context, filterSnapshot) {
              if (filterSnapshot.connectionState == ConnectionState.waiting) {
                return const LoadingWidget(
                  message: 'Applying filters...',
                  size: 24,
                );
              }
              
              final hangouts = filterSnapshot.data ?? [];
          
          if (hangouts.isEmpty) {
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
                ],
              ),
            );
          }
          
          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.45,
            ),
            itemCount: hangouts.length,
            itemBuilder: (context, index) {
              final hangout = hangouts[index];
              return _buildHangoutCard(context, hangout);
            },
          );
            },
          );
        },
      ),
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
                        onPressed: () => Navigator.pop(context),
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
      if (_genderFilter != null && user.gender != _genderFilter) continue;
      
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
                  onPressed: () => Navigator.pop(context),
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
              ...['All', 'Man', 'Woman'].map((gender) => ListTile(
                title: Text(gender),
                leading: Radio<String?>(
                  value: gender == 'All' ? null : gender,
                  groupValue: _genderFilter,
                  activeColor: AppTheme.primaryColor,
                  onChanged: (value) {
                    setState(() => _genderFilter = value);
                    Navigator.pop(context);
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
                        onPressed: () => Navigator.pop(context),
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