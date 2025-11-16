import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'gender_screen.dart';

class DobScreen extends StatefulWidget {
  final SignupData signupData;
  const DobScreen({super.key, required this.signupData});

  @override
  State<DobScreen> createState() => _DobScreenState();
}

class _DobScreenState extends State<DobScreen> {
  DateTime? _selectedDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.signupData.birthday;
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
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                'What\'s your date of birth?',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              
              const SizedBox(height: 48),
              
              // Date of birth
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 6570)),
                    firstDate: DateTime.now().subtract(const Duration(days: 36500)),
                    lastDate: DateTime.now().subtract(const Duration(days: 6570)),
                  );
                  if (date != null) {
                    setState(() => _selectedDate = date);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDate == null 
                          ? 'Select Date of Birth' 
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null ? Colors.grey : AppTheme.textPrimary,
                        ),
                      ),
                      Icon(Icons.calendar_today, color: AppTheme.primaryColor),
                    ],
                  ),
                ),
              ),
              
              if (_selectedDate != null) ...[
                const SizedBox(height: 16),
                Text(
                  'Age: ${DateTime.now().difference(_selectedDate!).inDays ~/ 365}',
                  style: TextStyle(
                    fontSize: 14,
                    color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                      ? Colors.red : AppTheme.textSecondary,
                  ),
                ),
                if (DateTime.now().difference(_selectedDate!).inDays < 6570)
                  Text(
                    'You must be at least 18 years old',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
              ],
              
                const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            left: 32,
            right: 32,
            child: LoadingButton(
              isLoading: _isLoading,
              text: 'Continue',
              onPressed: () async {
                if (_selectedDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select your date of birth')),
                  );
                  return;
                }
                if (DateTime.now().difference(_selectedDate!).inDays < 6570) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('You must be at least 18 years old')),
                  );
                  return;
                }
                
                setState(() => _isLoading = true);
                
                widget.signupData.birthday = _selectedDate;
                
                await Future.delayed(const Duration(milliseconds: 300));
                if (mounted) {
                  setState(() => _isLoading = false);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => GenderScreen(signupData: widget.signupData),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}