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
                'What\'s your ethnicity?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Ethnicity dropdown
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedEthnicity,
                    hint: Text('Select your ethnicity'),
                    isExpanded: true,
                    items: _ethnicities.map((ethnicity) => DropdownMenuItem(
                      value: ethnicity,
                      child: Text(ethnicity),
                    )).toList(),
                    onChanged: (value) => setState(() => _selectedEthnicity = value),
                  ),
                ),
              ),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 3),
              
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