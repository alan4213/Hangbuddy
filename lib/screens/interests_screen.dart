import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'photos_screen.dart';

class InterestsScreen extends StatefulWidget {
  final SignupData signupData;
  const InterestsScreen({super.key, required this.signupData});

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

  @override
  void initState() {
    super.initState();
    _selectedInterests.addAll(widget.signupData.interests);
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your Interests',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Select at least 3 interests to help us find your perfect hangout buddy',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              
              SizedBox(
                height: 400,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
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
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: isSelected ? AppTheme.primaryColor : Colors.grey.shade300,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            interest,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              
              if (_selectedInterests.isNotEmpty) ...[
                Text(
                  '${_selectedInterests.length} selected',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
                  if (_selectedInterests.length < 3) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select at least 3 interests')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  widget.signupData.interests = _selectedInterests.toList();
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhotosScreen(signupData: widget.signupData),
                      ),
                    );
                  }
                },
              ),
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
            ],
          ),
        ),
      ),
    );
  }
}