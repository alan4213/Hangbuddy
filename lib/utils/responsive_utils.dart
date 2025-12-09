import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375; // Base width (iPhone 6/7/8)
    return (baseSize * scaleFactor).clamp(baseSize * 0.8, baseSize * 1.2);
  }
  
  static double getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = screenWidth / 375;
    return baseSize * scaleFactor;
  }
  
  static EdgeInsets getResponsivePadding(BuildContext context, {
    double horizontal = 16.0,
    double vertical = 16.0,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final scaleFactor = (screenWidth / 375).clamp(0.8, 1.2);
    return EdgeInsets.symmetric(
      horizontal: horizontal * scaleFactor,
      vertical: vertical * scaleFactor,
    );
  }
  
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }
  
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 600;
  }
  
  // New overflow-safe methods
  static double safeWidth(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.width * percentage).clamp(50.0, 400.0);
  }
  
  static double safeHeight(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.height * percentage).clamp(20.0, 200.0);
  }
  
  static double safeFontSize(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.width * percentage).clamp(10.0, 28.0);
  }
  
  static double safeIconSize(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.width * percentage).clamp(16.0, 32.0);
  }
  
  static EdgeInsets safePadding(BuildContext context, double percentage) {
    final value = (MediaQuery.of(context).size.width * percentage).clamp(8.0, 24.0);
    return EdgeInsets.all(value);
  }
  
  static Widget safeText(String text, {
    required BuildContext context,
    double fontSizePercentage = 0.04,
    FontWeight? fontWeight,
    Color? color,
    int? maxLines,
    TextOverflow? overflow = TextOverflow.ellipsis,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: safeFontSize(context, fontSizePercentage),
        fontWeight: fontWeight,
        color: color,
      ),
      maxLines: maxLines,
      overflow: overflow,
    );
  }
  
  static Widget flexibleRow({
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.center,
  }) {
    return Row(
      mainAxisAlignment: mainAxisAlignment,
      crossAxisAlignment: crossAxisAlignment,
      children: children.map((child) {
        if (child is Text) {
          return Flexible(child: child);
        }
        return child;
      }).toList(),
    );
  }
}