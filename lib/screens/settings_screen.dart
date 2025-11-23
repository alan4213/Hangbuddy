import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../services/user_service.dart';
import '../models/user_model.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _userProfile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      final profile = await UserService.getUserProfile();
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
          // Account Information Card
          _buildAccountInfoCard(),
          
          SizedBox(height: 20),
          
          _buildSettingsCard([
            _buildSettingsItem(Icons.privacy_tip_outlined, 'Privacy', () {}),
            _buildSettingsItem(Icons.notifications_outlined, 'Notifications', () {}),
            _buildSettingsItem(Icons.block_outlined, 'Blocked Users', () {}),
          ]),
          
          SizedBox(height: 20),
          
          _buildSettingsCard([
            _buildSettingsItem(Icons.language_outlined, 'Language', () {}),
            _buildSettingsItem(Icons.dark_mode_outlined, 'Theme', () {}),
            _buildSettingsItem(Icons.location_on_outlined, 'Location', () {}),
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

  Widget _buildSettingsCard(List<Widget> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(children: items),
    );
  }

  Widget _buildAccountInfoCard() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Account Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          SizedBox(height: 16),
          if (_isLoading)
            Center(child: CircularProgressIndicator())
          else ...[
            _buildInfoRow('Name', '${_userProfile?.firstName ?? 'N/A'} ${_userProfile?.lastName ?? ''}'),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildInfoRow('Phone Number', _userProfile?.phoneNumber ?? 'Not set'),
                ),
                TextButton(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    print('Current user: ${user?.uid}');
                    print('User phone: ${user?.phoneNumber}');
                    print('Providers: ${user?.providerData.map((p) => '${p.providerId}: ${p.phoneNumber}')}');
                    
                    String? phoneNumber = user?.phoneNumber;
                    if (phoneNumber == null || phoneNumber.isEmpty) {
                      for (final provider in user?.providerData ?? []) {
                        if (provider.phoneNumber != null && provider.phoneNumber!.isNotEmpty) {
                          phoneNumber = provider.phoneNumber;
                          break;
                        }
                      }
                    }
                    
                    if (phoneNumber != null && phoneNumber.isNotEmpty) {
                      await UserService.forceUpdatePhoneNumber(phoneNumber);
                      _loadUserProfile();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Phone updated: $phoneNumber')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('No phone number found in auth')),
                      );
                    }
                  },
                  child: Text('Debug'),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildInfoRow('Age', _userProfile?.age?.toString() ?? 'Not set'),
          ]
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
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