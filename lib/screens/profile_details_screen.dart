import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import '../services/user_service.dart';
import '../services/photo_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import 'edit_photos_screen.dart';

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
    'Artist', 'Writer', 'Consultant', 'Manager', 'Financial Analyst', 'Other'
  ];
  final List<String> _educationOptions = [
    'High School', 'Some College', 'Bachelor\'s Degree', 'Master\'s Degree', 
    'PhD', 'Trade School', 'Professional Certification', 'Other'
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
          _selectedGender = userProfile.gender;
          _selectedInterests = userProfile.interests ?? [];
          _selectedReligion = userProfile.religion;
          _selectedOccupation = userProfile.occupation;
          _selectedEducation = userProfile.education;
          _selectedHeight = userProfile.height;
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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _photos[index] = File(image.path);
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos[index] = null;
    });
  }

  int get _photoCount => _photos.where((photo) => photo != null).length;
  
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
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Text(
                    'Profile Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
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
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            // Profile Image Section
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  border: Border.all(color: AppTheme.primaryColor, width: 3),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.1),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(60),
                  child: _userProfile?.profileImageUrl != null
                      ? Image.network(
                          _userProfile!.profileImageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.grey[200],
                          child: const Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.grey,
                          ),
                        ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Photos Section
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                  final photo = _photos[index];
                  
                  return GestureDetector(
                    onTap: () => _pickImage(index),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: photo != null ? AppTheme.primaryColor : Colors.grey.shade300,
                          width: photo != null ? 2 : 1,
                        ),
                      ),
                      child: photo != null
                        ? Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: photo is File
                                  ? Image.file(
                                      photo,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    )
                                  : Image.network(
                                      photo,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () => _removePhoto(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  bottom: 8,
                                  left: 8,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      'Main',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 32,
                                color: AppTheme.primaryColor,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                index == 0 ? 'Main Photo' : 'Add Photo',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
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
            ),

            const SizedBox(height: 24),

            // Gender Field
            _buildSectionTitle('I am a'),
            _buildDropdownField(
              value: _selectedGender,
              hint: 'Select gender',
              items: _genderOptions,
              onChanged: (value) => setState(() => _selectedGender = value),
              icon: Icons.people_outline,
            ),

            const SizedBox(height: 24),

            // Interests Field
            _buildSectionTitle('Interests'),
            Container(
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
                  // Display selected interests
                  if (_selectedInterests.isNotEmpty) ...[
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
                              Text(
                                interest,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedInterests.remove(interest);
                                  });
                                },
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Add interest button
                  GestureDetector(
                    onTap: _showAddInterestDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            color: AppTheme.primaryColor,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add Interest',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Religion Field
            _buildSectionTitle('Religion'),
            _buildDropdownField(
              value: _selectedReligion,
              hint: 'Select religion',
              items: _religionOptions,
              onChanged: (value) => setState(() => _selectedReligion = value),
              icon: Icons.church_outlined,
            ),

            const SizedBox(height: 24),

            // Occupation Field
            _buildSectionTitle('Occupation'),
            _buildDropdownField(
              value: _selectedOccupation,
              hint: 'Select occupation',
              items: _occupationOptions,
              onChanged: (value) => setState(() => _selectedOccupation = value),
              icon: Icons.work_outline,
            ),

            const SizedBox(height: 24),

            // Education Field
            _buildSectionTitle('Education'),
            _buildDropdownField(
              value: _selectedEducation,
              hint: 'Select education',
              items: _educationOptions,
              onChanged: (value) => setState(() => _selectedEducation = value),
              icon: Icons.school_outlined,
            ),

            const SizedBox(height: 24),

            // Height Field
            _buildSectionTitle('Height'),
            _buildDropdownField(
              value: _selectedHeight,
              hint: _selectedHeight ?? 'Select height',
              items: _heightOptions,
              onChanged: (value) => setState(() => _selectedHeight = value),
              icon: Icons.height,
            ),

            const SizedBox(height: 24),

            // Birthday Field
            GestureDetector(
              onTap: _selectBirthday,
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
                    Text(
                      _selectedDate != null 
                          ? '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'
                          : 'Choose birthday date',
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedDate != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
            ),
          ),

        ],
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          color: AppTheme.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
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