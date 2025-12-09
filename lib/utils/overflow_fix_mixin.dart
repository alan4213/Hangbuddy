import 'package:flutter/material.dart';

mixin OverflowFixMixin {
  // Safe responsive sizing methods
  double safeWidth(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.width * percentage).clamp(50.0, 400.0);
  }
  
  double safeHeight(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.height * percentage).clamp(20.0, 200.0);
  }
  
  double safeFontSize(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.width * percentage).clamp(10.0, 28.0);
  }
  
  double safeIconSize(BuildContext context, double percentage) {
    return (MediaQuery.of(context).size.width * percentage).clamp(16.0, 32.0);
  }
  
  EdgeInsets safePadding(BuildContext context, double percentage) {
    final value = (MediaQuery.of(context).size.width * percentage).clamp(8.0, 24.0);
    return EdgeInsets.all(value);
  }
  
  // Safe text widget with overflow protection
  Widget safeText(
    String text, {
    required BuildContext context,
    double fontSizePercentage = 0.04,
    FontWeight? fontWeight,
    Color? color,
    int? maxLines,
    TextOverflow? overflow = TextOverflow.ellipsis,
    TextAlign? textAlign,
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
      textAlign: textAlign,
    );
  }
  
  // Safe flexible row to prevent overflow
  Widget safeRow({
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
  
  // Safe container with responsive sizing
  Widget safeContainer({
    required BuildContext context,
    Widget? child,
    double? widthPercentage,
    double? heightPercentage,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? margin,
    Decoration? decoration,
  }) {
    return Container(
      width: widthPercentage != null ? safeWidth(context, widthPercentage) : null,
      height: heightPercentage != null ? safeHeight(context, heightPercentage) : null,
      padding: padding,
      margin: margin,
      decoration: decoration,
      child: child,
    );
  }
}