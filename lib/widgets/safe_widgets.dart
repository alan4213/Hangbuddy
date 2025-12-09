import 'package:flutter/material.dart';

class SafeWidgets {
  // Safe text that prevents overflow
  static Widget text(
    String text, {
    required BuildContext context,
    double fontSizePercentage = 0.04,
    FontWeight? fontWeight,
    Color? color,
    int? maxLines,
    TextOverflow overflow = TextOverflow.ellipsis,
    TextAlign? textAlign,
  }) {
    return Text(
      text,
      style: TextStyle(
        fontSize: (MediaQuery.of(context).size.width * fontSizePercentage).clamp(10.0, 28.0),
        fontWeight: fontWeight,
        color: color,
      ),
      maxLines: maxLines,
      overflow: overflow,
      textAlign: textAlign,
    );
  }
  
  // Safe row that wraps text widgets in Flexible
  static Widget row({
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
  
  // Safe sized box with clamped dimensions
  static Widget sizedBox({
    required BuildContext context,
    double? widthPercentage,
    double? heightPercentage,
    Widget? child,
  }) {
    return SizedBox(
      width: widthPercentage != null 
          ? (MediaQuery.of(context).size.width * widthPercentage).clamp(4.0, 200.0)
          : null,
      height: heightPercentage != null 
          ? (MediaQuery.of(context).size.height * heightPercentage).clamp(4.0, 100.0)
          : null,
      child: child,
    );
  }
  
  // Safe padding with clamped values
  static EdgeInsets padding(BuildContext context, double percentage) {
    final value = (MediaQuery.of(context).size.width * percentage).clamp(4.0, 24.0);
    return EdgeInsets.all(value);
  }
  
  // Safe icon with clamped size
  static Widget icon(
    IconData icon, {
    required BuildContext context,
    double sizePercentage = 0.06,
    Color? color,
  }) {
    return Icon(
      icon,
      size: (MediaQuery.of(context).size.width * sizePercentage).clamp(16.0, 32.0),
      color: color,
    );
  }
  
  // Safe container with responsive dimensions
  static Widget container({
    required BuildContext context,
    Widget? child,
    double? widthPercentage,
    double? heightPercentage,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
  }) {
    return Container(
      width: widthPercentage != null 
          ? (MediaQuery.of(context).size.width * widthPercentage).clamp(50.0, 400.0)
          : null,
      height: heightPercentage != null 
          ? (MediaQuery.of(context).size.height * heightPercentage).clamp(20.0, 200.0)
          : null,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}