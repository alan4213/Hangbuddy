import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${DateTime.now().year}',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly to us, such as when you create an account, update your profile, or contact us for support.',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'We use the information we collect to provide, maintain, and improve our services, process transactions, and communicate with you.',
            ),
            _buildSection(
              '3. Information Sharing',
              'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
            ),
            _buildSection(
              '4. Data Security',
              'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
            ),
            _buildSection(
              '5. Location Information',
              'We may collect and use your location information to provide location-based services. You can control location sharing through your device settings.',
            ),
            _buildSection(
              '6. Photos and Media',
              'Photos you upload are stored securely and are only visible to users you choose to connect with through our matching system.',
            ),
            _buildSection(
              '7. Communications',
              'We may send you service-related communications, including account verification, security alerts, and updates about our services.',
            ),
            _buildSection(
              '8. Data Retention',
              'We retain your information for as long as your account is active or as needed to provide you services and comply with legal obligations.',
            ),
            _buildSection(
              '9. Your Rights',
              'You have the right to access, update, or delete your personal information. You can do this through your account settings or by contacting us.',
            ),
            _buildSection(
              '10. Changes to Privacy Policy',
              'We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page.',
            ),
            const SizedBox(height: 32),
            Text(
              'Contact Us',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'If you have any questions about this Privacy Policy, please contact us at privacy@haule.com',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[700],
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}