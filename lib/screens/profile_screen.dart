import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_image_widget.dart';
import 'settings_screen.dart';
import 'notifications_screen.dart';
import 'edit_photos_screen.dart';
import '../services/hangout_service.dart';
import '../services/verification_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _userProfile;
  bool _isLoading = true;
  String? _verificationStatus;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadVerificationStatus();
  }
  
  void _loadVerificationStatus() async {
    final status = await VerificationService.getVerificationStatus();
    if (mounted) {
      setState(() {
        _verificationStatus = status;
      });
    }
  }

  void _loadUserProfile() async {
    try {
      final profile = await UserService.getUserProfile();
      print('Profile loaded: ${profile?.firstName} ${profile?.lastName}');
      print('Profile image URL: ${profile?.profileImageUrl}');
      setState(() {
        _userProfile = profile;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading profile: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all((MediaQuery.of(context).size.width * 0.05).clamp(12.0, 20.0)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Gather',
                    style: TextStyle(
                      fontSize: (MediaQuery.of(context).size.width * 0.07).clamp(20.0, 28.0),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => SettingsScreen()),
                      );
                    },
                    child: Icon(Icons.settings, size: (MediaQuery.of(context).size.width * 0.06).clamp(20.0, 28.0), color: AppTheme.primaryColor),
                  ),
                ],
              ),
            ),
            
            // Profile Image
            Stack(
              children: [
                ProfileImageWidget(
                  imageUrl: _userProfile?.profileImageUrl,
                  size: (MediaQuery.of(context).size.width * 0.3).clamp(80.0, 120.0),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () async {
                      await Navigator.pushNamed(context, '/profile-details');
                      _loadUserProfile();
                    },
                    child: Container(
                      width: (MediaQuery.of(context).size.width * 0.09).clamp(28.0, 36.0),
                      height: (MediaQuery.of(context).size.width * 0.09).clamp(28.0, 36.0),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.edit,
                        size: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 20.0),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: (MediaQuery.of(context).size.height * 0.02).clamp(12.0, 20.0)),
            
            // Name
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    _isLoading 
                        ? 'Loading...' 
                        : '${_userProfile?.firstName ?? 'User'} ${_userProfile?.lastName ?? ''}',
                    style: TextStyle(
                      fontSize: (MediaQuery.of(context).size.width * 0.08).clamp(20.0, 32.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
                SizedBox(width: (MediaQuery.of(context).size.width * 0.02).clamp(4.0, 8.0)),
                Icon(
                  Icons.verified,
                  color: _verificationStatus == 'verified' ? AppTheme.primaryColor : Colors.grey[400],
                  size: (MediaQuery.of(context).size.width * 0.06).clamp(20.0, 24.0),
                ),
              ],
            ),
            
            SizedBox(height: (MediaQuery.of(context).size.height * 0.04).clamp(20.0, 32.0)),
            
            SizedBox(height: (MediaQuery.of(context).size.height * 0.03).clamp(16.0, 24.0)),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width * 0.05).clamp(12.0, 20.0)),
                  child: Column(
                    children: [



                    // Notifications
                    _buildMenuCard(
                      Icons.notifications_outlined,
                      'Notifications',
                      'View your notifications',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Test Notification
                    _buildMenuCard(
                      Icons.bug_report,
                      'Test Notification',
                      'Create a test notification',
                      () async {
                        await HangoutService.createTestNotification();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Test notification created')),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Verify Profile
                    _buildMenuCard(
                      Icons.verified_user,
                      'Verify Profile',
                      'Verify your identity for trust',
                      () => _showVerificationDialog(),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Subscription
                    _buildMenuCard(
                      Icons.star_outline,
                      'Subscription',
                      'Upgrade options, current plan',
                      () {},
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Safety & Security
                    _buildMenuCard(
                      Icons.security_outlined,
                      'Safety & Security',
                      'Report issues, safety tips',
                      () {},
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Help Centre
                    _buildMenuCard(
                      Icons.help_outline,
                      'Help Centre',
                      'Support and FAQs',
                      () {},
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Logout
                    _buildMenuCard(
                      Icons.logout,
                      'Logout',
                      'Sign out of your account',
                      () async {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Delete Account
                    _buildMenuCard(
                      Icons.delete_forever,
                      'Delete Account',
                      'Permanently delete your account',
                      () => _showDeleteAccountDialog(),
                    ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.verified_user, color: AppTheme.primaryColor),
              SizedBox(width: 8),
              Text('Profile Verification'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_verificationStatus == 'verified') ...[
                Icon(Icons.check_circle, size: 48, color: Colors.green),
                SizedBox(height: 8),
                Text('Your profile is verified!', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('(Testing: You can verify again)', style: TextStyle(color: Colors.grey, fontSize: 12)),
              ] else ...[
                Text('Take a selfie to verify your identity and build trust with other users.'),
                SizedBox(height: 16),
                Icon(Icons.photo_camera, size: 48, color: AppTheme.primaryColor),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startPhotoVerification();
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor),
              child: Text(_verificationStatus == 'verified' ? 'Verify Again' : 'Take Photo', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _startPhotoVerification() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 80,
      );
      
      if (photo != null) {
        await _uploadVerificationPhoto(File(photo.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  Future<void> _uploadVerificationPhoto(File photo) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      // Show loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(width: 16),
              Text('Uploading verification photo...'),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          duration: Duration(seconds: 10),
        ),
      );
      
      // Upload to Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('verification_photos')
          .child('${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');
      
      await ref.putFile(photo);
      final photoUrl = await ref.getDownloadURL();
      
      // Update user document with verification photo and auto-verify
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'verificationPhotoUrl': photoUrl,
        'verificationStatus': 'verified',
        'verificationSubmittedAt': FieldValue.serverTimestamp(),
        'verifiedAt': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Profile verified successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh verification status
      _loadVerificationStatus();
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text('Are you sure you want to permanently delete your account? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount() async {
    try {
      await UserService.deleteUserAccount();
      Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting account: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all((MediaQuery.of(context).size.width * 0.05).clamp(12.0, 20.0)),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width * 0.04).clamp(12.0, 16.0)),
        ),
        child: Row(
          children: [
            Container(
              width: (MediaQuery.of(context).size.width * 0.1).clamp(32.0, 40.0),
              height: (MediaQuery.of(context).size.width * 0.1).clamp(32.0, 40.0),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width * 0.02).clamp(6.0, 8.0)),
              ),
              child: Icon(
                icon,
                size: (MediaQuery.of(context).size.width * 0.05).clamp(18.0, 22.0),
                color: Colors.grey[600],
              ),
            ),
            SizedBox(width: (MediaQuery.of(context).size.width * 0.04).clamp(12.0, 16.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 18.0),
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: (MediaQuery.of(context).size.height * 0.005).clamp(2.0, 4.0)),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: (MediaQuery.of(context).size.width * 0.035).clamp(12.0, 16.0),
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}