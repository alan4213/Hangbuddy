import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../services/preferences_service.dart';
import '../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _userProfile;
  bool _isLoading = true;
  bool _notificationsMuted = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      final profile = await UserService.getUserProfile();
      final muted = await PreferencesService.areNotificationsMuted();
      setState(() {
        _userProfile = profile;
        _notificationsMuted = muted;
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(20),
        children: [
          _buildSettingsCard([
            _buildNotificationToggle(),
          ]),
          
          SizedBox(height: 20),
          
          _buildSettingsCard([
            _buildSettingsItem(Icons.privacy_tip_outlined, 'Privacy', () {}),
          ]),
          
          SizedBox(height: 20),
          
          _buildSettingsCard([
            _buildSettingsItem(Icons.help_outline, 'Help & Support', () {}),
            _buildSettingsItem(Icons.info_outline, 'About', () {}),
          ]),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            _notificationsMuted ? Icons.notifications_off : Icons.notifications,
            color: AppTheme.primaryColor,
            size: 20,
          ),
        ),
        title: Text(
          'Mute All Notifications',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Switch(
          value: _notificationsMuted,
          activeColor: AppTheme.primaryColor,
          onChanged: (value) async {
            await PreferencesService.setNotificationsMuted(value);
            setState(() {
              _notificationsMuted = value;
            });
          },
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, VoidCallback onTap) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}