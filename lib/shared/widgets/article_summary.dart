import 'package:flutter/material.dart';

class ArticleSummary extends StatelessWidget {
  final List<String> summary;
  final bool isTablet;

  const ArticleSummary({
    super.key,
    required this.summary,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryColor.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.summarize_outlined, size: 14, color: primaryColor),
              const SizedBox(width: 8),
              const Text(
                'EXECUTIVE SUMMARY',
                style: TextStyle(
                  color: Color(0xFFFF6F00), // Defaulting to saffron for consistency if needed, or theme.primary
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...summary.map((point) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    point,
                    style: TextStyle(
                      color: isDark ? Colors.white.withValues(alpha: 0.8) : Colors.black.withValues(alpha: 0.75),
                      fontSize: isTablet ? 16 : 14,
                      height: 1.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}
