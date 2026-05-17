import 'dart:ui';
import 'package:flutter/material.dart';

class LockedOverlay extends StatelessWidget {
  final VoidCallback onUnlock;
  final String subtitle;

  const LockedOverlay({
    super.key,
    required this.onUnlock,
    this.subtitle = "Your free access has ended",
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxHeight = constraints.maxHeight;
        
        // Adaptive thresholds
        final bool isVeryCompact = maxHeight < 50;
        final bool isCompact = maxHeight < 160;

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // 1. Blur Layer
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                  child: Container(
                    color: isDark ? Colors.black.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ),
              
              // 2. Content
              Center(
                child: Padding(
                  padding: EdgeInsets.all(isVeryCompact ? 2 : 12),
                  child: isVeryCompact
                    ? Icon(Icons.lock_rounded, color: primaryColor, size: 14)
                    : isCompact 
                      ? _buildCompactLayout(primaryColor, isDark)
                      : _buildFullLayout(primaryColor, isDark),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildFullLayout(Color primaryColor, bool isDark) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated Lock Icon
          _AnimatedLock(color: primaryColor),
          const SizedBox(height: 12),
          
          // Premium Badge
          _PremiumBadge(primaryColor: primaryColor),
          const SizedBox(height: 8),
          
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          
          // CTA Button
          ElevatedButton(
            onPressed: onUnlock,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              elevation: 0,
            ),
            child: const Text(
              'Unlock Premium',
              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactLayout(Color primaryColor, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock_rounded, color: primaryColor, size: 18),
        const SizedBox(width: 12),
        _PremiumBadge(primaryColor: primaryColor),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onUnlock,
          child: Text(
            'UNLOCK',
            style: TextStyle(
              color: primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumBadge extends StatelessWidget {
  const _PremiumBadge({
    required this.primaryColor,
  });

  final Color primaryColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'PREMIUM',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AnimatedLock extends StatefulWidget {
  final Color color;
  const _AnimatedLock({required this.color});

  @override
  State<_AnimatedLock> createState() => _AnimatedLockState();
}

class _AnimatedLockState extends State<_AnimatedLock> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.lock_rounded, color: widget.color, size: 28),
      ),
    );
  }
}
