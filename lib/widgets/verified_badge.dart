import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  final bool isVerified;
  
  const VerifiedBadge({
    super.key,
    this.size = 16,
    this.isVerified = true,
  });

  @override
  Widget build(BuildContext context) {
    return Icon(
      Icons.verified,
      color: isVerified ? Colors.blue : Colors.grey[400],
      size: size,
    );
  }
}