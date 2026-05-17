import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/providers/subscription_provider.dart';
import 'package:upsc_ca_ui/shared/widgets/blur_button.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _selectedPlan = 'yearly';
  bool _agreeToTerms = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          _buildBackground(primaryColor),

          // Main Content
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(context),
                _buildPlans(context, primaryColor),
                _buildBenefits(context),
                _buildTermsSection(context, primaryColor),
                _buildActionButton(context, primaryColor),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),

          // Close Button
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: BlurButton(
              icon: Icons.close_rounded,
              onTap: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground(Color primaryColor) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        image: DecorationImage(
          image: const NetworkImage('https://www.transparenttextures.com/patterns/asfalt-dark.png'),
          repeat: ImageRepeat.repeat,
          opacity: 0.1,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.2),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 32),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.workspace_premium_rounded, color: Colors.amber, size: 48),
            ),
            const SizedBox(height: 24),
            const Text(
              'UPSC Premium',
              style: TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w900,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Elevate your preparation with exclusive insights',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white60,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlans(BuildContext context, Color primaryColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            _buildPlanCard(
              id: 'monthly',
              title: 'Monthly',
              price: '₹299',
              subtitle: 'Billed monthly',
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              id: 'quarterly',
              title: 'Quarterly',
              price: '₹599',
              subtitle: 'Billed every 3 months',
              badge: 'POPULAR',
              primaryColor: primaryColor,
            ),
            const SizedBox(height: 16),
            _buildPlanCard(
              id: 'yearly',
              title: 'Yearly',
              price: '₹1999',
              subtitle: 'Only ₹167/month',
              badge: 'BEST VALUE',
              primaryColor: primaryColor,
              highlight: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlanCard({
    required String id,
    required String title,
    required String price,
    required String subtitle,
    String? badge,
    required Color primaryColor,
    bool highlight = false,
  }) {
    final isSelected = _selectedPlan == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPlan = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.white.withValues(alpha: 0.1),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(color: primaryColor.withValues(alpha: 0.2), blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (badge != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: highlight ? Colors.amber : primaryColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        badge,
                        style: TextStyle(
                          color: highlight ? Colors.black : primaryColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    title,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
                ),
                Icon(
                  isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: isSelected ? primaryColor : Colors.white24,
                  size: 24,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBenefits(BuildContext context) {
    final benefits = [
      {'icon': Icons.article_rounded, 'text': 'Unlimited Premium Articles'},
      {'icon': Icons.quiz_rounded, 'text': 'Full Access to Daily Quizzes'},
      {'icon': Icons.psychology_rounded, 'text': 'AI-Powered Study Insights'},
      {'icon': Icons.analytics_rounded, 'text': 'Advanced Preparation Analytics'},
    ];

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
        child: Column(
          children: benefits.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Icon(b['icon'] as IconData, color: Colors.amber, size: 20),
                const SizedBox(width: 16),
                Text(
                  b['text'] as String,
                  style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          )).toList(),
        ),
      ),
    );
  }

  Widget _buildTermsSection(BuildContext context, Color primaryColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text('Terms & Conditions', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w700)),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: Text(
                      '• Auto-renewal: Subscriptions renew automatically unless cancelled 24h before end date.\n'
                      '• Cancellation: Manage in your App Store settings.\n'
                      '• Refund: Non-refundable as per platform policies.\n'
                      '• Trial: 3-month trial available for first-time users only.',
                      style: TextStyle(color: Colors.white38, fontSize: 11, height: 1.5),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(onPressed: () {}, child: const Text('Privacy Policy', style: TextStyle(fontSize: 12))),
                      const Text('|', style: TextStyle(color: Colors.white10)),
                      TextButton(onPressed: () {}, child: const Text('Terms of Service', style: TextStyle(fontSize: 12))),
                    ],
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Checkbox(
                  value: _agreeToTerms,
                  onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
                  fillColor: WidgetStateProperty.all(primaryColor),
                ),
                const Expanded(
                  child: Text(
                    'I agree to the Terms & Conditions',
                    style: TextStyle(color: Colors.white60, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, Color primaryColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Google Play Secure Payment Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.security_rounded, color: Colors.green, size: 14),
                const SizedBox(width: 8),
                Text(
                  'SECURE PAYMENT VIA GOOGLE PLAY',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Consumer<SubscriptionProvider>(
              builder: (context, provider, _) {
                return GestureDetector(
                  onTap: (_agreeToTerms && !provider.isLoading) 
                      ? () async {
                          final success = await provider.purchasePlan(_selectedPlan);
                          if (success && mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Subscription activated successfully!')),
                            );
                          }
                        }
                      : null,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: _agreeToTerms ? 1.0 : 0.5,
                    child: Container(
                      width: double.infinity,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [primaryColor, primaryColor.withValues(alpha: 0.8)]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          if (_agreeToTerms)
                            BoxShadow(color: primaryColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 10)),
                        ],
                      ),
                      child: Center(
                        child: provider.isLoading 
                          ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('ACTIVATE PREMIUM', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.read<SubscriptionProvider>().restorePurchases(),
              child: const Text('Restore Purchase', style: TextStyle(color: Colors.white38, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
