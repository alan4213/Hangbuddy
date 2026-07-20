import 'dart:io';
import 'dart:ui';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:crop_your_image/crop_your_image.dart';
import 'dart:typed_data';
import '../services/user_service.dart';
import '../services/photo_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../screens/simple_crop_screen.dart';
import 'simple_crop_screen.dart';
import 'religion_screen.dart';
import 'occupation_screen.dart';
import 'education_screen.dart';
import 'gender_screen.dart';
import 'interests_screen.dart';
import 'height_screen.dart';
import 'dob_screen.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _selectedDate;
  String? _selectedGender;
  List<String> _selectedInterests = [];
  String? _selectedReligion;
  String? _selectedOccupation;
  String? _selectedEducation;
  String? _selectedHeight;
  UserModel? _userProfile;
  bool _isLoading = false;
  
  // Photo editing variables
  final List<dynamic> _photos = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _genderOptions = ['Man', 'Woman', 'Transgender', 'Non-binary', 'Other'];
  final List<String> _religionOptions = [
    'Christianity', 'Islam', 'Judaism', 'Hinduism', 'Buddhism', 
    'Sikhism', 'Atheist', 'Agnostic', 'Spiritual', 'Other', 'Prefer not to say'
  ];
  final List<String> _occupationOptions = [
    'Student', 'Teacher', 'Engineer', 'Doctor', 'Nurse', 'Lawyer', 
    'Business Owner', 'Marketing', 'Sales', 'Finance', 'IT/Tech', 
    'Artist', 'Writer', 'Consultant', 'Manager', 'Project Manager', 
    'Financial Analyst', 'Software Developer', 'Data Analyst', 'Designer',
    'Accountant', 'Architect', 'Chef', 'Photographer', 'Freelancer',
    'Entrepreneur', 'Researcher', 'Therapist', 'Real Estate', 'Other'
  ];
  final List<String> _educationOptions = [
    'High School', 'Some College', 'Bachelor\'s Degree', 'Master\'s Degree', 
    'PhD', 'Trade School', 'Professional Certification', 'Associate Degree',
    'Diploma', 'Other'
  ];
  final List<String> _heightOptions = [
    '4\'0"', '4\'1"', '4\'2"', '4\'3"', '4\'4"', '4\'5"', '4\'6"', '4\'7"', '4\'8"', '4\'9"', '4\'10"', '4\'11"',
    '5\'0"', '5\'1"', '5\'2"', '5\'3"', '5\'4"', '5\'5"', '5\'6"', '5\'7"', '5\'8"', '5\'9"', '5\'10"', '5\'11"',
    '6\'0"', '6\'1"', '6\'2"', '6\'3"', '6\'4"', '6\'5"', '6\'6"', '6\'7"', '6\'8"', '6\'9"', '6\'10"', '6\'11"',
    '7\'0"', '7\'1"', '7\'2"', '7\'3"', '7\'4"', '7\'5"'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      final userProfile = await UserService.getUserProfile();
      if (userProfile != null) {
        setState(() {
          _userProfile = userProfile;
          _firstNameController.text = userProfile.firstName;
          _lastNameController.text = userProfile.lastName;
          _selectedDate = userProfile.birthday;
          
          // Safely set dropdown values - only if they exist in options
          _selectedGender = _genderOptions.contains(userProfile.gender) 
              ? userProfile.gender : null;
          _selectedReligion = _religionOptions.contains(userProfile.religion) 
              ? userProfile.religion : null;
          _selectedOccupation = _occupationOptions.contains(userProfile.occupation) 
              ? userProfile.occupation : null;
          _selectedEducation = _educationOptions.contains(userProfile.education) 
              ? userProfile.education : null;
          _selectedHeight = _heightOptions.contains(userProfile.height) 
              ? userProfile.height : null;
              
          _selectedInterests = userProfile.interests ?? [];
        });
        // Load current photos after userProfile is set
        _loadCurrentPhotos();
      }
    } catch (e) {
      print('Error loading profile: $e');
    }
  }
  
  void _loadCurrentPhotos() {
    if (_userProfile?.photoUrls != null) {
      setState(() {
        for (int i = 0; i < _userProfile!.photoUrls!.length && i < 4; i++) {
          _photos[i] = _userProfile!.photoUrls![i];
        }
      });
    }
  }

  Future<void> _pickImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        final imageBytes = await image.readAsBytes();
        if (mounted) {
          final result = await Navigator.push<dynamic>(
            context,
            MaterialPageRoute(
              builder: (context) => SimpleCropScreen(
                imageBytes: imageBytes,
                onCropped: (croppedData) {
                  _saveCroppedImage(index, croppedData);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _saveCroppedImage(int index, dynamic croppedData) async {
    try {
      print('Saving cropped image for index $index');
      print('Cropped data type: ${croppedData.runtimeType}');
      
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      // Extract bytes from CropSuccess object
      Uint8List bytes;
      if (croppedData.runtimeType.toString() == 'CropSuccess') {
        // Access the cropped image bytes from CropSuccess
        bytes = croppedData.croppedImage;
      } else if (croppedData is Uint8List) {
        bytes = croppedData;
      } else {
        bytes = Uint8List.fromList(croppedData);
      }
      
      await file.writeAsBytes(bytes);
      print('File saved: ${file.path}');
      
      if (mounted) {
        setState(() {
          _photos[index] = file;
        });
        print('Photo updated in UI');
      }
    } catch (e) {
      print('Error saving cropped image: $e');
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos[index] = null;
    });
  }

  int get _photoCount => _photos.where((photo) => photo != null).length;
  
  List<String> get _missingFields {
    List<String> missing = [];
    
    if (_firstNameController.text.isEmpty) missing.add('First Name');
    if (_lastNameController.text.isEmpty) missing.add('Last Name');
    if (_selectedGender == null) missing.add('Gender');
    if (_selectedInterests.length < 3) missing.add('Interests (minimum 3)');
    if (_selectedDate == null) missing.add('Birthday');
    if (_selectedReligion == null) missing.add('Religion');
    if (_selectedOccupation == null) missing.add('Occupation');
    if (_selectedEducation == null) missing.add('Education');
    if (_photoCount < 2) missing.add('Photos (minimum 2)');
    
    return missing;
  }
  
  int get _profileCompletionPercentage {
    int completedFields = 0;
    int totalFields = 9;
    
    if (_firstNameController.text.isNotEmpty) completedFields++;
    if (_lastNameController.text.isNotEmpty) completedFields++;
    if (_selectedGender != null) completedFields++;
    if (_selectedInterests.length >= 3) completedFields++;
    if (_selectedDate != null) completedFields++;
    if (_selectedReligion != null) completedFields++;
    if (_selectedOccupation != null) completedFields++;
    if (_selectedEducation != null) completedFields++;
    if (_photoCount >= 2) completedFields++;
    
    return ((completedFields / totalFields) * 100).round();
  }
  
  String get _completionMessage {
    final percentage = _profileCompletionPercentage;
    if (percentage == 100) return "🎉 Your profile is complete!";
    if (percentage >= 80) return "Almost there! Just a few more details";
    if (percentage >= 60) return "Looking good! Keep going";
    if (percentage >= 40) return "Great start! Let's add more info";
    return "Let's build your amazing profile";
  }
  
  void _showMissingFields() {
    final missing = _missingFields;
    if (missing.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎉 Your profile is 100% complete!'),
          backgroundColor: Colors.green,
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Complete Your Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Missing fields:'),
            const SizedBox(height: 12),
            ...missing.map((field) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(Icons.circle, size: 6, color: Colors.red),
                  const SizedBox(width: 8),
                  Expanded(child: Text(field)),
                ],
              ),
            )),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
  
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
  
  void _showAddInterestDialog() {
    final TextEditingController controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Interest'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter your interest',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final interest = controller.text.trim();
              if (interest.isNotEmpty && !_selectedInterests.contains(interest)) {
                setState(() {
                  _selectedInterests.add(interest);
                });
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
            ),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FB),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Profile Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(color: Colors.white),
                  ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // Profile Completion Status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
              margin: const EdgeInsets.only(bottom: 32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withOpacity(0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Avatar with Edit Button
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppTheme.primaryColor,
                            width: 2.5,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: _userProfile?.profileImageUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: _userProfile!.profileImageUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(Icons.person, color: Colors.grey[600], size: 40),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(Icons.person, color: Colors.grey[600], size: 40),
                                ),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Text
                  Text(
                    'Your profile is ${_profileCompletionPercentage}%\ncomplete!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1E293B),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Progress Bar
                  Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      Container(
                        height: 8,
                        width: MediaQuery.of(context).size.width * 0.8 * (_profileCompletionPercentage / 100),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                      // Photos Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PHOTOS',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  '$_photoCount/4 photos',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.75,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final photo = _photos[index];
                
                return GestureDetector(
                  onTap: () => _pickImage(index),
                  child: photo != null
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppTheme.primaryColor,
                              width: 2,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: photo is File
                                    ? Image.file(
                                        photo,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      )
                                    : CachedNetworkImage(
                                        imageUrl: photo,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.black87,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  top: 12,
                                  left: 12,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'MAIN',
                                      style: GoogleFonts.poppins(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        )
                      : CustomPaint(
                            painter: DashedRectPainter(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              strokeWidth: 1.5,
                              gap: 5.0,
                              dash: 6.0,
                              borderRadius: 16.0,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.04),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add,
                                      size: 24,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Add Photo',
                                    style: GoogleFonts.poppins(
                                      color: AppTheme.primaryColor,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                );
              },
            ),
            if (_photoCount > 0) ...[
              const SizedBox(height: 8),
              Text(
                '$_photoCount/4 photos',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],

            const SizedBox(height: 32),

            // First Name Field
            _buildInputField(
              label: 'First Name',
              controller: _firstNameController,
              icon: Icons.person_outline,
            ),

            const SizedBox(height: 24),

            // Last Name Field
            _buildInputField(
              label: 'Last Name',
              controller: _lastNameController,
              icon: Icons.person_outline,
              isIncomplete: _lastNameController.text.isEmpty,
            ),

            const SizedBox(height: 24),

            // Gender Field
            _buildSectionTitle('I am a', isIncomplete: _selectedGender == null),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GenderScreen(
                      initialGender: _selectedGender,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedGender = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.people_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedGender ?? 'Select gender',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedGender != null ? AppTheme.textPrimary : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Interests Field
            _buildSectionTitle('Interests', isIncomplete: _selectedInterests.length < 3),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<List<String>>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => InterestsScreen(
                      initialInterests: _selectedInterests,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedInterests = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.favorite, color: AppTheme.primaryColor),
                        const SizedBox(width: 12),
                        Text(
                          'Tap to edit interests',
                          style: TextStyle(
                            fontSize: 16,
                            color: AppTheme.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                      ],
                    ),
                    if (_selectedInterests.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedInterests.map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _getInterestIcon(interest),
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  interest,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Religion Field
            _buildSectionTitle('Religion', isIncomplete: _selectedReligion == null),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReligionScreen(
                      initialReligion: _selectedReligion,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedReligion = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.church_outlined, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedReligion ?? 'Select religion',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedReligion != null ? AppTheme.textPrimary : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Occupation Field
            _buildSectionTitle('Occupation', isIncomplete: _selectedOccupation == null),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OccupationScreen(
                      initialOccupation: _selectedOccupation,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedOccupation = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.work_outline, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedOccupation ?? 'Select occupation',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedOccupation != null ? AppTheme.textPrimary : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Education Field
            _buildSectionTitle('Education', isIncomplete: _selectedEducation == null),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EducationScreen(
                      initialEducation: _selectedEducation,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedEducation = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.school_outlined, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedEducation ?? 'Select education',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedEducation != null ? AppTheme.textPrimary : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Height Field
            _buildSectionTitle('Height', isIncomplete: _selectedHeight == null),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<String>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => HeightScreen(
                      initialHeight: _selectedHeight,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedHeight = result);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.height, color: AppTheme.primaryColor),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedHeight ?? 'Select height',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedHeight != null ? AppTheme.textPrimary : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Birthday Field
            _buildSectionTitle('Birthday', isIncomplete: _selectedDate == null),
            GestureDetector(
              onTap: () async {
                final result = await Navigator.push<DateTime>(
                  context,
                  MaterialPageRoute(
                    builder: (context) => DobScreen(
                      initialDate: _selectedDate,
                      isEditMode: true,
                    ),
                  ),
                );
                if (result != null) {
                  setState(() => _selectedDate = result);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                  children: [
                    const Icon(
                      Icons.cake,
                      color: AppTheme.accentColor,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedDate != null 
                            ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                            : 'Choose birthday date',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate != null ? Colors.black : Colors.grey,
                        ),
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 16),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  void _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveProfile() async {
    if (_firstNameController.text.trim().isEmpty || 
        _lastNameController.text.trim().isEmpty ||
        _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    
    if (_photoCount < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 2 photos')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Handle photo uploads
      final List<String> allUrls = [];
      final List<File> filesToUpload = [];
      
      // Collect files to upload
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo is File) {
          filesToUpload.add(photo);
        }
      }
      
      // Upload new files
      List<String> uploadedUrls = [];
      if (filesToUpload.isNotEmpty) {
        uploadedUrls = await PhotoService.uploadMultiplePhotos(filesToUpload);
      }
      
      // Build final URLs list
      int uploadIndex = 0;
      for (int i = 0; i < _photos.length; i++) {
        final photo = _photos[i];
        if (photo is String) {
          allUrls.add(photo);
        } else if (photo is File && uploadIndex < uploadedUrls.length) {
          allUrls.add(uploadedUrls[uploadIndex]);
          uploadIndex++;
        }
      }
      
      final existingProfile = await UserService.getUserProfile();
      
      if (existingProfile == null) {
        // Create new profile - convert URLs back to handle mixed content
        await UserService.createUserProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthday: _selectedDate,
          gender: _selectedGender,
          interests: _selectedInterests,
          profileImageUrl: allUrls.isNotEmpty ? allUrls.first : null,
        );
        
        // Update with photo URLs separately
        if (allUrls.isNotEmpty) {
          await UserService.updateUserProfile(
            photoUrls: allUrls,
            profileImageUrl: allUrls.first,
          );
        }
      } else {
        // Update existing profile
        await UserService.updateUserProfile(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          birthday: _selectedDate,
          gender: _selectedGender,
          interests: _selectedInterests,
          religion: _selectedReligion,
          occupation: _selectedOccupation,
          education: _selectedEducation,
          height: _selectedHeight,
          photoUrls: allUrls,
          profileImageUrl: allUrls.isNotEmpty ? allUrls.first : null,
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile saved successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving profile: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }



  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Widget _buildSectionTitle(String title, {bool isIncomplete = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (isIncomplete)
            const SizedBox(width: 8),
          if (isIncomplete)
            Icon(
              Icons.error,
              color: Colors.red,
              size: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool isIncomplete = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label, isIncomplete: isIncomplete),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppTheme.primaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: value,
                hint: Text(
                  hint,
                  style: TextStyle(color: Colors.grey[600]),
                ),
                isExpanded: true,
                items: items.map((String item) {
                  return DropdownMenuItem<String>(
                    value: item,
                    child: Text(
                      item,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CropScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final Function(dynamic) onCropped;

  const _CropScreen({
    required this.imageBytes,
    required this.onCropped,
  });

  @override
  State<_CropScreen> createState() => _CropScreenState();
}

class _CropScreenState extends State<_CropScreen> {
  final CropController _cropController = CropController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Crop(
            image: widget.imageBytes,
            controller: _cropController,
            onCropped: (cropResult) {
              widget.onCropped(cropResult);
              Navigator.pop(context);
            },
            aspectRatio: 1.0,
            maskColor: Colors.black.withOpacity(0.7),
            baseColor: Colors.white,
            cornerDotBuilder: (size, edgeAlignment) => Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.blue, width: 3),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
            interactive: true,
          ),
          // Grid overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(),
            ),
          ),
        ],
      ),
    );
  }
}

class DashedRectPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double dash;
  final double gap;
  final double borderRadius;

  DashedRectPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.dash = 5.0,
    this.gap = 5.0,
    this.borderRadius = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final RRect rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(borderRadius),
    );

    final Path path = Path()..addRRect(rrect);
    final Path dashPath = Path();

    for (final PathMetric measurePath in path.computeMetrics()) {
      double distance = 0;
      while (distance < measurePath.length) {
        dashPath.addPath(
          measurePath.extractPath(distance, distance + dash),
          Offset.zero,
        );
        distance += dash + gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}