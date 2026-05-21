import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:upsc_ca_ui/shared/widgets/progress_bar.dart';

class ModernLoadingScreen extends StatelessWidget {
  final double progress;
  final String status;
  final String? title;

  const ModernLoadingScreen({
    super.key,
    required this.progress,
    required this.status,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
      body: Stack(
        children: [
          // Background accents
          if (isDark)
            Positioned(
              top: -100,
              right: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor.withValues(alpha: 0.1),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 100, sigmaY: 100),
                  child: Container(color: Colors.transparent),
                ),
              ),
            ),
          
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Logo or Icon
                  Container(
                    width: 64,
                    height: 64,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: primaryColor.withValues(alpha: 0.2)),
                    ),
                    child: Icon(Icons.cloud_sync_rounded, color: primaryColor, size: 32),
                  ),
                  const SizedBox(height: 32),
                  
                  // Title
                  Text(
                    title ?? 'SETTING UP YOUR SPACE',
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87,
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Status Text
                  Text(
                    status.toUpperCase(),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Progress Bar
                  ProgressBar(
                    progress: progress,
                    width: double.infinity,
                    height: 8,
                  ),
                  const SizedBox(height: 16),
                  
                  // Percentage Text
                  Text(
                    '${(progress * 100).toInt()}%',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Bottom Quote or Tip
          Positioned(
            bottom: 60,
            left: 40,
            right: 40,
            child: Text(
              'Great things take time. We are preparing the best materials for your preparation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? Colors.white12 : Colors.black12,
                fontSize: 11,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
