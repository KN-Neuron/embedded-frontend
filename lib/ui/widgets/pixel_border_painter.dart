import 'package:flutter/material.dart';

class PixelBorderPainter extends CustomPainter {
  final Color color;
  final double pixelSize;

  PixelBorderPainter({required this.color, this.pixelSize = 4.0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (double i = 0; i < size.width; i += pixelSize) {
      canvas.drawRect(Rect.fromLTWH(i, 0, pixelSize, pixelSize), paint);
      canvas.drawRect(Rect.fromLTWH(i, size.height - pixelSize, pixelSize, pixelSize), paint);
    }
    for (double i = 0; i < size.height; i += pixelSize) {
      canvas.drawRect(Rect.fromLTWH(0, i, pixelSize, pixelSize), paint);
      canvas.drawRect(Rect.fromLTWH(size.width - pixelSize, i, pixelSize, pixelSize), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}