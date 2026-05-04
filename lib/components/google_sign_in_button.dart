import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback onPressed;
  final bool isLoading;
  const GoogleSignInButton({
    super.key,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pressController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isLoading ? null : (_) => _pressController.forward(),
      onTapUp: widget.isLoading ? null : (_) => _pressController.reverse(),
      onTapCancel: widget.isLoading ? null : () => _pressController.reverse(),
      onTap: widget.isLoading ? null : widget.onPressed,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          height: 64,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -4,
              ),
            ],
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white,
                Color(0xFFF8F8F8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // 1. Shimmer Effect (only if not loading)
              if (!widget.isLoading)
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) {
                    return FractionalTranslation(
                      translation: Offset(_shimmerController.value * 3 - 1, 0),
                      child: Transform.rotate(
                        angle: 0.5,
                        child: Container(
                          width: 80,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.white.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.8),
                                Colors.white.withValues(alpha: 0.0),
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

              // 2. Button Content
              Center(
                child: widget.isLoading
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.primary),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Image.network(
                            'https://www.gstatic.com/images/branding/product/2x/googleg_48dp.png',
                            height: 28,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.g_mobiledata, color: Colors.blue, size: 28);
                            },
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              'Continue with Google',
                              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                    color: Colors.black87,
                                    fontSize: 18,
                                  ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
