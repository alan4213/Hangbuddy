import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/loading_widget.dart';
import '../models/signup_data.dart';
import 'ethnicity_screen.dart';
import '../widgets/progress_bar.dart';

class HeightScreen extends StatefulWidget {
  final SignupData? signupData;
  final String? initialHeight;
  final bool isEditMode;
  
  const HeightScreen({
    super.key, 
    this.signupData,
    this.initialHeight,
    this.isEditMode = false,
  });

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  bool _isLoading = false;
  bool _isCm = true;
  
  FixedExtentScrollController? _cmController;
  FixedExtentScrollController? _ftController;
  
  final List<int> _cmValues = List.generate(81, (index) => 140 + index); // 140 to 220
  final List<String> _ftValues = [
    for (int ft = 4; ft <= 7; ft++)
      for (int inch = 0; inch < 12; inch++)
        if (!(ft == 7 && inch > 0)) '$ft\'$inch"'
  ];
  
  int _selectedCmIndex = 35; // Default 175 cm
  int _selectedFtIndex = 17; // Default 5'5"

  @override
  void initState() {
    super.initState();
    String? initial = widget.isEditMode ? widget.initialHeight : widget.signupData?.height;
    if (initial != null) {
      if (initial.contains('\'')) {
        _isCm = false;
        _selectedFtIndex = _ftValues.indexOf(initial);
        if (_selectedFtIndex == -1) _selectedFtIndex = 17;
      } else {
        _isCm = true;
        String numStr = initial.replaceAll(RegExp(r'[^0-9]'), '');
        if (numStr.isNotEmpty) {
          int val = int.parse(numStr);
          _selectedCmIndex = _cmValues.indexOf(val);
          if (_selectedCmIndex == -1) _selectedCmIndex = 35;
        }
      }
    }
    
    _cmController = FixedExtentScrollController(initialItem: _selectedCmIndex);
    _ftController = FixedExtentScrollController(initialItem: _selectedFtIndex);
  }

  @override
  void dispose() {
    _cmController?.dispose();
    _ftController?.dispose();
    super.dispose();
  }

  Widget _buildToggle() {
    return Align(
      alignment: Alignment.center,
      child: Container(
        width: 180,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (!_isCm) setState(() => _isCm = true);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _isCm ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: _isCm ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'CM',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _isCm ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  if (_isCm) setState(() => _isCm = false);
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: !_isCm ? AppTheme.primaryColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: !_isCm ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      )
                    ] : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    'FT',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: !_isCm ? Colors.white : const Color(0xFF64748B),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRuler() {
    _cmController ??= FixedExtentScrollController(initialItem: _selectedCmIndex);
    _ftController ??= FixedExtentScrollController(initialItem: _selectedFtIndex);

    return SizedBox(
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Selection overlay
          Container(
            height: 56,
            margin: const EdgeInsets.symmetric(horizontal: 48),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withOpacity(0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.08)),
            ),
          ),
          // Selection dot
          Positioned(
            right: 72,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.4),
                shape: BoxShape.circle,
              ),
            ),
          ),
          
          // Wheel Scroll View
          ListWheelScrollView.useDelegate(
            controller: _isCm ? _cmController : _ftController,
            itemExtent: 56,
            physics: const FixedExtentScrollPhysics(),
            perspective: 0.005,
            diameterRatio: 2.5,
            overAndUnderCenterOpacity: 0.5,
            onSelectedItemChanged: (index) {
              setState(() {
                if (_isCm) {
                  _selectedCmIndex = index;
                } else {
                  _selectedFtIndex = index;
                }
              });
            },
            childDelegate: ListWheelChildBuilderDelegate(
              builder: (context, index) {
                final isSelected = _isCm ? index == _selectedCmIndex : index == _selectedFtIndex;
                final value = _isCm ? _cmValues[index].toString() : _ftValues[index];
                final isMajorTick = _isCm ? _cmValues[index] % 10 == 0 : value.endsWith('\'0"');

                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(width: 80),
                    // Tick mark
                    Container(
                      width: isMajorTick ? 32 : 16,
                      height: 2,
                      color: isMajorTick 
                        ? AppTheme.primaryColor.withOpacity(0.5) 
                        : const Color(0xFFE2E8F0),
                    ),
                    const SizedBox(width: 32),
                    // Text
                    SizedBox(
                      width: 80,
                      child: Text(
                        value,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: isSelected ? 28 : 24,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected 
                            ? AppTheme.primaryColor 
                            : const Color(0xFFCBD5E1),
                        ),
                      ),
                    ),
                    const Spacer(),
                  ],
                );
              },
              childCount: _isCm ? _cmValues.length : _ftValues.length,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: const Color(0xFFFAFAFA),
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.isEditMode ? 'Edit Height' : 'Create Profile',
          style: GoogleFonts.poppins(
            color: const Color(0xFF0F172A),
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor, size: 20),
              padding: EdgeInsets.zero,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        actions: [
          if (!widget.isEditMode)
            TextButton(
              onPressed: () {
                widget.signupData!.height = null; // null or empty, depending on API.
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EthnicityScreen(signupData: widget.signupData!),
                  ),
                );
              },
              child: Text(
                'Skip',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!widget.isEditMode)
                  const ProgressBar(currentStep: 4, totalSteps: 8),
                
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),
                        Text(
                          'What\'s your height?',
                          style: GoogleFonts.poppins(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Optional information to help friends recognize you when meeting up.',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            color: const Color(0xFF64748B),
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                        
                        const SizedBox(height: 32),
                        
                        _buildToggle(),
                        
                        const SizedBox(height: 24),
                        
                        _buildRuler(),
                        
                        SizedBox(height: MediaQuery.of(context).size.height * 0.125),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Bottom Bar
            Positioned(
              bottom: MediaQuery.of(context).viewInsets.bottom > 0 
                  ? MediaQuery.of(context).viewInsets.bottom + 16
                  : 32,
              left: 24,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Color(0xFF64748B)),
                      onPressed: () => Navigator.pop(context),
                    ),
                    if (!widget.isEditMode)
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        'Edit Height',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    GestureDetector(
                      onTap: () async {
                        String selected = _isCm 
                            ? '${_cmValues[_selectedCmIndex]} cm'
                            : _ftValues[_selectedFtIndex];
                            
                        if (widget.isEditMode) {
                          Navigator.pop(context, selected);
                        } else {
                          setState(() => _isLoading = true);
                          widget.signupData!.height = selected;
                          await Future.delayed(const Duration(milliseconds: 300));
                          if (mounted) {
                            setState(() => _isLoading = false);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => EthnicityScreen(signupData: widget.signupData!),
                              ),
                            );
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryColor,
                        ),
                        child: _isLoading 
                            ? const SizedBox(
                                width: 20, 
                                height: 20, 
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              )
                            : const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ),
                    ),
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