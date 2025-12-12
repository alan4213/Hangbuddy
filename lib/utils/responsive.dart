import 'package:flutter/material.dart';

class Responsive {
  static double width(BuildContext context) => MediaQuery.of(context).size.width;
  static double height(BuildContext context) => MediaQuery.of(context).size.height;
  
  // Font sizes
  static double fontSize(BuildContext context, double percentage) => width(context) * percentage;
  
  // Padding/Margins
  static double padding(BuildContext context, double percentage) => width(context) * percentage;
  
  // Common responsive values
  static double get titleFontSize => 0.07; // 7% of screen width
  static double get headingFontSize => 0.05; // 5% of screen width
  static double get bodyFontSize => 0.04; // 4% of screen width
  static double get smallFontSize => 0.035; // 3.5% of screen width
  
  static double get largePadding => 0.08; // 8% of screen width
  static double get mediumPadding => 0.05; // 5% of screen width
  static double get smallPadding => 0.03; // 3% of screen width
}