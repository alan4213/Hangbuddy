import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
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
  UserModel? _userProfile = UserService.cachedProfile;
  bool _isLoading = true;
  bool _notificationsMuted = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  void _loadUserProfile() async {
    try {
      final muted = await PreferencesService.areNotificationsMuted();
      setState(() {
        _notificationsMuted = muted;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading preferences: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Very light grey for contrast
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                'Settings',
                style: GoogleFonts.poppins(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Preferences'),
                  const SizedBox(height: 12),
                  _buildNotificationToggle(),
                  const SizedBox(height: 32),
                  _buildSectionHeader('Legal & Support'),
                  const SizedBox(height: 12),
                  _buildSettingsGroup([
                    _buildSettingsItem(
                      icon: Icons.privacy_tip_rounded,
                      title: 'Privacy Policy',
                      onTap: () async {
                        final url = Uri.parse('https://hauleapp.com/privacy.html');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                    ),
                    _buildSettingsItem(
                      icon: Icons.help_rounded,
                      title: 'Help & Support',
                      onTap: () async {
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
                    ),
                    _buildSettingsItem(
                      icon: Icons.info_rounded,
                      title: 'About Haule',
                      onTap: () async {
                        final url = Uri.parse('https://hauleapp.com');
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                      },
                      isLast: true,
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.grey[500],
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsGroup(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildNotificationToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _notificationsMuted
                ? Colors.grey[100]
                : AppTheme.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            _notificationsMuted ? Icons.notifications_off_rounded : Icons.notifications_active_rounded,
            color: _notificationsMuted ? Colors.grey[500] : AppTheme.primaryColor,
            size: 22,
          ),
        ),
        title: Text(
          'Mute Notifications',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          'Pause all alerts',
          style: GoogleFonts.poppins(
            fontSize: 13,
            color: Colors.grey[500],
          ),
        ),
        trailing: Switch.adaptive(
          value: _notificationsMuted,
          activeColor: AppTheme.primaryColor,
          activeTrackColor: AppTheme.primaryColor.withOpacity(0.3),
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

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLast = false,
  }) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryColor,
              size: 22,
            ),
          ),
          title: Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios_rounded,
            size: 16,
            color: Colors.grey[400],
          ),
          onTap: onTap,
        ),
        if (!isLast)
          Divider(
            height: 1,
            indent: 70,
            endIndent: 20,
            color: Colors.grey[100],
          ),
      ],
    );
  }
}