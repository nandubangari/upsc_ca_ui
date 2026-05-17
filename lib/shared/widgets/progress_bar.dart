import 'package:flutter/material.dart';

class ProgressBar extends StatelessWidget {
  final double progress;
  final double width;
  final double height;

  const ProgressBar({
    super.key,
    required this.progress,
    this.width = 40,
    this.height = 4,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(width, height),
        painter: _ProgressBarPainter(
          progress: progress.clamp(0.05, 1.0),
          color: primaryColor,
          backgroundColor: Colors.white10,
        ),
      ),
    );
  }
}

class _ProgressBarPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color backgroundColor;

  _ProgressBarPainter({
    required this.progress,
    required this.color,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.fill;

    final radius = size.height / 2;
    
    // Draw background
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, size.width, size.height),
        Radius.circular(radius),
      ),
      paint,
    );

    // Draw progress
    paint.color = color;
    
    final progressWidth = size.width * progress;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, progressWidth, size.height),
        Radius.circular(radius),
      ),
      paint,
    );
    
    // Removed duplicate sharp draw as blur was removed
  }

  @override
  bool shouldRepaint(covariant _ProgressBarPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.backgroundColor != backgroundColor;
  }
}
