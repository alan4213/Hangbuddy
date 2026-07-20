import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'photos_screen.dart';
import '../widgets/progress_bar.dart';

class InterestsScreen extends StatefulWidget {
  final SignupData? signupData;
  final List<String>? initialInterests;
  final bool isEditMode;
  
  const InterestsScreen({
    super.key, 
    this.signupData,
    this.initialInterests,
    this.isEditMode = false,
  });

  @override
  State<InterestsScreen> createState() => _InterestsScreenState();
}

class _InterestsScreenState extends State<InterestsScreen> {
  final List<String> _allInterests = [
    'Travel', 'Photography', 'Cooking', 'Wine', 'Coffee', 'Tea',
    'Hiking', 'Running', 'Yoga', 'Gym', 'CrossFit', 'Cycling',
    'Swimming', 'Rock Climbing', 'Skiing', 'Surfing', 'Dancing',
    'Music', 'Concerts', 'Festivals', 'Art', 'Museums', 'Theater',
    'Movies', 'Netflix', 'Reading', 'Writing', 'Podcasts',
    'Gaming', 'Board Games', 'Trivia', 'Karaoke', 'Comedy Shows',
    'Food Tours', 'Brunch', 'Fine Dining', 'Street Food', 'Baking',
    'Gardening', 'DIY Projects', 'Volunteering', 'Meditation',
    'Fashion', 'Shopping', 'Thrifting', 'Vintage', 'Sustainability',
    'Technology', 'Startups', 'Investing', 'Real Estate',
    'Dogs', 'Cats', 'Animals', 'Nature', 'Beach', 'Mountains',
    'Road Trips', 'Backpacking', 'Camping', 'Adventure Sports'
  ];
  
  final Set<String> _selectedInterests = {};
  bool _isLoading = false;

  IconData _getInterestIcon(String interest) {
    switch (interest.toLowerCase()) {
      case 'travel':
        return Icons.flight;
      case 'photography':
        return Icons.camera_alt;
      case 'cooking':
        return Icons.restaurant;
      case 'wine':
        return Icons.wine_bar;
      case 'coffee':
        return Icons.local_cafe;
      case 'tea':
        return Icons.emoji_food_beverage;
      case 'hiking':
        return Icons.hiking;
      case 'running':
        return Icons.directions_run;
      case 'yoga':
        return Icons.self_improvement;
      case 'gym':
        return Icons.fitness_center;
      case 'crossfit':
        return Icons.sports_gymnastics;
      case 'cycling':
        return Icons.directions_bike;
      case 'swimming':
        return Icons.pool;
      case 'rock climbing':
        return Icons.terrain;
      case 'skiing':
        return Icons.downhill_skiing;
      case 'surfing':
        return Icons.surfing;
      case 'dancing':
        return Icons.music_note;
      case 'music':
        return Icons.music_note;
      case 'concerts':
        return Icons.library_music;
      case 'festivals':
        return Icons.celebration;
      case 'art':
        return Icons.palette;
      case 'museums':
        return Icons.museum;
      case 'theater':
        return Icons.theater_comedy;
      case 'movies':
        return Icons.movie;
      case 'netflix':
        return Icons.tv;
      case 'reading':
        return Icons.menu_book;
      case 'writing':
        return Icons.edit;
      case 'podcasts':
        return Icons.podcasts;
      case 'gaming':
        return Icons.sports_esports;
      case 'board games':
        return Icons.casino;
      case 'trivia':
        return Icons.quiz;
      case 'karaoke':
        return Icons.mic;
      case 'comedy shows':
        return Icons.sentiment_very_satisfied;
      case 'food tours':
        return Icons.tour;
      case 'brunch':
        return Icons.brunch_dining;
      case 'fine dining':
        return Icons.restaurant_menu;
      case 'street food':
        return Icons.local_dining;
      case 'baking':
        return Icons.cake;
      case 'gardening':
        return Icons.local_florist;
      case 'diy projects':
        return Icons.build;
      case 'volunteering':
        return Icons.volunteer_activism;
      case 'meditation':
        return Icons.spa;
      case 'fashion':
        return Icons.checkroom;
      case 'shopping':
        return Icons.shopping_bag;
      case 'thrifting':
        return Icons.store;
      case 'vintage':
        return Icons.history;
      case 'sustainability':
        return Icons.eco;
      case 'technology':
        return Icons.computer;
      case 'startups':
        return Icons.rocket_launch;
      case 'investing':
        return Icons.trending_up;
      case 'real estate':
        return Icons.home;
      case 'dogs':
        return Icons.pets;
      case 'cats':
        return Icons.pets;
      case 'animals':
        return Icons.pets;
      case 'nature':
        return Icons.nature;
      case 'beach':
        return Icons.beach_access;
      case 'mountains':
        return Icons.landscape;
      case 'road trips':
        return Icons.directions_car;
      case 'backpacking':
        return Icons.backpack;
      case 'camping':
        return Icons.cabin;
      case 'adventure sports':
        return Icons.sports;
      default:
        return Icons.favorite;
    }
  }

