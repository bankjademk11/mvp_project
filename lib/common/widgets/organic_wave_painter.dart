
import 'package:flutter/material.dart';

class OrganicWavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF34D399).withOpacity(0.8) // Use the primary green color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.25);
    path.quadraticBezierTo(
        size.width * 0.20, size.height * 0.35, size.width * 0.5, size.height * 0.20);
    path.quadraticBezierTo(
        size.width * 0.85, size.height * 0.05, size.width, size.height * 0.15);
    path.lineTo(size.width, 0);
    path.lineTo(0, 0);
    path.close();

    canvas.drawPath(path, paint);

    final paint2 = Paint()
      ..color = const Color(0xFF34D399) // A slightly different shade
      ..style = PaintingStyle.fill;

    final path2 = Path();
    path2.moveTo(0, size.height * 0.28);
    path2.quadraticBezierTo(
        size.width * 0.25, size.height * 0.40, size.width * 0.55, size.height * 0.22);
    path2.quadraticBezierTo(
        size.width * 0.90, size.height * 0.08, size.width, size.height * 0.18);
    path2.lineTo(size.width, 0);
    path2.lineTo(0, 0);
    path2.close();

    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
