import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../services/user_service.dart';
import '../services/system_chat_service.dart';
import '../models/signup_data.dart';
import 'simple_crop_screen.dart';

class PhotosScreen extends StatefulWidget {
  final SignupData signupData;
  const PhotosScreen({super.key, required this.signupData});

  @override
  State<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends State<PhotosScreen> {
  final List<File?> _photos = [null, null, null, null];
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickImage(int index) async {
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
  }

  void _saveCroppedImage(int index, dynamic croppedData) async {
    try {
      Uint8List bytes;
      if (croppedData.runtimeType.toString() == 'CropSuccess') {
        bytes = croppedData.croppedImage;
      } else if (croppedData is Uint8List) {
        bytes = croppedData;
      } else {
        bytes = Uint8List.fromList(croppedData);
      }
      
      final tempDir = Directory.systemTemp;
      final file = File('${tempDir.path}/cropped_${DateTime.now().millisecondsSinceEpoch}.jpg');
      await file.writeAsBytes(bytes);
      
      if (mounted) {
        setState(() {
          _photos[index] = file;
        });
      }
    } catch (e) {
      print('Error saving cropped image: $e');
    }
  }

  int get _photoCount => _photos.where((photo) => photo != null).length;

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
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Photos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Show your personality! Upload at least 2 photos to help others get to know you.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: AppTheme.primaryColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tip: Choose photos that show your face clearly and represent your interests!',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              
              Expanded(
                child: GridView.builder(
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
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: photo != null
                          ? Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: Image.file(
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
                                    onTap: () {
                                      setState(() {
                                        _photos[index] = null;
                                      });
                                    },
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
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.add_photo_alternate,
                                    size: 32,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 12),
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
              ),
              
              if (_photoCount > 0) ...[
                Text(
                  '$_photoCount/4 photos added',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              LoadingButton(
                isLoading: _isLoading,
                text: _isLoading ? 'Uploading Photos...' : 'Complete Profile',
                onPressed: () async {
                  if (_photoCount < 2) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please add at least 2 photos')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  try {
                    // Filter out null photos
                    final validPhotos = _photos.where((photo) => photo != null).cast<File>().toList();
                    
                    // Create user profile with all collected data
                    await UserService.createUserProfile(
                      firstName: widget.signupData.firstName ?? 'User',
                      lastName: widget.signupData.lastName ?? '',
                      birthday: widget.signupData.birthday,
                      gender: widget.signupData.gender,
                      interests: widget.signupData.interests,
                      photos: validPhotos,
                      occupation: widget.signupData.occupation,
                      education: widget.signupData.education,
                      height: widget.signupData.height,
                      race: widget.signupData.race,
                      religion: widget.signupData.religion,
                    );
                    
                    // Create system chat for new user
                    final currentUser = FirebaseAuth.instance.currentUser;
                    if (currentUser != null) {
                      await SystemChatService.createSystemChatForUser(currentUser.uid);
                    }
                    
                    if (mounted) {
                      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error creating profile: $e')),
                      );
                    }
                  } finally {
                    if (mounted) {
                      setState(() => _isLoading = false);
                    }
                  }
                },
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}