  final List<Color> _iconColors = [
    const Color(0xFFF43F5E), // Rose
    const Color(0xFF8B5CF6), // Violet
    const Color(0xFF0EA5E9), // Sky Blue
    const Color(0xFF10B981), // Emerald
    const Color(0xFFF59E0B), // Amber
    const Color(0xFF3B82F6), // Blue
    const Color(0xFF14B8A6), // Teal
    const Color(0xFFEC4899), // Pink
    const Color(0xFF6366F1), // Indigo
  ];

  @override
  void initState() {
    super.initState();
    if (widget.isEditMode && widget.initialInterests != null) {
      _selectedInterests.addAll(widget.initialInterests!);
    } else if (widget.signupData?.interests != null) {
      _selectedInterests.addAll(widget.signupData!.interests);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.isEditMode ? 'Edit Interests' : 'Create Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditMode)
                  const ProgressBar(currentStep: 8, totalSteps: 8),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'Your Interests',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Select at least 3 interests to help us find your perfect hangout buddy.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 2.8, // Slightly taller to fit 2 lines if needed
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                          ),
                          itemCount: _allInterests.length,
                          itemBuilder: (context, index) {
                            final interest = _allInterests[index];
                            final isSelected = _selectedInterests.contains(interest);
                            final iconColor = _iconColors[index % _iconColors.length];
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedInterests.remove(interest);
                                  } else {
                                    _selectedInterests.add(interest);
                                  }
                                });
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected ? AppTheme.primaryColor : Colors.white,
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                    width: isSelected ? 2 : 1,
                                  ),
                                  boxShadow: isSelected ? [
                                    BoxShadow(
                                      color: AppTheme.primaryColor.withOpacity(0.15),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    )
                                  ] : null,
                                ),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        _getInterestIcon(interest),
                                        color: isSelected ? Colors.white : iconColor,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          interest,
                                          style: GoogleFonts.poppins(
                                            color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                            fontWeight: FontWeight.w500,
                                            fontSize: 13,
                                            height: 1.2,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                          maxLines: 2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        
                        if (_selectedInterests.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              '${_selectedInterests.length} selected',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                        ],
                        
                        SizedBox(height: MediaQuery.of(context).size.height * 0.15),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom Bar
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                  ? MediaQuery.of(context).viewInsets.bottom + 16
                  : 32,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (!widget.isEditMode)
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)),
                        ],
                      )
                    else
                      Text(
                        'Edit Interests',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        if (_selectedInterests.length < 3) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select at least 3 interests')),
                          );
                          return;
                        }
                        
                        if (widget.isEditMode) {
                          Navigator.pop(context, _selectedInterests.toList());
                        } else {
                          setState(() => _isLoading = true);
                          widget.signupData!.interests = _selectedInterests.toList();
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhotosScreen(signupData: widget.signupData!),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}