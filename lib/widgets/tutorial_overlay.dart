import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_theme.dart';

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;
  final Widget child;
  final String screenName;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
    required this.child,
    required this.screenName,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;
  bool _showTutorial = true;
  bool _tutorialChecked = false;

  @override
  void initState() {
    super.initState();
    _checkTutorialStatus();
  }

  void _checkTutorialStatus() async {
    if (_tutorialChecked) return;
    _tutorialChecked = true;
    
    final isCompleted = await TutorialService.isTutorialCompleted(widget.screenName);
    if (isCompleted && mounted) {
      setState(() {
        _showTutorial = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_showTutorial) {
      return widget.child;
    }

    return Stack(
      children: [
        widget.child,
        if (_currentStep < widget.steps.length)
          _buildTutorialOverlay(widget.steps[_currentStep]),
      ],
    );
  }

  Widget _buildTutorialOverlay(TutorialStep step) {
    return Positioned.fill(
      child: Material(
        color: Colors.black.withOpacity(0.7),
        child: Stack(
          children: [
            // Highlight area
            if (step.targetKey != null)
              _buildHighlight(step),
            
            // Icon highlight
            if (step.showIconHighlight && step.customIcon != null)
              _buildIconHighlight(step),
            
            // Tutorial bubble
            _buildTutorialBubble(step),
          ],
        ),
      ),
    );
  }

  Widget _buildIconHighlight(TutorialStep step) {
    return Stack(
      children: [
        // Left swipe icon
        Positioned(
          bottom: 100,
          left: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.swipe_left,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
        // Right swipe icon
        Positioned(
          bottom: 100,
          right: 30,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: const Icon(
              Icons.swipe_right,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlight(TutorialStep step) {
    return CustomPaint(
      painter: HighlightPainter(
        targetKey: step.targetKey!,
        highlightRadius: step.highlightRadius,
        highlightAsRectangle: step.highlightAsRectangle,
      ),
      child: Container(),
    );
  }

  Widget _buildTutorialBubble(TutorialStep step) {
    return Positioned(
      top: step.bubblePosition?.dy ?? MediaQuery.of(context).size.height * 0.3,
      left: 20,
      right: 20,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (step.customIcon != null) ...[
                  Icon(
                    step.customIcon!,
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    step.title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              step.description,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_currentStep + 1} of ${widget.steps.length}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
                Row(
                  children: [
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: _previousStep,
                        child: Text('Back'),
                      ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _nextStep,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                      ),
                      child: Text(
                        _currentStep == widget.steps.length - 1 ? 'Got it!' : 'Next',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _nextStep() {
    if (_currentStep < widget.steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      setState(() {
        _showTutorial = false;
      });
      TutorialService.markTutorialCompleted(widget.screenName);
      widget.onComplete();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
}

class TutorialStep {
  final String title;
  final String description;
  final GlobalKey? targetKey;
  final Offset? bubblePosition;
  final double highlightRadius;
  final bool highlightAsRectangle;
  final IconData? customIcon;
  final bool showIconHighlight;

  TutorialStep({
    required this.title,
    required this.description,
    this.targetKey,
    this.bubblePosition,
    this.highlightRadius = 60,
    this.highlightAsRectangle = false,
    this.customIcon,
    this.showIconHighlight = false,
  });
}

class HighlightPainter extends CustomPainter {
  final GlobalKey targetKey;
  final double highlightRadius;
  final bool highlightAsRectangle;

  HighlightPainter({
    required this.targetKey,
    required this.highlightRadius,
    this.highlightAsRectangle = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final RenderBox? renderBox = targetKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.attached) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final targetSize = renderBox.size;

    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    if (highlightAsRectangle) {
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - 8,
          position.dy - 8,
          targetSize.width + 16,
          targetSize.height + 16,
        ),
        const Radius.circular(16),
      );
      canvas.drawRRect(rect, paint);
      canvas.drawRRect(rect, borderPaint);
    } else {
      final center = Offset(
        position.dx + targetSize.width / 2,
        position.dy + targetSize.height / 2,
      );
      canvas.drawCircle(center, highlightRadius, paint);
      canvas.drawCircle(center, highlightRadius, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Tutorial service to manage tutorial state
class TutorialService {
  static Future<bool> isTutorialCompleted(String screenName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return false;
      
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      
      if (doc.exists) {
        final completedTutorials = doc.data()?['completedTutorials'] as List<dynamic>? ?? [];
        return completedTutorials.contains(screenName);
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  static Future<void> markTutorialCompleted(String screenName) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'completedTutorials': FieldValue.arrayUnion([screenName])
      });
    } catch (e) {
      print('Error saving tutorial completion: $e');
    }
  }
}