import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'dob_screen.dart';
import '../widgets/progress_bar.dart';

class NameScreen extends StatefulWidget {
  final SignupData? signupData;
  const NameScreen({super.key, this.signupData});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  bool _isLoading = false;
  late SignupData signupData;

  @override
  void initState() {
    super.initState();
    signupData = widget.signupData ?? SignupData();
    
    // Auto-populate from Google user if available
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null && signupData.firstName == null) {
      final nameParts = user!.displayName!.split(' ');
      signupData.firstName = nameParts.first;
      if (nameParts.length > 1) {
        signupData.lastName = nameParts.skip(1).join(' ');
      }
    }
    
    _firstNameController.text = signupData.firstName ?? '';
    _lastNameController.text = signupData.lastName ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
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
            const ProgressBar(currentStep: 1, totalSteps: 8),
            Expanded(
              child: Stack(
                children: [
                  SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: EdgeInsets.only(
                left: MediaQuery.of(context).size.width * 0.08,
                right: MediaQuery.of(context).size.width * 0.08,
                top: MediaQuery.of(context).size.width * 0.08,
                bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).size.height * 0.15,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What\'s your name?',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                  Text(
                    'This is how you\'ll appear to other users. Use your real name to build trust.',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                  
                  // First Name input
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _firstNameController,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'First Name',
                        labelStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.03),
                  
                  // Last Name input (optional)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _lastNameController,
                      style: TextStyle(
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Last Name (Optional)',
                        labelStyle: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 16,
                        ),
                        floatingLabelStyle: TextStyle(
                          color: AppTheme.primaryColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: AppTheme.primaryColor, width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.125),
                ],
              ),
            ),
            Positioned(
              bottom: MediaQuery.of(context).size.height * 0.025,
              left: MediaQuery.of(context).size.width * 0.08,
              right: MediaQuery.of(context).size.width * 0.08,
              child: LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
                  if (_firstNameController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter your first name')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  signupData.firstName = _firstNameController.text;
                  signupData.lastName = _lastNameController.text;
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DobScreen(signupData: signupData),
                      ),
                    );
                  }
                },
              ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}