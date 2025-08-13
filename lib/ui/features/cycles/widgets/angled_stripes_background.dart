import 'dart:math';
import 'package:flutter/material.dart';

class AngledStripesBackground extends StatelessWidget {
  const AngledStripesBackground({
    super.key,
    required this.color,
    this.backgroundColor = Colors.white,
    this.stripeWidth = 1.6,
    this.angle = -45.0,
     this.width = 26,
     this.height = 26,
    this.shape = const CircleBorder(),
  });

  final double stripeWidth;
  final double angle;
  final Color color;
  final Color backgroundColor;
  final double width;
  final double height;
  final ShapeBorder shape;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: ClipPath(
        clipper: ShapeBorderClipper(shape: shape),
        child: CustomPaint(
          painter: _StripePainter(
            stripeWidth: stripeWidth,
            angle: angle,
            color: color,
            backgroundColor: backgroundColor,
          ),
        ),
      ),
    );
  }
}

class _StripePainter extends CustomPainter {
  const _StripePainter({
    required this.stripeWidth,
    required this.angle,
    required this.color,
    required this.backgroundColor,
  });

  final double stripeWidth;
  final double angle;
  final Color color;
  final Color backgroundColor;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = backgroundColor);
    final paint = Paint()
      ..color = color
      ..strokeWidth = stripeWidth
      ..style = PaintingStyle.stroke;

    final radians = angle * (pi / 180);

    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.rotate(radians);
    canvas.translate(-size.width / 2, -size.height / 2);

    final spacing = stripeWidth * 2;
    final numLines = (size.width + size.height) ~/ spacing;

    for (var i = -numLines; i < numLines * 2; i++) {
      final startY = i * spacing;
      canvas.drawLine(
        Offset(-size.width, startY.toDouble()),
        Offset(size.width * 2, startY.toDouble()),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StripePainter oldDelegate) {
    return oldDelegate.stripeWidth != stripeWidth ||
        oldDelegate.angle != angle ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
