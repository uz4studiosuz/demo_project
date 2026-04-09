import 'package:flutter/material.dart';

class LiquidPainter extends CustomPainter {
  final Color color;

  LiquidPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();

    // Wave 1
    path.moveTo(size.width * 0.2, 0);
    path.quadraticBezierTo(
      size.width * 0.45,
      size.height * 0.1,
      size.width * 0.9,
      size.height * 0.3,
    );
    path.lineTo(size.width, size.height * 0.3);
    path.lineTo(size.width, 0);
    path.close();
    canvas.drawPath(path, paint);

    // Wave 2
    final path2 = Path();
    path2.moveTo(0, size.height * 0.15);
    path2.quadraticBezierTo(
      size.width * 0.3,
      size.height * 0.25,
      size.width * 0.8,
      size.height * 0.1,
    );
    path2.quadraticBezierTo(
      size.width * 0.9,
      size.height * 0.05,
      size.width,
      size.height * 0.02,
    );
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();
    canvas.drawPath(path2, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
