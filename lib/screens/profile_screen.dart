import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
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
import '../widgets/premium_dialog.dart';
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
  UserModel? _userProfile = UserService.cachedProfile;
  bool _isLoading = UserService.cachedProfile == null;
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
        child: SingleChildScrollView(
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
                      style: GoogleFonts.poppins(
                        fontSize: 28.0,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Profile Image
              Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryColor, width: 3),
                    ),
                    child: ProfileImageWidget(
                      imageUrl: _userProfile?.profileImageUrl,
                      size: (MediaQuery.of(context).size.width * 0.28).clamp(90.0, 110.0),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () async {
                        await Navigator.pushNamed(context, '/profile-details');
                        _loadUserProfile();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.edit,
                          size: 14,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '67%',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
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
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.check_circle,
                    color: _verificationStatus == 'verified' ? AppTheme.primaryColor : Colors.grey[400],
                    size: 20,
                  ),
                ],
              ),
              
              const SizedBox(height: 8),
              
              // Subtitle texts
              Text(
                'Incomplete profile',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Complete your profile to get better matches.',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey[600],
                ),
              ),
              
              const SizedBox(height: 24),
            
            // Content
            Padding(
              padding: EdgeInsets.symmetric(horizontal: (MediaQuery.of(context).size.width * 0.05).clamp(12.0, 20.0)),
              child: Column(
                children: [
                    // Notifications
                    _buildMenuCard(
                      Icons.notifications_outlined,
                      'Notifications',
                      'See your latest activity',
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                        );
                      },
                      iconBgColor: AppTheme.primaryColor.withOpacity(0.1),
                      iconColor: AppTheme.primaryColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Verify Profile
                    _buildMenuCard(
                      Icons.verified_user_outlined,
                      'Verify Profile',
                      'Identity trust status',
                      () => _showVerificationSheet(),
                      iconBgColor: AppTheme.primaryColor.withOpacity(0.1),
                      iconColor: AppTheme.primaryColor,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Help Centre
                    _buildMenuCard(
                      Icons.help_outline,
                      'Help Centre',
                      'Support and common FAQs',
                      () async {
                        final url = Uri.parse('mailto:team@hauleapp.com');
                        try {
                          final launched = await launchUrl(url);
                          if (!launched && context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open email app. Reach us at team@hauleapp.com')),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open email app. Reach us at team@hauleapp.com')),
                            );
                          }
                        }
                      },
                      iconBgColor: Colors.orange.withOpacity(0.15),
                      iconColor: Colors.orange[800],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Logout
                    _buildMenuCard(
                      Icons.logout,
                      'Logout',
                      'Sign out of session',
                      () async {
                        UserService.clearCache();
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
                      },
                      iconBgColor: Colors.grey.withOpacity(0.15),
                      iconColor: Colors.grey[800],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Delete Account
                    _buildMenuCard(
                      Icons.delete_outline,
                      'Delete Account',
                      'Permanently remove data',
                      () => _showDeleteAccountDialog(),
                      isDestructive: true,
                    ),
                    ],
                  ),
                ),
              // Bottom padding for scrolling
              const SizedBox(height: 32),
            ],
          ),
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
      builder: (context) => PremiumDialog(
        title: 'Delete Account?',
        subtitle: 'This action cannot be undone. All your data, matches, and hangouts will be permanently removed from Haule.',
        primaryActionText: 'Delete',
        secondaryActionText: 'Cancel',
        onPrimaryAction: () async {
          Navigator.pop(context);
          await _deleteAccount();
        },
        customContent: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What happens next:',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF4B5563),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 12),
              _buildDeleteItem('Authentication access revoked immediately'),
              _buildDeleteItem('Profile & photos permanently deleted'),
              _buildDeleteItem('No account recovery possible'),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(
              Icons.close_rounded,
              size: 16,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.poppins(
                fontSize: 13,
                color: const Color(0xFF374151),
                height: 1.4,
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
      
      // Show modern success popup
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PremiumDialog(
          title: 'Account Deleted',
          subtitle: 'Your account has been successfully deleted. You can create a new account anytime.',
          primaryActionText: 'Got it',
          onPrimaryAction: () => Navigator.pop(context),
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

  Widget _buildMenuCard(IconData icon, String title, String subtitle, VoidCallback onTap, {bool isDestructive = false, Color? iconBgColor, Color? iconColor}) {
    final finalIconColor = isDestructive ? const Color(0xFFDC2626) : const Color(0xFF8B5CF6);
    final finalIconBgColor = isDestructive ? const Color(0xFFFEE2E2) : const Color(0xFFF3E8FF);
    final textColor = isDestructive ? const Color(0xFFDC2626) : Colors.black87;
    final subtextColor = Colors.grey[500];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.0),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 48.0,
              height: 48.0,
              decoration: BoxDecoration(
                color: finalIconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24.0,
                color: finalIconColor,
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 15.0,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2.0),
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      fontSize: 13.0,
                      color: subtextColor,
                      fontWeight: FontWeight.w400,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20.0,
              color: Colors.grey[400],
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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Verify Identity',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 12),
            
            // Description
            Text(
              _codeSent 
                  ? 'Enter the 6-digit code sent to your phone'
                  : 'Sending verification code...',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
                height: 1.4,
              ),
            ),
            
            if (_codeSent) ...[
              SizedBox(height: 24),
              TextField(
                onChanged: (value) => _otpCode = value,
                keyboardType: TextInputType.number,
                maxLength: 6,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 8,
                ),
                decoration: InputDecoration(
                  labelText: 'OTP Code',
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                ),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _verifyOTP,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              'Verify',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              SizedBox(height: 24),
              CircularProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
}