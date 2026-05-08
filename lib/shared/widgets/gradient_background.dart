import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GradientBackground extends StatefulWidget {
  final Widget child;
  const GradientBackground({super.key, required this.child});

  @override
  State<GradientBackground> createState() => _GradientBackgroundState();
}

class _GradientBackgroundState extends State<GradientBackground> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );
    unawaited(_controller.repeat());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          // 1. Base Mesh Gradient
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return CustomPaint(
                  painter: MeshPainter(
                    progress: _controller.value,
                    isDark: isDark,
                    primaryColor: theme.colorScheme.primary,
                  ),
                );
              },
            ),
          ),

          // 2. Grain/Noise Texture Overlay
          Positioned.fill(
            child: Opacity(
              opacity: isDark ? 0.04 : 0.02,
              child: Image.network(
                'https://www.transparenttextures.com/patterns/asfalt-dark.png',
                repeat: ImageRepeat.repeat,
                color: isDark ? Colors.white : Colors.black,
                colorBlendMode: isDark ? BlendMode.overlay : BlendMode.multiply,
              ),
            ),
          ),

          // 3. Subtle Vignette
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [
                    Colors.transparent,
                    backgroundColor.withValues(alpha: 0.1),
                  ],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
          ),

          // 4. Main Content
          SafeArea(child: widget.child),
        ],
      ),
    );
  }
}

class MeshPainter extends CustomPainter {
  final double progress;
  final bool isDark;
  final Color primaryColor;
  MeshPainter({required this.progress, required this.isDark, required this.primaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..maskFilter = const MaskFilter.blur(BlurStyle.normal, 100);

    void drawBlob(Offset center, double radius, Color color) {
      paint.color = color;
      canvas.drawCircle(center, radius, paint);
    }

    final double baseOpacity = isDark ? 0.3 : 0.15;

    // Blob 1: Dynamic Primary (Moves in a large circle)
    final b1Center = Offset(
      size.width * 0.2 + 100 * math.cos(progress * 2 * math.pi),
      size.height * 0.2 + 80 * math.sin(progress * 2 * math.pi),
    );
    drawBlob(b1Center, 250, primaryColor.withValues(alpha: baseOpacity));

    // Blob 2: Primary Accent (Moves in figure eight)
    final b2Center = Offset(
      size.width * 0.8 + 120 * math.sin(progress * 2 * math.pi),
      size.height * 0.7 + 100 * math.sin(progress * 4 * math.pi),
    );
    drawBlob(b2Center, 300, primaryColor.withValues(alpha: baseOpacity));

    // Blob 3: Primary Soft (Slow drift)
    final b3Center = Offset(
      size.width * 0.5 + 50 * math.cos(progress * 2 * math.pi + 1),
      size.height * 0.4 + 150 * math.sin(progress * 1 * math.pi),
    );
    drawBlob(b3Center, 200, primaryColor.withValues(alpha: baseOpacity * 0.8));
    
    // Blob 4: Soft Highlight
    final b4Center = Offset(
      size.width * 0.1 + 80 * math.sin(progress * 3 * math.pi),
      size.height * 0.9,
    );
    drawBlob(b4Center, 150, (isDark ? Colors.white : primaryColor).withValues(alpha: baseOpacity * 0.5));
  }

  @override
  bool shouldRepaint(covariant MeshPainter oldDelegate) => 
    oldDelegate.progress != progress || oldDelegate.isDark != isDark || oldDelegate.primaryColor != primaryColor;
}
