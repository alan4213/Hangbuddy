import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/hangout_service.dart';
import '../services/location_service.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../utils/responsive.dart';
import '../widgets/tutorial_overlay.dart';
import '../utils/error_handler.dart';

class CreateHangoutScreen extends StatefulWidget {
  const CreateHangoutScreen({super.key});

  @override
  State<CreateHangoutScreen> createState() => _CreateHangoutScreenState();
}

class _CreateHangoutScreenState extends State<CreateHangoutScreen> {
  final _titleController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Food & Drink';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  bool _isCreating = false;
  double _maxDistance = 100.0;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  List<String> _locationSuggestions = [];
  bool _showCategoryDropdown = false;
  Timer? _debounceTimer;
  bool _isSearchingLocation = false;
  bool _showSuggestions = false;
  
  // Tutorial keys
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _dateTimeKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();
  bool _showTutorial = false;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Drink', 'icon': Icons.restaurant, 'color': const Color(0xFFFF6B6B)},
    {'name': 'Coffee & Tea', 'icon': Icons.local_cafe, 'color': const Color(0xFF8B4513)},
    {'name': 'Movies & Cinema', 'icon': Icons.movie, 'color': const Color(0xFF6366F1)},
    {'name': 'Sports & Fitness', 'icon': Icons.sports, 'color': const Color(0xFF10B981)},
    {'name': 'Music & Concerts', 'icon': Icons.music_note, 'color': const Color(0xFFE91E63)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': const Color(0xFFF59E0B)},
    {'name': 'Travel & Adventure', 'icon': Icons.explore, 'color': const Color(0xFF06B6D4)},
    {'name': 'Party & Nightlife', 'icon': Icons.celebration, 'color': const Color(0xFF8B5CF6)},
    {'name': 'Study & Work', 'icon': Icons.school, 'color': const Color(0xFF64748B)},
    {'name': 'Gaming', 'icon': Icons.sports_esports, 'color': const Color(0xFF3B82F6)},
    {'name': 'Books & Reading', 'icon': Icons.menu_book, 'color': const Color(0xFF7C3AED)},
    {'name': 'Photography', 'icon': Icons.camera_alt, 'color': const Color(0xFF059669)},
    {'name': 'Cooking', 'icon': Icons.kitchen, 'color': const Color(0xFFDC2626)},
    {'name': 'Volunteering', 'icon': Icons.volunteer_activism, 'color': const Color(0xFF0891B2)},
  ];

  @override
  void initState() {
    super.initState();
    _checkAndShowTutorial();
  }
  
