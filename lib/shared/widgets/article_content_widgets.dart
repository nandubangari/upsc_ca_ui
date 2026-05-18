import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:upsc_ca_ui/shared/models/article_content.dart';

class ZoomableArticleImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final bool isTablet;
  final BoxFit fit;
  final double? displayHeight;

  const ZoomableArticleImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    required this.isTablet,
    this.fit = BoxFit.contain,
    this.displayHeight,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: double.infinity,
      fit: fit,
      memCacheWidth: isTablet ? 1200 : 800,
      imageBuilder: (context, imageProvider) => Container(
        height: displayHeight ?? (height ?? 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: DecorationImage(image: imageProvider, fit: fit),
        ),
      ),
      placeholder: (context, url) => Container(
        height: displayHeight ?? (height ?? 100),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator(strokeWidth: 1)),
      ),
      errorWidget: (context, url, error) => const SizedBox.shrink(),
    );

    if (width != null && height != null && displayHeight == null) {
      image = AspectRatio(
        aspectRatio: width! / height!,
        child: image,
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context),
      child: Hero(
        tag: imageUrl,
        child: image,
      ),
    );
  }

  void _showFullScreenImage(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true, // 🟢 STABILITY FIX: Using opaque routes prevents complex framework detachment issues
        barrierDismissible: false,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FullScreenImageViewer(imageUrl: imageUrl);
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}

class FullScreenImageViewer extends StatefulWidget {
  final String imageUrl;

  const FullScreenImageViewer({super.key, required this.imageUrl});

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer> with SingleTickerProviderStateMixin {
  final TransformationController _transformationController = TransformationController();
  late AnimationController _animationController;
  Animation<Matrix4>? _animation;
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(() {
        if (_animation != null) {
          _transformationController.value = _animation!.value;
        }
      });
  }

  @override
  void dispose() {
    _transformationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _handleDoubleTap() {
    final Matrix4 currentMatrix = _transformationController.value;
    final Matrix4 endMatrix;

    if (currentMatrix != Matrix4.identity()) {
      endMatrix = Matrix4.identity();
    } else {
      final position = _doubleTapDetails!.localPosition;
      const double scale = 2.5;
      
      // Calculate translation to center the tapped point
      final Size size = MediaQuery.of(context).size;
      final double x = -position.dx * scale + size.width / 2;
      final double y = -position.dy * scale + size.height / 2;

      endMatrix = Matrix4.identity()
        ..translate(x, y)
        ..scale(scale);
    }

    _animation = Matrix4Tween(
      begin: currentMatrix,
      end: endMatrix,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic));

    _animationController.forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // 🟢 STABILITY FIX: Solid background for opaque route
      body: Stack(
        children: [
          // Background tap to pop - only if hit directly
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => Navigator.of(context).pop(),
              child: Container(color: Colors.transparent),
            ),
          ),
          
          // Full-screen gesture area for InteractiveViewer
          Positioned.fill(
            child: GestureDetector(
              // 🟢 FIX: Consume single taps here so they don't reach the background 'pop' handler
              onTap: () {}, 
              onDoubleTapDown: (details) => _doubleTapDetails = details,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _transformationController,
                minScale: 1.0,
                maxScale: 4.0,
                // Using constrained: true ensures the child stays centered properly
                constrained: true,
                onInteractionStart: (_) {
                  if (_animationController.isAnimating) {
                    _animationController.stop();
                  }
                },
                child: Center(
                  child: Hero(
                    tag: widget.imageUrl,
                    child: CachedNetworkImage(
                      imageUrl: widget.imageUrl,
                      fit: BoxFit.contain,
                      // 🟢 IMPROVEMENT: Match memCache settings or remove them for full-res view
                      placeholder: (context, url) => const Center(
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 1),
                      ),
                      errorWidget: (context, url, error) => const Icon(Icons.error_outline, color: Colors.white38),
                    ),
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
