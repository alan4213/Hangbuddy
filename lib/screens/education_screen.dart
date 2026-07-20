import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'occupation_screen.dart';
import '../widgets/progress_bar.dart';


class EducationScreen extends StatefulWidget {
  final SignupData? signupData;
  final String? initialEducation;
  final bool isEditMode;
  
  const EducationScreen({
    super.key, 
    this.signupData,
    this.initialEducation,
    this.isEditMode = false,
  });

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  String? _selectedEducation;
  bool _isLoading = false;
  final List<String> _educations = [
    'High School', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD', 'Trade School', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    _selectedEducation = widget.isEditMode 
        ? widget.initialEducation 
        : widget.signupData?.education;
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
          widget.isEditMode ? 'Edit Education' : 'Create Profile',
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
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditMode)
                  const ProgressBar(currentStep: 6, totalSteps: 8),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'What\'s your education level?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Share your educational background to connect with like-minded people.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Education options
                        ..._educations.map((education) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedEducation = education),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: _selectedEducation == education ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                                  width: _selectedEducation == education ? 2 : 1.5,
                                ),
                                boxShadow: _selectedEducation == education ? [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  )
                                ] : null,
                              ),
                              child: Text(
                                education,
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
                    if (!widget.isEditMode)
                      Row(
                        children: [
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)),
                        ],
                      )
                    else
                      Text(
                        'Edit Education',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        if (_selectedEducation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select your education level')),
                          );
                          return;
                        }
                        
                        if (widget.isEditMode) {
                          Navigator.pop(context, _selectedEducation);
                        } else {
                          setState(() => _isLoading = true);
                          widget.signupData!.education = _selectedEducation!;
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => OccupationScreen(signupData: widget.signupData!),
                              ),
                            );
                          }
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