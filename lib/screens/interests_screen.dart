import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!widget.isEditMode) const ProgressBar(currentStep: 8, totalSteps: 8),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.08),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Interests',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.07,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.015),
              Text(
                'Select at least 3 interests to help us find your perfect hangout buddy',
                style: TextStyle(
                  fontSize: MediaQuery.of(context).size.width * 0.04,
                  color: AppTheme.textSecondary,
                ),
              ),
              SizedBox(height: MediaQuery.of(context).size.height * 0.03),
              
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: MediaQuery.of(context).size.width * 0.03,
                    mainAxisSpacing: MediaQuery.of(context).size.height * 0.015,
                  ),
                  itemCount: _allInterests.length,
                  itemBuilder: (context, index) {
                    final interest = _allInterests[index];
                    final isSelected = _selectedInterests.contains(interest);
                    
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
                          color: isSelected ? AppTheme.primaryColor : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(MediaQuery.of(context).size.width * 0.06),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getInterestIcon(interest),
                                color: isSelected ? Colors.white : AppTheme.primaryColor,
                                size: MediaQuery.of(context).size.width * 0.04,
                              ),
                              SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: MediaQuery.of(context).size.width * 0.035,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              if (_selectedInterests.isNotEmpty) ...[
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Text(
                  '${_selectedInterests.length} selected',
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width * 0.035,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              
              SizedBox(height: MediaQuery.of(context).size.height * 0.02),
              
              LoadingButton(
                isLoading: _isLoading,
                text: widget.isEditMode ? 'Save' : 'Continue',
                onPressed: () async {
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