import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'interests_screen.dart';
import '../widgets/progress_bar.dart';

class ReligionScreen extends StatefulWidget {
  final SignupData? signupData;
  final String? initialReligion;
  final bool isEditMode;
  
  const ReligionScreen({
    super.key, 
    this.signupData,
    this.initialReligion,
    this.isEditMode = false,
  });

  @override
  State<ReligionScreen> createState() => _ReligionScreenState();
}

class _ReligionScreenState extends State<ReligionScreen> {
  String? _selectedReligion;
  bool _isLoading = false;
  final List<String> _religions = [
    'Christianity', 'Islam', 'Judaism', 'Hinduism', 'Buddhism', 'Sikhism',
    'Atheist', 'Agnostic', 'Spiritual', 'Other', 'Prefer not to say'
  ];

  @override
  void initState() {
    super.initState();
    _selectedReligion = widget.isEditMode 
        ? widget.initialReligion 
        : widget.signupData?.religion;
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
            if (!widget.isEditMode) const ProgressBar(currentStep: 7, totalSteps: 8),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What\'s your religion?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Share your beliefs to find people who respect and understand your values.',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Religion options
              ..._religions.map((religion) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedReligion = religion),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _selectedReligion == religion ? AppTheme.primaryColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _selectedReligion == religion ? AppTheme.primaryColor : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      religion,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: _selectedReligion == religion ? Colors.white : AppTheme.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              )).toList(),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
              
              LoadingButton(
                isLoading: _isLoading,
                text: widget.isEditMode ? 'Save' : 'Continue',
                onPressed: () async {
                  if (_selectedReligion == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your religion')),
                    );
                    return;
                  }
                  
                  if (widget.isEditMode) {
                    Navigator.pop(context, _selectedReligion);
                  } else {
                    setState(() => _isLoading = true);
                    widget.signupData!.religion = _selectedReligion;
                    await Future.delayed(const Duration(milliseconds: 300));
                    if (mounted) {
                      setState(() => _isLoading = false);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => InterestsScreen(signupData: widget.signupData!),
                        ),
                      );
                    }
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