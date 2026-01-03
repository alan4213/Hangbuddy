import 'package:flutter/material.dart';

class VerifiedBadge extends StatelessWidget {
  final double size;
  
  const VerifiedBadge({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: Colors.white,
        size: size * 0.7,
      ),
    );
  }
}