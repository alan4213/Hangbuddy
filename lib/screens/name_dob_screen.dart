import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'personal_info_screen.dart';

class NameDobScreen extends StatefulWidget {
  final SignupData? signupData;
  const NameDobScreen({super.key, this.signupData});

  @override
  State<NameDobScreen> createState() => _NameDobScreenState();
}

class _NameDobScreenState extends State<NameDobScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  DateTime? _selectedDate;
  bool _isLoading = false;
  late SignupData signupData;

  @override
  void initState() {
    super.initState();
    signupData = widget.signupData ?? SignupData();
    _firstNameController.text = signupData.firstName ?? '';
    _lastNameController.text = signupData.lastName ?? '';
    _selectedDate = signupData.birthday;
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
                'About You',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Tell us your name and date of birth',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // First Name input
              TextField(
                controller: _firstNameController,
                decoration: InputDecoration(
                  labelText: 'First Name',
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Last Name input (optional)
              TextField(
                controller: _lastNameController,
                decoration: InputDecoration(
                  labelText: 'Last Name (Optional)',
                  labelStyle: TextStyle(color: AppTheme.primaryColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Date of birth
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
                    firstDate: DateTime.now().subtract(const Duration(days: 36500)), // 100 years ago
                    lastDate: DateTime.now().subtract(const Duration(days: 6570)), // 18 years ago
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
                          ? 'Date of Birth' 
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
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
              
              LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
                  if (_firstNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your first name')),
                    );
                    return;
                  }
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
                  
                  signupData.firstName = _firstNameController.text;
                  signupData.lastName = _lastNameController.text;
                  signupData.birthday = _selectedDate;
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PersonalInfoScreen(signupData: signupData),
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