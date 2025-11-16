import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'interests_screen.dart';

class PersonalInfoScreen extends StatefulWidget {
  final SignupData signupData;
  const PersonalInfoScreen({super.key, required this.signupData});

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  String? _selectedGender;
  String? _selectedOccupation;
  String? _selectedEducation;
  String? _selectedHeight;
  String? _selectedRace;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedGender = widget.signupData.gender;
    _selectedOccupation = widget.signupData.occupation;
    _selectedEducation = widget.signupData.education;
    _selectedHeight = widget.signupData.height;
    _selectedRace = widget.signupData.race;
  }

  final List<String> _genders = ['Male', 'Female', 'Other'];
  final List<String> _occupations = [
    'Software Engineer', 'Product Manager', 'Designer', 'Data Scientist', 'Marketing Manager',
    'Sales Representative', 'Consultant', 'Teacher', 'Doctor', 'Nurse', 'Lawyer', 'Accountant',
    'Financial Analyst', 'Project Manager', 'Business Analyst', 'Engineer', 'Architect',
    'Chef', 'Artist', 'Writer', 'Photographer', 'Real Estate Agent', 'Entrepreneur',
    'Student', 'Researcher', 'Therapist', 'Social Worker', 'HR Manager', 'Operations Manager',
    'Customer Success', 'UX/UI Designer', 'Content Creator', 'Freelancer', 'Other'
  ];
  final List<String> _educations = ['High School', 'Bachelor\'s Degree', 'Master\'s Degree', 'PhD', 'Trade School', 'Other'];
  final List<String> _heights = ['4\'0"', '4\'1"', '4\'2"', '4\'3"', '4\'4"', '4\'5"', '4\'6"', '4\'7"', '4\'8"', '4\'9"', '4\'10"', '4\'11"', '5\'0"', '5\'1"', '5\'2"', '5\'3"', '5\'4"', '5\'5"', '5\'6"', '5\'7"', '5\'8"', '5\'9"', '5\'10"', '5\'11"', '6\'0"', '6\'1"', '6\'2"', '6\'3"', '6\'4"', '6\'5"', '6\'6"', '6\'7"', '6\'8"'];
  final List<String> _races = ['Asian', 'Black', 'Hispanic/Latino', 'White', 'Native American', 'Pacific Islander', 'Mixed', 'Other', 'Prefer not to say'];

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
                'Personal Info',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Help us know you better',
                style: TextStyle(
                  fontSize: 16,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 48),
              
              // Gender dropdown
              _buildDropdown('Gender', _selectedGender, _genders, (value) => setState(() => _selectedGender = value)),
              
              const SizedBox(height: 24),
              
              // Occupation dropdown
              _buildDropdown('Occupation', _selectedOccupation, _occupations, (value) => setState(() => _selectedOccupation = value)),
              
              const SizedBox(height: 24),
              
              // Education dropdown
              _buildDropdown('Education', _selectedEducation, _educations, (value) => setState(() => _selectedEducation = value)),
              
              const SizedBox(height: 24),
              
              // Height dropdown
              _buildDropdown('Height', _selectedHeight, _heights, (value) => setState(() => _selectedHeight = value)),
              
              const SizedBox(height: 24),
              
              // Race dropdown
              _buildDropdown('Race', _selectedRace, _races, (value) => setState(() => _selectedRace = value)),
              
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 32),
              
              LoadingButton(
                isLoading: _isLoading,
                text: 'Continue',
                onPressed: () async {
                  if (_selectedGender == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your gender')),
                    );
                    return;
                  }
                  if (_selectedOccupation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your occupation')),
                    );
                    return;
                  }
                  if (_selectedEducation == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your education')),
                    );
                    return;
                  }
                  if (_selectedHeight == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your height')),
                    );
                    return;
                  }
                  if (_selectedRace == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select your race')),
                    );
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  
                  widget.signupData.gender = _selectedGender;
                  widget.signupData.occupation = _selectedOccupation;
                  widget.signupData.education = _selectedEducation;
                  widget.signupData.height = _selectedHeight;
                  widget.signupData.race = _selectedRace;
                  
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    setState(() => _isLoading = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => InterestsScreen(signupData: widget.signupData),
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

  Widget _buildDropdown(String label, String? value, List<String> items, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width > 600 ? 18 : 16,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(16),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              hint: Text('Select $label'),
              isExpanded: true,
              items: items.map((item) => DropdownMenuItem(
                value: item,
                child: Text(
                  item,
                  style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width > 600 ? 16 : 14,
                  ),
                ),
              )).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}