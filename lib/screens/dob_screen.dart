import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'gender_screen.dart';
import '../widgets/progress_bar.dart';

class DobScreen extends StatefulWidget {
  final SignupData signupData;
  const DobScreen({super.key, required this.signupData});

  @override
  State<DobScreen> createState() => _DobScreenState();
}

class _DobScreenState extends State<DobScreen> {
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _useTextInput = false;
  final TextEditingController _dayController = TextEditingController();
  final TextEditingController _monthController = TextEditingController();
  final TextEditingController _yearController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.signupData.birthday;
    if (_selectedDate != null) {
      _dayController.text = _selectedDate!.day.toString();
      _monthController.text = _selectedDate!.month.toString();
      _yearController.text = _selectedDate!.year.toString();
    }
  }

  void _updateDateFromText() {
    final day = int.tryParse(_dayController.text);
    final month = int.tryParse(_monthController.text);
    final year = int.tryParse(_yearController.text);
    
    if (day != null && month != null && year != null) {
      try {
        final date = DateTime(year, month, day);
        setState(() => _selectedDate = date);
      } catch (e) {
        setState(() => _selectedDate = null);
      }
    } else {
      setState(() => _selectedDate = null);
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
            const ProgressBar(currentStep: 2, totalSteps: 8),
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
                  
                  // Toggle between picker and text input
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useTextInput = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_useTextInput ? AppTheme.primaryColor : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Date Picker',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: !_useTextInput ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _useTextInput = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _useTextInput ? AppTheme.primaryColor : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Type Date',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: _useTextInput ? Colors.white : Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Date input
                  if (!_useTextInput) ...[
                  // Date picker
                  GestureDetector(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().subtract(const Duration(days: 6570)),
                        firstDate: DateTime.now().subtract(const Duration(days: 36500)),
                        lastDate: DateTime.now().subtract(const Duration(days: 6570)),
                      );
                      if (date != null) {
                        setState(() {
                          _selectedDate = date;
                          _dayController.text = date.day.toString();
                          _monthController.text = date.month.toString();
                          _yearController.text = date.year.toString();
                        });
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
                  ] else ..[
                    // Text input fields
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _dayController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                            onChanged: (_) => _updateDateFromText(),
                            decoration: InputDecoration(
                              labelText: 'Day',
                              hintText: 'DD',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _monthController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
                            onChanged: (_) => _updateDateFromText(),
                            decoration: InputDecoration(
                              labelText: 'Month',
                              hintText: 'MM',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _yearController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
                            onChanged: (_) => _updateDateFromText(),
                            decoration: InputDecoration(
                              labelText: 'Year',
                              hintText: 'YYYY',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  
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
                                    'You must be at least 18 years old to use Gather',
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
              bottom: MediaQuery.of(context).viewInsets.bottom + MediaQuery.of(context).size.height * 0.025,
              left: MediaQuery.of(context).size.width * 0.08,
              right: MediaQuery.of(context).size.width * 0.08,
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
            ),
          ],
        ),
      ),
    );
  }
}