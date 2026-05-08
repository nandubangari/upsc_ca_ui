import 'dart:ui';
import 'package:flutter/material.dart';

class BlurButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? iconColor;
  final double size;

  const BlurButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.iconColor,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
            ),
            child: Icon(
              icon, 
              color: iconColor ?? (isDark ? Colors.white70 : Colors.black54), 
              size: size * 0.4,
            ),
          ),
        ),
      ),
    );
  }
}