  void _checkAndShowTutorial() async {
    // Only show tutorial if not already completed
    final isCompleted = await TutorialService.isTutorialCompleted('create_hangout_screen');
    if (!isCompleted && mounted && !_showTutorial) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted && !_showTutorial) {
          setState(() {
            _showTutorial = true;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final createContent = Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      extendBodyBehindAppBar: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Create Hangout',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 24, left: 24, right: 24, bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          "What's the plan?",
                          style: GoogleFonts.poppins(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "DEFINE YOUR NEXT ADVENTURE",
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryColor.withOpacity(0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildSectionLabel('HANGOUT TITLE'),
                  _buildTitleField(),

                  const SizedBox(height: 24),

                  _buildSectionLabel('CATEGORY'),
                  _buildCategoryField(),

                  const SizedBox(height: 24),

                  _buildSectionLabel('LOCATION'),
                  _buildLocationField(),

                  const SizedBox(height: 24),

                  _buildDistanceSlider(),

                  const SizedBox(height: 24),

                  _buildSectionLabel('WHEN?'),
                  Row(
                    key: _dateTimeKey,
                    children: [
                      Expanded(
                        child: _buildDateTimeBox(
                          '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                          _selectDate,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildDateTimeBox(
                          _selectedTime.format(context),
                          _selectTime,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
          
          // Create Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFFF8FAFC),
            ),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: _createButtonKey,
                onPressed: _isCreating ? null : _createHangout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Create Hangout',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );

    if (_showTutorial) {
      return TutorialOverlay(
        screenName: 'create_hangout_screen',
        steps: [
          TutorialStep(
            title: 'Create Your Hangout',
            description: 'This is where you create hangouts for others to join. Fill in the details about what you want to do.',
            bubblePosition: const Offset(20, 150),
          ),
          TutorialStep(
            title: 'Hangout Title',
            description: 'Give your hangout a catchy title that describes what you\'re planning to do.',
            targetKey: _titleKey,
            bubblePosition: const Offset(20, 280),
            highlightAsRectangle: true,
          ),
          TutorialStep(
            title: 'Choose Category',
            description: 'Select the category that best fits your hangout activity.',
            targetKey: _categoryKey,
            bubblePosition: const Offset(20, 350),
            highlightAsRectangle: true,
          ),
          TutorialStep(
            title: 'Set Location',
            description: 'Enter where you want to meet or use GPS to set your current location.',
            targetKey: _locationKey,
            bubblePosition: const Offset(20, 450),
            highlightAsRectangle: true,
          ),
          TutorialStep(
            title: 'Choose Date & Time',
            description: 'Select when your hangout will take place. Must be at least 30 minutes from now and within 7 days.',
            targetKey: _dateTimeKey,
            bubblePosition: const Offset(20, 520),
            highlightAsRectangle: true,
          ),
        ],
        onComplete: () {
          setState(() {
            _showTutorial = false;
          });
          TutorialService.markTutorialCompleted('create_hangout');
        },
        child: createContent,
      );
    }

    return createContent;
  }

  Widget _buildSectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF475569),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildTitleField() {
    return Container(
      key: _titleKey,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _titleController,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
        decoration: InputDecoration(
          hintText: 'What are we doing?',
          hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          suffixIcon: Icon(Icons.edit_note, color: AppTheme.primaryColor.withOpacity(0.5)),
        ),
      ),
    );
  }

  Widget _buildCategoryField() {
    return Column(
      children: [
        GestureDetector(
          key: _categoryKey,
          onTap: () => setState(() => _showCategoryDropdown = !_showCategoryDropdown),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _getCategoryColor(_selectedCategory).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _getCategoryIcon(_selectedCategory),
                    color: _getCategoryColor(_selectedCategory),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedCategory,
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _showCategoryDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    color: AppTheme.primaryColor,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_showCategoryDropdown)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 250),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = _selectedCategory == category['name'];
                return ListTile(
                  onTap: () {
                    setState(() {
                      _selectedCategory = category['name'];
                      _showCategoryDropdown = false;
                    });
                  },
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: category['color'].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      category['icon'],
                      color: category['color'],
                      size: 20,
                    ),
                  ),
                  title: Text(
                    category['name'],
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? category['color'] : const Color(0xFF0F172A),
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check, color: category['color'], size: 20)
                      : null,
                  dense: true,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimeBox(String text, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _buildLocationField() {
    return Column(
      key: _locationKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _locationController,
                  maxLines: 3,
                  minLines: 1,
                  style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                  decoration: InputDecoration(
                    hintText: 'Where is it happening?',
                    hintStyle: GoogleFonts.poppins(color: const Color(0xFF94A3B8), fontSize: 16),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    suffixIcon: _isSearchingLocation 
                        ? const Padding(
                            padding: EdgeInsets.all(12.0),
                            child: SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : null,
                  ),
                  onChanged: _updateLocationSuggestions,
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _isGettingLocation ? null : _getCurrentLocation,
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isGettingLocation
                    ? const Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
        if (_showSuggestions && _locationSuggestions.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            constraints: const BoxConstraints(maxHeight: 200),
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _locationSuggestions.length,
              itemBuilder: (context, index) {
                return ListTile(
                  dense: true,
                  leading: Icon(Icons.location_on, size: 20, color: AppTheme.primaryColor),
                  title: Text(
                    _locationSuggestions[index],
                    style: GoogleFonts.poppins(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F172A)),
                  ),
                  onTap: () => _selectLocation(_locationSuggestions[index]),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VISIBILITY RANGE',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF475569),
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Audience reach',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8), // Add a little spacing
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _maxDistance >= 100.0 ? 'Anywhere' : '${_maxDistance.toInt()} km',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppTheme.primaryColor.withOpacity(0.2),
              inactiveTrackColor: const Color(0xFFF1F5F9),
              thumbColor: AppTheme.primaryColor,
              overlayColor: AppTheme.primaryColor.withOpacity(0.1),
              trackHeight: 4,
            ),
            child: Slider(
              value: _maxDistance,
              min: 1.0,
              max: 100.0,
              divisions: 99,
              onChanged: (value) => setState(() => _maxDistance = value),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('LOCAL', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
                Text('WORLDWIDE', style: GoogleFonts.poppins(fontSize: 10, fontWeight: FontWeight.w700, color: const Color(0xFF94A3B8))),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _maxDistance >= 100.0
                        ? 'Your hangout will be visible to everyone, anywhere in the world.'
                        : 'People within ${_maxDistance.toInt()} km can see your hangout.',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black87,
            ),
            dialogBackgroundColor: Colors.white,
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: AppTheme.primaryColor,
              headerForegroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            alwaysUse24HourFormat: false,
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              timePickerTheme: TimePickerThemeData(
                backgroundColor: Colors.white,
                hourMinuteShape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                dayPeriodBorderSide: BorderSide(
                  color: AppTheme.primaryColor,
                  width: 2,
                ),
                dayPeriodColor: WidgetStateColor.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? AppTheme.primaryColor
                      : Colors.transparent;
                }),
                dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                  return states.contains(WidgetState.selected)
                      ? Colors.white
                      : Colors.grey[600]!;
                }),
                hourMinuteColor: AppTheme.primaryColor.withOpacity(0.1),
                hourMinuteTextColor: AppTheme.primaryColor,
                dialHandColor: AppTheme.primaryColor,
                dialBackgroundColor: Colors.grey[100],
                dialTextColor: Colors.black87,
                entryModeIconColor: AppTheme.primaryColor,
              ),
            ),
            child: child!,
          ),
        );
      },
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _createHangout() async {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      // Check if user already has an active hangout
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final activeHangouts = await FirebaseFirestore.instance
            .collection('hangout_requests')
            .where('creatorId', isEqualTo: currentUser.uid)
            .where('status', isEqualTo: 'active')
            .get();
        
        // Filter for future hangouts on client side
        final futureHangouts = activeHangouts.docs.where((doc) {
          final data = doc.data();
          final dateTime = (data['dateTime'] as Timestamp).toDate();
          return dateTime.isAfter(DateTime.now());
        }).toList();
        
        if (futureHangouts.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You already have an active hangout. Please wait for it to complete or cancel it first.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 4),
            ),
          );
          setState(() => _isCreating = false);
          return;
        }
      }

      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final now = DateTime.now();
      final minTime = now.add(const Duration(minutes: 30));
      final maxTime = now.add(const Duration(days: 7));

      if (dateTime.isBefore(minTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hangout must be at least 30 minutes from now'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isCreating = false);
        return;
      }

      if (dateTime.isAfter(maxTime)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hangout cannot be more than 7 days from now'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isCreating = false);
        return;
      }

      await HangoutService.createHangoutRequest(
        title: _titleController.text,
        category: _selectedCategory,
        dateTime: dateTime,
        location: _locationController.text,
        latitude: _latitude,
        longitude: _longitude,
        maxDistance: _maxDistance,
      );

      // Show success animation
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SuccessDialog(),
      );

      // Auto close after 2 seconds and navigate back
      Timer(const Duration(seconds: 2), () {
        Navigator.of(context).pop(); // Close dialog
        Navigator.pop(context); // Go back to previous screen
      });
    } catch (e) {
      print('ERROR creating hangout: $e');
      print('Error type: ${e.runtimeType}');
      ErrorHandler.showErrorSnackBar(
        context,
        e,
        onRetry: _createHangout,
        retryLabel: 'Try Again',
      );
    } finally {
      setState(() => _isCreating = false);
    }
  }

  void _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    
    try {
      final position = await LocationService.getCurrentPosition();
      if (position != null) {
        final address = await LocationService.getAddressFromCoordinates(
          position.latitude,
          position.longitude,
        );
        
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          if (address != null) {
            _locationController.text = _cleanAddress(address);
          }
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to get location. Please check permissions.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ErrorHandler.showErrorSnackBar(
        context,
        e,
        onRetry: _getCurrentLocation,
        retryLabel: 'Retry Location',
      );
    } finally {
      setState(() => _isGettingLocation = false);
    }
  }

  void _updateLocationSuggestions(String query) async {
    _debounceTimer?.cancel();
    
    if (query.isEmpty) {
      setState(() {
        _showSuggestions = false;
        _locationSuggestions = [];
        _isSearchingLocation = false;
      });
      return;
    }
    
    setState(() {
      _isSearchingLocation = true;
    });
    
    _debounceTimer = Timer(const Duration(milliseconds: 400), () async {
      try {
        final suggestions = await LocationService.getLocationSuggestions(query);
        if (mounted && _locationController.text == query) {
          setState(() {
            _locationSuggestions = suggestions;
            _showSuggestions = suggestions.isNotEmpty;
            _isSearchingLocation = false;
          });
        }
      } catch (e) {
        print('Error getting location suggestions: $e');
        setState(() {
          _isSearchingLocation = false;
        });
      }
    });
  }
  
  void _selectLocation(String location) async {
    _locationController.text = location;
    setState(() {
      _showSuggestions = false;
    });
    
    // Get coordinates for the selected location
    final coords = await LocationService.getCoordinatesFromAddress(location);
    if (coords != null) {
      setState(() {
        _latitude = coords['latitude'];
        _longitude = coords['longitude'];
      });
    }
    
    // Reset session token for next search
    LocationService.resetSessionToken();
  }

  String _cleanAddress(String address) {
    final parts = address.split(', ');
    List<String> cleanParts = [];
    
    for (String part in parts) {
      String cleanPart = part.trim();
      // Skip Plus Codes
      bool isPlusCode = cleanPart.contains('+') && 
          RegExp(r'^[A-Z0-9+]+$').hasMatch(cleanPart.toUpperCase());
      
      if (!isPlusCode && cleanPart.isNotEmpty) {
        cleanParts.add(cleanPart);
      }
    }
    
    if (cleanParts.isEmpty) {
      return address; // Fallback to original if nothing clean found
    }
    
    // For hangout creation, show specific location (first 2-3 parts)
    // This gives street/landmark + area + city
    if (cleanParts.length >= 3) {
      return '${cleanParts[0]}, ${cleanParts[1]}, ${cleanParts[2]}';
    } else if (cleanParts.length >= 2) {
      return '${cleanParts[0]}, ${cleanParts[1]}';
    } else {
      return cleanParts[0];
    }
  }

  IconData _getCategoryIcon(String categoryName) {
    final category = _categories.firstWhere(
      (cat) => cat['name'] == categoryName,
      orElse: () => _categories.last,
    );
    return category['icon'];
  }

  Color _getCategoryColor(String categoryName) {
    final category = _categories.firstWhere(
      (cat) => cat['name'] == categoryName,
      orElse: () => _categories.last,
    );
    return category['color'];
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}

class SuccessDialog extends StatefulWidget {
  const SuccessDialog({super.key});

  @override
  State<SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<SuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Hangout Created!',
                    style: GoogleFonts.poppins(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your hangout has been created successfully',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}