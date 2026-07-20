import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import '../widgets/progress_bar.dart';
import '../utils/responsive.dart';
import 'education_screen.dart';

class EthnicityScreen extends StatefulWidget {
  final SignupData signupData;
  const EthnicityScreen({super.key, required this.signupData});

  @override
  State<EthnicityScreen> createState() => _EthnicityScreenState();
}

class _EthnicityScreenState extends State<EthnicityScreen> {
  String? _selectedEthnicity;
  bool _isLoading = false;
  final List<String> _ethnicities = [
    'Asian', 'Black', 'Hispanic/Latino', 'White', 'Native American', 
    'Pacific Islander', 'Mixed', 'Other', 'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _selectedEthnicity = widget.signupData.race;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          'Create Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.signupData.race = null;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EducationScreen(signupData: widget.signupData),
                ),
              );
            },
            child: Text(
              'Skip',
              style: GoogleFonts.poppins(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ProgressBar(currentStep: 5, totalSteps: 8),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'What\'s your ethnicity?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Ethnicity options
                        ..._ethnicities.map((ethnicity) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedEthnicity = ethnicity),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedEthnicity == ethnicity ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                  width: _selectedEthnicity == ethnicity ? 2 : 1.5,
                                ),
                                boxShadow: _selectedEthnicity == ethnicity ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              child: Text(
                                ethnicity,
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  color: const Color(0xFF1E293B),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        )).toList(),
                        
                        SizedBox(height: MediaQuery.of(context).size.height * 0.125),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom Bar
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                  ? MediaQuery.of(context).viewInsets.bottom + 16
                  : 32,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () async {
                        if (_selectedEthnicity == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select your ethnicity')),
                          );
                          return;
                        }
                        
                        setState(() => _isLoading = true);
                        widget.signupData.race = _selectedEthnicity;
                        await Future.delayed(const Duration(milliseconds: 300));
                        if (mounted) {
                          setState(() => _isLoading = false);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EducationScreen(signupData: widget.signupData),
                            ),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}