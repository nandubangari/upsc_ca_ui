import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/providers/subscription_provider.dart';
import 'package:upsc_ca_ui/shared/widgets/locked_overlay.dart';
import 'package:upsc_ca_ui/features/subscription/screens/subscription_screen.dart';

class PremiumGate extends StatelessWidget {
  final Widget child;
  final bool isFree;
  final String? subtitle;

  const PremiumGate({
    super.key,
    required this.child,
    this.isFree = false,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    if (isFree) return child;

    return Consumer<SubscriptionProvider>(
      builder: (context, subscription, _) {
        if (subscription.isPremium) return child;

        return Stack(
          children: [
            child,
            Positioned.fill(
              child: LockedOverlay(
                subtitle: subtitle ?? "Your free access has ended",
                onUnlock: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SubscriptionScreen()),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
