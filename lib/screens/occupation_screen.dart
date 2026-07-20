import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'religion_screen.dart';
import '../widgets/progress_bar.dart';

class OccupationScreen extends StatefulWidget {
  final SignupData? signupData;
  final String? initialOccupation;
  final bool isEditMode;
  
  const OccupationScreen({
    super.key, 
    this.signupData,
    this.initialOccupation,
    this.isEditMode = false,
  });

  @override
  State<OccupationScreen> createState() => _OccupationScreenState();
}

class _OccupationScreenState extends State<OccupationScreen> {
  String? _selectedOccupation;
  bool _isLoading = false;
  final TextEditingController _customOccupationController = TextEditingController();
  final List<String> _occupations = [
    'Software Engineer', 'Product Manager', 'Designer', 'Data Scientist', 'Marketing Manager',
    'Sales Representative', 'Consultant', 'Teacher', 'Doctor', 'Nurse', 'Lawyer', 'Accountant',
    'Financial Analyst', 'Project Manager', 'Business Analyst', 'Engineer', 'Architect',
    'Chef', 'Artist', 'Writer', 'Photographer', 'Real Estate Agent', 'Entrepreneur',
    'Student', 'Researcher', 'Therapist', 'Social Worker', 'HR Manager', 'Operations Manager',
    'Customer Success', 'UX/UI Designer', 'Content Creator', 'Freelancer', 'Other'
  ];

  @override
  void initState() {
    super.initState();
    String? initial = widget.isEditMode 
        ? widget.initialOccupation 
        : widget.signupData?.occupation;
        
    if (initial != null) {
      if (_occupations.contains(initial)) {
        _selectedOccupation = initial;
      } else {
        _selectedOccupation = 'Other';
        _customOccupationController.text = initial;
      }
    }
  }

  @override
  void dispose() {
    _customOccupationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.isEditMode ? 'Edit Occupation' : 'Create Profile',
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
                  const ProgressBar(currentStep: 7, totalSteps: 8),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'What\'s your occupation?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Let others know what you do for work - it\'s a great conversation starter!',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Occupation dropdown
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: _selectedOccupation != null ? AppTheme.primaryColor : const Color(0xFFE2E8F0),
                              width: _selectedOccupation != null ? 2 : 1.5,
                            ),
                            boxShadow: _selectedOccupation != null ? [
                              BoxShadow(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ] : null,
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedOccupation,
                              hint: Text(
                                'Select your occupation',
                                style: GoogleFonts.poppins(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              isExpanded: true,
                              icon: const Icon(
                                Icons.keyboard_arrow_down,
                                color: Color(0xFF94A3B8),
                              ),
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E293B),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              dropdownColor: Colors.white,
                              items: _occupations.map((occupation) => DropdownMenuItem(
                                value: occupation,
                                child: Text(
                                  occupation,
                                  style: GoogleFonts.poppins(
                                    color: const Color(0xFF1E293B),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              )).toList(),
                              onChanged: (value) => setState(() => _selectedOccupation = value),
                            ),
                          ),
                        ),
                        
                        if (_selectedOccupation == 'Other') ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.primaryColor,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primaryColor.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: TextField(
                              controller: _customOccupationController,
                              style: GoogleFonts.poppins(
                                color: const Color(0xFF1E293B),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type your occupation',
                                hintStyle: GoogleFonts.poppins(
                                  color: const Color(0xFF94A3B8),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                        
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
                          Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE2E8F0))),
                          const SizedBox(width: 8),
                          Container(width: 6, height: 6, decoration: BoxDecoration(shape: BoxShape.circle, color: AppTheme.primaryColor)),
                        ],
                      )
                    else
                      Text(
                        'Edit Occupation',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        if (_selectedOccupation == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please select your occupation')),
                          );
                          return;
                        }
                        
                        String finalOccupation = _selectedOccupation!;
                        if (_selectedOccupation == 'Other') {
                          finalOccupation = _customOccupationController.text.trim();
                          if (finalOccupation.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please type your occupation')),
                            );
                            return;
                          }
                        }
                        
                        if (widget.isEditMode) {
                          Navigator.pop(context, finalOccupation);
                        } else {
                          setState(() => _isLoading = true);
                          widget.signupData!.occupation = finalOccupation;
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ReligionScreen(signupData: widget.signupData!),
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