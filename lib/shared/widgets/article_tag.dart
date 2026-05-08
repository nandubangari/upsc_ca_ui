import 'package:flutter/material.dart';

class ArticleTag extends StatelessWidget {
  final String tag;

  const ArticleTag({
    super.key,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black12),
      ),
      child: Text(
        tag.toUpperCase(),
        style: TextStyle(
          color: isDark ? Colors.white60 : Colors.black54,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}
