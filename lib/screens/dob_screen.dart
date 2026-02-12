import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
            if (!widget.isEditMode) const ProgressBar(currentStep: 2, totalSteps: 8),
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
                    'What\'s your date of birth?',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.015),
                  Text(
                    'We use this to calculate your age and find age-appropriate hangout buddies.',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  
                  SizedBox(height: MediaQuery.of(context).size.height * 0.06),
                  
                  // Date input field with picker
                  TextField(
                    controller: _dateController,
                    decoration: InputDecoration(
                      hintText: 'DD/MM/YYYY',
                      suffixIcon: IconButton(
                        icon: Icon(Icons.calendar_today, color: AppTheme.primaryColor),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onChanged: (value) {
                      final parts = value.split('/');
                      if (parts.length == 3) {
                        final day = int.tryParse(parts[0]);
                        final month = int.tryParse(parts[1]);
                        final year = int.tryParse(parts[2]);
                        if (day != null && month != null && year != null && year > 1900 && year <= DateTime.now().year) {
                          try {
                            final date = DateTime(year, month, day);
                            setState(() => _selectedDate = date);
                          } catch (e) {
                            setState(() => _selectedDate = null);
                          }
                        }
                      }
                    },
                  ),
                  
                  if (_selectedDate != null) ...[
                    SizedBox(height: MediaQuery.of(context).size.height * 0.025),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                          ? Colors.red.withOpacity(0.1)
                          : AppTheme.primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                            ? Colors.red.withOpacity(0.3)
                            : AppTheme.primaryColor.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                                ? Colors.red
                                : AppTheme.primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              DateTime.now().difference(_selectedDate!).inDays < 6570 
                                ? Icons.warning
                                : Icons.check,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Age: ${DateTime.now().difference(_selectedDate!).inDays ~/ 365} years old',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: DateTime.now().difference(_selectedDate!).inDays < 6570 
                                      ? Colors.red
                                      : AppTheme.primaryColor,
                                  ),
                                ),
                                if (DateTime.now().difference(_selectedDate!).inDays < 6570)
                                  Text(
                                    'You must be at least 18 years old to use Haule',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.red.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  )
                                else
                                  Text(
                                    'Perfect! You meet the age requirement',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.primaryColor.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
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
                text: widget.isEditMode ? 'Save' : 'Continue',
                onPressed: () async {
                  if (_selectedDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your date of birth')),
                    );
                    return;
                  }
                  if (DateTime.now().difference(_selectedDate!).inDays < 6570) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Age criteria not met. You must be at least 18 years old.')),
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