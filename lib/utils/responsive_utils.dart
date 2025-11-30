import 'package:flutter/material.dart';

class ResponsiveUtils {
  static double getScreenWidth(BuildContext context) {
    return MediaQuery.of(context).size.width;
  }

  static double getScreenHeight(BuildContext context) {
    return MediaQuery.of(context).size.height;
  }

  // Font sizes based on screen width
  static double getFontSize(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  // Spacing based on screen dimensions
  static double getHorizontalSpacing(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  static double getVerticalSpacing(BuildContext context, double percentage) {
    return getScreenHeight(context) * percentage;
  }

  // Icon sizes
  static double getIconSize(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  // Container dimensions
  static double getContainerWidth(BuildContext context, double percentage) {
    return getScreenWidth(context) * percentage;
  }

  static double getContainerHeight(BuildContext context, double percentage) {
    return getScreenHeight(context) * percentage;
  }

  // Check if device is tablet
  static bool isTablet(BuildContext context) {
    return getScreenWidth(context) >= 600;
  }

  // Check if device is small phone
  static bool isSmallPhone(BuildContext context) {
    return getScreenWidth(context) < 360;
  }

  // Adaptive font sizes
  static double getAdaptiveFontSize(BuildContext context, {
    required double small,
    required double medium,
    required double large,
  }) {
    final width = getScreenWidth(context);
    if (width < 360) return small;
    if (width < 600) return medium;
    return large;
  }
}