import 'package:flutter/material.dart';
import 'package:upsc_ca_ui/shared/models/article_content.dart';

class ArticleRichText extends StatelessWidget {
  final List<InlineSpanData> spans;
  final bool isTablet;
  final double fontSize;

  const ArticleRichText({
    super.key,
    required this.spans,
    required this.isTablet,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text.rich(
      TextSpan(
        children: spans.map((s) {
          final color = _parseColor(s.color);
          return TextSpan(
            text: s.text,
            style: TextStyle(
              color: color ?? (isDark ? Colors.white.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.8)),
              fontSize: isTablet ? fontSize + 2 : fontSize,
              fontWeight: s.isBold ? FontWeight.bold : FontWeight.normal,
              height: 1.6,
            ),
          );
        }).toList(),
      ),
    );
  }

  static Color? _parseColor(String? cssColor) {
    if (cssColor == null) return null;
    final cleanColor = cssColor.trim().toLowerCase();
    
    if (cleanColor == "red") return Colors.red;
    if (cleanColor == "blue") return Colors.blue;
    if (cleanColor == "green") return Colors.green;
    
    if (cleanColor.startsWith("#")) {
      try {
        final hex = cleanColor.replaceFirst("#", "");
        if (hex.length == 6) {
          return Color(int.parse("FF$hex", radix: 16));
        } else if (hex.length == 3) {
          final fullHex = hex.split('').map((e) => '$e$e').join();
          return Color(int.parse("FF$fullHex", radix: 16));
        }
      } catch (_) {}
    }
    return null;
  }
}

class ArticleTable extends StatelessWidget {
  final List<List<String>> rows;

  const ArticleTable({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isDark ? Colors.white12 : Colors.black12),
        ),
        child: Table(
          border: TableBorder.symmetric(inside: BorderSide(color: isDark ? Colors.white12 : Colors.black12)),
          children: rows.map((row) {
            return TableRow(
              children: row.map((cell) {
                return Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    cell,
                    style: TextStyle(
                      color: isDark ? Colors.white70 : Colors.black87,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                );
              }).toList(),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class ArticleListItemWidget extends StatelessWidget {
  final ListItem item;
  final bool isTablet;

  const ArticleListItemWidget({
    super.key,
    required this.item,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 10, right: 12),
                child: Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Expanded(
                child: ArticleRichText(spans: item.spans, isTablet: isTablet, fontSize: 16),
              ),
            ],
          ),
        ),
        if (item.children.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              children: item.children.map((child) => ArticleListItemWidget(item: child, isTablet: isTablet)).toList(),
            ),
          ),
      ],
    );
  }
}

class ArticleInfoBox extends StatelessWidget {
  final InfoBoxData data;
  final bool isTablet;

  const ArticleInfoBox({
    super.key,
    required this.data,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return RepaintBoundary(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 24),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.blueGrey.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.blueGrey.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.heading,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: isTablet ? 18 : 16,
                fontWeight: FontWeight.w800,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            ...data.items.map((item) => _buildInfoItem(context, item, isTablet, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, InfoItem item, bool isTablet, bool isDark) {
    return Padding(
      padding: EdgeInsets.only(
        left: item.level * 20.0,
        bottom: 10,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 11, right: 12),
            child: Container(
              width: 8,
              height: 1.5,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          ),
          Expanded(
            child: ArticleRichText(spans: item.spans, isTablet: isTablet, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
