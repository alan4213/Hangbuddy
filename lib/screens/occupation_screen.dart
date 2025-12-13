import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'religion_screen.dart';
import '../widgets/progress_bar.dart';

class OccupationScreen extends StatefulWidget {
  final SignupData signupData;
  const OccupationScreen({super.key, required this.signupData});

  @override
  State<OccupationScreen> createState() => _OccupationScreenState();
}

class _OccupationScreenState extends State<OccupationScreen> {
  String? _selectedOccupation;
  bool _isLoading = false;
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
    _selectedOccupation = widget.signupData.occupation;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const ProgressBar(currentStep: 6, totalSteps: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What\'s your occupation?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Let others know what you do for work - it\'s a great conversation starter!',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Occupation dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _selectedOccupation != null ? AppTheme.primaryColor : Colors.grey.shade300,
                    width: _selectedOccupation != null ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedOccupation,
                    hint: Text(
                      'Select your occupation',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 16,
                      ),
                    ),
                    isExpanded: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: AppTheme.primaryColor,
                    ),
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                    dropdownColor: Colors.white,
                    items: _occupations.map((occupation) => DropdownMenuItem(
                      value: occupation,
                      child: Text(
                        occupation,
                        style: TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedOccupation = value),
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 48),
              
              LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
                  if (_selectedOccupation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your occupation')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  widget.signupData.occupation = _selectedOccupation;
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ReligionScreen(signupData: widget.signupData),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
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