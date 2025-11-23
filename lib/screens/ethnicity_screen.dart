import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Custom back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back, color: AppTheme.textPrimary),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'What\'s your ethnicity?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
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
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedEthnicity == ethnicity ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedEthnicity == ethnicity ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      ethnicity,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedEthnicity == ethnicity ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )).toList(),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
              
              LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
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
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}