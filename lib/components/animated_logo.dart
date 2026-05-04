import 'package:flutter/material.dart';
import 'dart:math' as math;

class AnimatedLogo extends StatefulWidget {
  const AnimatedLogo({super.key});

  @override
  State<AnimatedLogo> createState() => _AnimatedLogoState();
}

class _AnimatedLogoState extends State<AnimatedLogo> with TickerProviderStateMixin {
  late AnimationController _mainController;

  @override
  void initState() {
    super.initState();
    _mainController = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _mainController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return AnimatedBuilder(
      animation: _mainController,
      builder: (context, child) {
        final floatY = 8 * math.sin(_mainController.value * 2 * math.pi);
        
        return Stack(
          alignment: Alignment.center,
          children: [
            // 1. Volumetric Outer Glow
            ...List.generate(3, (index) {
              final scale = 1.0 + (index * 0.2);
              final opacity = 0.3 - (index * 0.1);
              return Transform.scale(
                scale: scale + (0.05 * math.sin(_mainController.value * 2 * math.pi)),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: opacity),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // 2. Rotating Halo Ring
            Transform.rotate(
              angle: _mainController.value * 2 * math.pi,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: primaryColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
              ),
            ),

            // 3. Floating Glass Orb
            Transform.translate(
              offset: Offset(0, floatY),
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withValues(alpha: 0.4),
                      blurRadius: 20,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Stack(
                    children: [
                      // Glossy Highlight
                      Positioned(
                        top: 10,
                        left: 15,
                        child: Container(
                          width: 40,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.4),
                            borderRadius: const BorderRadius.all(Radius.elliptical(40, 20)),
                          ),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.auto_stories,
                          size: 45,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
