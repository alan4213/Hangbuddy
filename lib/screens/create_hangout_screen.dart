import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
  double _maxDistance = 20.0;
  double? _latitude;
  double? _longitude;
  bool _isGettingLocation = false;
  List<String> _locationSuggestions = [];
  bool _showCategoryDropdown = false;
  bool _showSuggestions = false;
  
  // Tutorial keys
  final GlobalKey _titleKey = GlobalKey();
  final GlobalKey _categoryKey = GlobalKey();
  final GlobalKey _locationKey = GlobalKey();
  final GlobalKey _dateTimeKey = GlobalKey();
  final GlobalKey _createButtonKey = GlobalKey();
  bool _showTutorial = false;


  final List<Map<String, dynamic>> _categories = [
    {'name': 'Food & Drink', 'icon': Icons.restaurant, 'color': Color(0xFFFF6B6B)},
    {'name': 'Coffee & Tea', 'icon': Icons.local_cafe, 'color': Color(0xFF8B4513)},
    {'name': 'Movies & Cinema', 'icon': Icons.movie, 'color': Color(0xFF6366F1)},
    {'name': 'Sports & Fitness', 'icon': Icons.sports, 'color': Color(0xFF10B981)},
    {'name': 'Music & Concerts', 'icon': Icons.music_note, 'color': Color(0xFFE91E63)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Color(0xFFF59E0B)},
    {'name': 'Travel & Adventure', 'icon': Icons.explore, 'color': Color(0xFF06B6D4)},
    {'name': 'Party & Nightlife', 'icon': Icons.celebration, 'color': Color(0xFF8B5CF6)},
    {'name': 'Study & Work', 'icon': Icons.school, 'color': Color(0xFF64748B)},
    {'name': 'Outdoor & Nature', 'icon': Icons.nature, 'color': Color(0xFF22C55E)},
    {'name': 'Gaming', 'icon': Icons.sports_esports, 'color': Color(0xFF3B82F6)},
    {'name': 'Arts & Culture', 'icon': Icons.palette, 'color': Color(0xFFEC4899)},
    {'name': 'Books & Reading', 'icon': Icons.menu_book, 'color': Color(0xFF7C3AED)},
    {'name': 'Photography', 'icon': Icons.camera_alt, 'color': Color(0xFF059669)},
    {'name': 'Cooking', 'icon': Icons.kitchen, 'color': Color(0xFFDC2626)},
    {'name': 'Dancing', 'icon': Icons.music_video, 'color': Color(0xFFDB2777)},
    {'name': 'Volunteering', 'icon': Icons.volunteer_activism, 'color': Color(0xFF0891B2)},
    {'name': 'Networking', 'icon': Icons.people, 'color': Color(0xFF7C2D12)},
    {'name': 'Other', 'icon': Icons.more_horiz, 'color': Color(0xFF6B7280)},
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.close, color: AppTheme.primaryColor),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    Center(
                      child: Text(
                        'Create Hangout',
                        style: TextStyle(
                          fontSize: Responsive.fontSize(context, Responsive.headingFontSize),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Responsive.padding(context, Responsive.mediumPadding),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    // Title
            _buildTextField(
              key: _titleKey,
              controller: _titleController,
              label: 'Hangout Title',
              hint: 'What are you planning?',
            ),

                    const SizedBox(height: 24),

                    // Category
            _buildSectionTitle('Category'),
            GestureDetector(
              key: _categoryKey,
              onTap: () => setState(() => _showCategoryDropdown = !_showCategoryDropdown),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _getCategoryColor(_selectedCategory).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _getCategoryIcon(_selectedCategory),
                        color: _getCategoryColor(_selectedCategory),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedCategory,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Icon(
                      _showCategoryDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                      color: Colors.grey[600],
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
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                constraints: const BoxConstraints(maxHeight: 250),
                child: ListView.builder(
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
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? category['color'] : Colors.black87,
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

                    const SizedBox(height: 24),

                    // Location
            _buildLocationField(),

                    const SizedBox(height: 24),

                    // Distance Range
            _buildDistanceSlider(),

                    const SizedBox(height: 24),

                    // Date & Time
            Row(
              key: _dateTimeKey,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Date'),
                      GestureDetector(
                        onTap: _selectDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.grey),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Time'),
                      GestureDetector(
                        onTap: _selectTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.grey),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  _selectedTime.format(context),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

                    const SizedBox(height: 32),

            // Create Button
            LoadingButton(
              key: _createButtonKey,
              isLoading: _isCreating,
              text: 'Create Hangout',
              onPressed: _createHangout,
            ),
                ],
              ),
            ),
          ],
          ),
        ),
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
          TutorialStep(
            title: 'Create & Share',
            description: 'Tap here to create your hangout and make it visible to people nearby.',
            targetKey: _createButtonKey,
            bubblePosition: const Offset(20, 600),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: TextStyle(
          fontSize: Responsive.fontSize(context, Responsive.bodyFontSize),
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      key: key,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey, 
              fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
            ),
            prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
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
                dayPeriodColor: AppTheme.primaryColor.withOpacity(0.1),
                dayPeriodTextColor: AppTheme.primaryColor,
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
      return;
    }

    if (dateTime.isAfter(maxTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hangout cannot be more than 7 days from now'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
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

  Widget _buildLocationField() {
    return Column(
      key: _locationKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Location'),
        Row(
          children: [
            Expanded(
              child: Column(
                children: [
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'Enter location or use GPS',
                      prefixIcon: const Icon(Icons.location_on, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: AppTheme.primaryColor),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    onChanged: (value) {
                      _updateLocationSuggestions(value);
                    },
                  ),
                  if (_showSuggestions && _locationSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, size: 16),
                            title: Text(
                              _locationSuggestions[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectLocation(_locationSuggestions[index]),
                          );
                        },
                      ),
                    ),
                  if (_showSuggestions && _locationSuggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: const BoxConstraints(maxHeight: 200),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _locationSuggestions.length,
                        itemBuilder: (context, index) {
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on, size: 16),
                            title: Text(
                              _locationSuggestions[index],
                              style: const TextStyle(fontSize: 14),
                            ),
                            onTap: () => _selectLocation(_locationSuggestions[index]),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                icon: _isGettingLocation
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.my_location, color: Colors.white),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDistanceSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Visibility Range'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Who can see this hangout?',
                      style: TextStyle(
                        fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    'Within ${_maxDistance.toInt()} km',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxDistance,
                min: 1.0,
                max: 30.0,
                divisions: 29,
                activeColor: AppTheme.primaryColor,
                onChanged: (value) {
                  setState(() => _maxDistance = value);
                },
              ),
              Text(
                'People within this range can see your hangout',
                style: TextStyle(
                  fontSize: Responsive.fontSize(context, Responsive.smallFontSize),
                  color: Colors.grey,
                  fontWeight: FontWeight.w400,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
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
    if (query.length < 2) {
      setState(() {
        _showSuggestions = false;
        _locationSuggestions = [];
      });
      return;
    }
    
    try {
      final suggestions = await LocationService.getLocationSuggestions(query);
      setState(() {
        _locationSuggestions = suggestions;
        _showSuggestions = suggestions.isNotEmpty;
      });
    } catch (e) {
      print('Error getting location suggestions: $e');
      setState(() {
        _locationSuggestions = [];
        _showSuggestions = false;
      });
    }
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
                  const Text(
                    'Hangout Created!',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your hangout has been created successfully',
                    textAlign: TextAlign.center,
                    style: TextStyle(
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