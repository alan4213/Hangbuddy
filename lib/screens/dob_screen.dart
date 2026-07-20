import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'gender_screen.dart';
import '../widgets/progress_bar.dart';

class DobScreen extends StatefulWidget {
  final SignupData? signupData;
  final DateTime? initialDate;
  final bool isEditMode;
  
  const DobScreen({
    super.key, 
    this.signupData,
    this.initialDate,
    this.isEditMode = false,
  });

  @override
  State<DobScreen> createState() => _DobScreenState();
}

class _DobScreenState extends State<DobScreen> {
  DateTime? _selectedDate;
  bool _isLoading = false;
  final TextEditingController _dateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.isEditMode 
        ? widget.initialDate 
        : widget.signupData?.birthday;
    if (_selectedDate != null) {
      _dateController.text = '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isEditMode ? 'Edit DOB' : 'Create Profile',
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
                  const ProgressBar(currentStep: 2, totalSteps: 8),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'What\'s your date of birth?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'We use this to calculate your age and find age-appropriate hangout buddies.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        
                        const SizedBox(height: 48),
                        
                        // Date input field with picker
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: TextField(
                            controller: _dateController,
                            readOnly: true, // Typically date fields with pickers should be readOnly to prevent manual keyboard entry causing parsing issues
                            onTap: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: _selectedDate ?? DateTime(2000),
                                firstDate: DateTime(1950),
                                lastDate: DateTime.now(),
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: ColorScheme.light(
                                        primary: AppTheme.primaryColor,
                                        onPrimary: Colors.white,
                                        surface: Colors.white,
                                        onSurface: Colors.black,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (date != null) {
                                setState(() {
                                  _selectedDate = date;
                                  _dateController.text = '${date.day}/${date.month}/${date.year}';
                                });
                              }
                            },
                            style: GoogleFonts.poppins(
                              color: const Color(0xFF1E293B),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'DD/MM/YYYY',
                              hintStyle: GoogleFonts.poppins(
                                color: const Color(0xFF94A3B8),
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.calendar_today, color: Color(0xFF94A3B8)),
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: _selectedDate ?? DateTime(2000),
                                    firstDate: DateTime(1950),
                                    lastDate: DateTime.now(),
                                    builder: (context, child) {
                                      return Theme(
                                        data: Theme.of(context).copyWith(
                                          colorScheme: ColorScheme.light(
                                            primary: AppTheme.primaryColor,
                                            onPrimary: Colors.white,
                                            surface: Colors.white,
                                            onSurface: Colors.black,
                                          ),
                                        ),
                                        child: child!,
                                      );
                                    },
                                  );
                                  if (date != null) {
                                    setState(() {
                                      _selectedDate = date;
                                      _dateController.text = '${date.day}/${date.month}/${date.year}';
                                    });
                                  }
                                },
                              ),
                            ),
                          ),
                        ),
                        
                        if (_selectedDate != null) ...[
                          SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 24,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFECFDF5),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    DateTime.now().difference(_selectedDate!).inDays < 6570 
                                      ? Icons.close_rounded
                                      : Icons.check_rounded,
                                    color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                                      ? const Color(0xFFDC2626) // Red
                                      : const Color(0xFF059669), // Green
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Age: ${DateTime.now().difference(_selectedDate!).inDays ~/ 365}',
                                        style: GoogleFonts.poppins(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: const Color(0xFF1F2937),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      if (DateTime.now().difference(_selectedDate!).inDays < 6570)
                                        Text(
                                          'Must be 18 or older to join',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFFEF4444),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        )
                                      else
                                        Text(
                                          'Age requirement met',
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                            color: const Color(0xFF6B7280),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                if (DateTime.now().difference(_selectedDate!).inDays >= 6570)
                                  const Icon(
                                    Icons.verified,
                                    color: Color(0xFF10B981),
                                    size: 28,
                                  )
                                else
                                  const Icon(
                                    Icons.error,
                                    color: Color(0xFFEF4444),
                                    size: 28,
                                  ),
                              ],
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
                        ],
                      )
                    else
                      Text(
                        'Edit Date of Birth',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        if (_selectedDate == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.info_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'Please select your date of birth',
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFF64748B), // Slate
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                          return;
                        }
                        if (DateTime.now().difference(_selectedDate!).inDays < 6570) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Colors.white),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'You must be at least 18 years old to join.',
                                      style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: const Color(0xFFEF4444), // Red
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                          return;
                        }
                        
                        if (widget.isEditMode) {
                          Navigator.pop(context, _selectedDate);
                        } else {
                          setState(() => _isLoading = true);
                          widget.signupData!.birthday = _selectedDate;
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => GenderScreen(signupData: widget.signupData!),
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