import 'package:flutter/material.dart';

class HangbuddyLogo extends StatelessWidget {
  final double size;
  
  const HangbuddyLogo({super.key, this.size = 60});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size * 1.2),
      painter: LogoPainter(),
    );
  }
}

class LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    // Blue location pin shape
    paint.color = const Color(0xFF6366F1);
    
    final path = Path();
    final centerX = size.width / 2;
    final radius = size.width * 0.4;
    final topY = size.height * 0.15;
    final bottomY = size.height * 0.85;
    
    // Create location pin shape
    path.addOval(Rect.fromCircle(
      center: Offset(centerX, topY + radius),
      radius: radius,
    ));
    
    // Add the pointed bottom
    path.moveTo(centerX - radius * 0.3, topY + radius * 1.6);
    path.lineTo(centerX, bottomY);
    path.lineTo(centerX + radius * 0.3, topY + radius * 1.6);
    path.close();
    
    canvas.drawPath(path, paint);
    
    // White circle inside
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(centerX, topY + radius),
      radius * 0.6,
      paint,
    );
    
    // Orange center dot
    paint.color = const Color(0xFFF59E0B);
    canvas.drawCircle(
      Offset(centerX, topY + radius),
      radius * 0.25,
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}