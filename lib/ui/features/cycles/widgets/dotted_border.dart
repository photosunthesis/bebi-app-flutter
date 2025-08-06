import 'package:flutter/material.dart';

class DottedBorder extends StatelessWidget {
  const DottedBorder({
    super.key,
    required this.child,
    required this.color,
    this.dotSpacing = 5.0,
    this.strokeWidth = .2,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final Color color;
  final double dotSpacing;
  final double strokeWidth;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DottedBorderPainter(
        color: color,
        dotSpacing: dotSpacing,
        strokeWidth: strokeWidth,
        borderRadius: borderRadius,
      ),
      child: ClipRRect(borderRadius: borderRadius, child: child),
    );
  }
}

class _DottedBorderPainter extends CustomPainter {
  _DottedBorderPainter({
    required this.color,
    required this.dotSpacing,
    required this.strokeWidth,
    required this.borderRadius,
  });

  final Color color;
  final double dotSpacing;
  final double strokeWidth;
  final BorderRadius borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(0, 0, size.width, size.height),
          topLeft: borderRadius.topLeft,
          topRight: borderRadius.topRight,
          bottomLeft: borderRadius.bottomLeft,
          bottomRight: borderRadius.bottomRight,
        ),
      );

    final pathMetrics = path.computeMetrics().first;
    final dashLength = dotSpacing / 2;
    final dashGap = dotSpacing / 2;

    var distance = 0.0;
    while (distance < pathMetrics.length) {
      final start = distance;
      final end = (start + dashLength).clamp(0.0, pathMetrics.length);

      final extractPath = pathMetrics.extractPath(start, end);
      canvas.drawPath(extractPath, paint);

      distance += dashLength + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
