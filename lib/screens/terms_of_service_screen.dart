import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
              'Terms of Service',
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
              '1. Acceptance of Terms',
              'By accessing and using Haule, you accept and agree to be bound by the terms and provision of this agreement.',
            ),
            _buildSection(
              '2. Use License',
              'Permission is granted to temporarily use Haule for personal, non-commercial transitory viewing only.',
            ),
            _buildSection(
              '3. User Accounts',
              'You are responsible for safeguarding the password and for maintaining the confidentiality of your account.',
            ),
            _buildSection(
              '4. Privacy Policy',
              'Your privacy is important to us. Please review our Privacy Policy, which also governs your use of the Service.',
            ),
            _buildSection(
              '5. Prohibited Uses',
              'You may not use our service for any unlawful purpose or to solicit others to perform unlawful acts.',
            ),
            _buildSection(
              '6. Content',
              'Our service allows you to post, link, store, share and otherwise make available certain information, text, graphics, videos, or other material.',
            ),
            _buildSection(
              '7. Termination',
              'We may terminate or suspend your account and bar access to the service immediately, without prior notice or liability.',
            ),
            _buildSection(
              '8. Changes to Terms',
              'We reserve the right to modify these terms at any time. We will notify users of any changes by posting the new Terms of Service on this page.',
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
              'If you have any questions about these Terms of Service, please contact us at support@haule.com',
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