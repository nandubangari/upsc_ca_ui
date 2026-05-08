import 'package:flutter/material.dart';

class SectionHeader extends StatelessWidget {
  final String title;
  final bool isLarge;

  const SectionHeader({
    super.key,
    required this.title,
    this.isLarge = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isLarge) {
      return Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 10),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            color: isDark ? Colors.white24 : Colors.black45,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3),
          fontSize: 12,
          fontWeight: FontWeight.w900,
          letterSpacing: 2.0,
        ),
      ),
    );
  }
}
