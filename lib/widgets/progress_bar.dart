import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ProgressBar extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const ProgressBar({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: LinearProgressIndicator(
          value: currentStep / totalSteps,
          backgroundColor: const Color(0xFFE2E8F0),
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          minHeight: 4,
        ),
      ),
    );
  }
}