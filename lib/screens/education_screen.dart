import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'occupation_screen.dart';

class EducationScreen extends StatefulWidget {
  final SignupData signupData;
  const EducationScreen({super.key, required this.signupData});

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
    _selectedEducation = widget.signupData.education;
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What\'s your education level?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Education dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEducation,
                    hint: Text('Select your education level'),
                    isExpanded: true,
                    items: _educations.map((education) => DropdownMenuItem(
                      value: education,
                      child: Text(education),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedEducation = value),
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 3),
              
              LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
                  if (_selectedEducation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your education level')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  widget.signupData.education = _selectedEducation;
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => OccupationScreen(signupData: widget.signupData),
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
    );
  }
}