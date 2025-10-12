import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreateHangoutScreen extends StatefulWidget {
  const CreateHangoutScreen({super.key});

  @override
  State<CreateHangoutScreen> createState() => _CreateHangoutScreenState();
}

class _CreateHangoutScreenState extends State<CreateHangoutScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  String _selectedCategory = 'Food & Drink';
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _maxParticipants = 5;

  final List<String> _categories = [
    'Food & Drink',
    'Sports',
    'Entertainment',
    'Study',
    'Outdoor',
    'Gaming',
    'Arts & Culture',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Create Hangout',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            _buildTextField(
              controller: _titleController,
              label: 'Hangout Title',
              hint: 'What are you planning?',
            ),

            const SizedBox(height: 20),

            // Description
            _buildTextField(
              controller: _descriptionController,
              label: 'Description',
              hint: 'Tell people what to expect...',
              maxLines: 3,
            ),

            const SizedBox(height: 20),

            // Category
            _buildSectionTitle('Category'),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  items: _categories.map((category) {
                    return DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedCategory = value!);
                  },
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Location
            _buildTextField(
              controller: _locationController,
              label: 'Location',
              hint: 'Where will this happen?',
              prefixIcon: Icons.location_on,
            ),

            const SizedBox(height: 20),

            // Date & Time
            Row(
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
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
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
                              Text(_selectedTime.format(context)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Max Participants
            _buildSectionTitle('Max Participants'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Number of people'),
                  Row(
                    children: [
                      IconButton(
                        onPressed: _maxParticipants > 2
                            ? () => setState(() => _maxParticipants--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text(
                        '$_maxParticipants',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: _maxParticipants < 20
                            ? () => setState(() => _maxParticipants++)
                            : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _createHangout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4C5E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Create Hangout',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(label),
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
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
              borderSide: const BorderSide(color: Color(0xFFEF4C5E)),
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
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _selectTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _createHangout() {
    if (_titleController.text.isEmpty || _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all required fields')),
      );
      return;
    }

    // Here you would typically save the hangout to your backend
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hangout created successfully!')),
    );
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }
}