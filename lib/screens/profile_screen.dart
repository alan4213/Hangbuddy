import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';
import '../services/user_service.dart';
import '../models/user_model.dart';
import '../theme/app_theme.dart';
import '../widgets/profile_image_widget.dart';
import '../widgets/photo_verified_sheet.dart';
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
                    'Haule',
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
                    style: GoogleFonts.poppins(
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
                    
                    // Verify Profile
                    _buildMenuCard(
                      Icons.verified_user,
                      'Verify Profile',
                      'Verify your identity for trust',
                      () => _showVerificationSheet(),
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

  void _showVerificationSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PhotoVerifiedSheet(),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
              // Warning Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.warning_rounded,
                  size: 40,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Delete Account?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              
              // Description
              const Text(
                'This will permanently delete your account from authentication. Your data will be marked as deleted but retained for legal compliance.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 8),
              
              // What will be deleted
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This will delete:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildDeleteItem('Your authentication access'),
                    _buildDeleteItem('Profile marked as deleted'),
                    _buildDeleteItem('No account recovery possible'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await _deleteAccount();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Delete Account',
                        style: TextStyle(
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
        ),
      ),
    );
  }
  
  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            Icons.close,
            size: 16,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
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
      if (e.toString().contains('REAUTH_REQUIRED')) {
        _showReauthDialog();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReauthDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _ReauthDialog(
        onSuccess: () async {
          Navigator.pop(context);
          await _deleteAccount();
        },
      ),
    );
  }

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all((MediaQuery.of(context).size.width * 0.05).clamp(16.0, 20.0)),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width * 0.04).clamp(16.0, 20.0)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: (MediaQuery.of(context).size.width * 0.12).clamp(40.0, 48.0),
              height: (MediaQuery.of(context).size.width * 0.12).clamp(40.0, 48.0),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular((MediaQuery.of(context).size.width * 0.03).clamp(10.0, 12.0)),
              ),
              child: Icon(
                icon,
                size: (MediaQuery.of(context).size.width * 0.06).clamp(20.0, 24.0),
                color: AppTheme.primaryColor,
              ),
            ),
            SizedBox(width: (MediaQuery.of(context).size.width * 0.04).clamp(16.0, 20.0)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: (MediaQuery.of(context).size.width * 0.045).clamp(16.0, 18.0),
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF1F2937),
                      letterSpacing: -0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: (MediaQuery.of(context).size.height * 0.008).clamp(3.0, 5.0)),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: (MediaQuery.of(context).size.width * 0.035).clamp(13.0, 15.0),
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: (MediaQuery.of(context).size.width * 0.04).clamp(14.0, 16.0),
              color: AppTheme.primaryColor.withOpacity(0.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReauthDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  
  const _ReauthDialog({required this.onSuccess});
  
  @override
  State<_ReauthDialog> createState() => _ReauthDialogState();
}

class _ReauthDialogState extends State<_ReauthDialog> {
  String? _verificationId;
  String _otpCode = '';
  bool _isLoading = false;
  bool _codeSent = false;
  
  @override
  void initState() {
    super.initState();
    _sendOTP();
  }
  
  Future<void> _sendOTP() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.phoneNumber == null) return;
    
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: user!.phoneNumber!,
        verificationCompleted: (credential) {},
        verificationFailed: (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to send OTP: ${e.message}')),
          );
        },
        codeSent: (verificationId, resendToken) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _isLoading = false;
          });
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  Future<void> _verifyOTP() async {
    if (_verificationId == null || _otpCode.length != 6) return;
    
    setState(() => _isLoading = true);
    
    try {
      await UserService.reauthenticateWithPhone(_verificationId!, _otpCode);
      widget.onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Invalid OTP: $e')),
      );
    }
    
    setState(() => _isLoading = false);
  }
  
  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Verify Identity',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            Text(
              _codeSent 
                  ? 'Enter the OTP sent to your phone'
                  : 'Sending OTP...',
              textAlign: TextAlign.center,
            ),
            if (_codeSent) ...[
              SizedBox(height: 20),
              TextField(
                onChanged: (value) => _otpCode = value,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: InputDecoration(
                  labelText: 'OTP Code',
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Cancel'),
                    ),
                  ),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      child: _isLoading 
                          ? CircularProgressIndicator()
                          : Text('Verify'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}