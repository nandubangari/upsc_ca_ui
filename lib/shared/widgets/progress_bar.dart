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
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0.05, 1.0),
        child: Container(
          decoration: BoxDecoration(
            color: primaryColor,
            borderRadius: BorderRadius.circular(height / 2),
            boxShadow: [
              BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}
