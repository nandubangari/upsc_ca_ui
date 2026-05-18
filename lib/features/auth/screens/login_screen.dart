import 'dart:async';
import 'package:flutter/material.dart';
import 'package:upsc_ca_ui/shared/widgets/glass_card.dart';
import 'package:upsc_ca_ui/shared/widgets/animated_logo.dart';
import 'package:upsc_ca_ui/shared/widgets/google_sign_in_button.dart';
import 'package:provider/provider.dart';
import 'package:upsc_ca_ui/data/repositories/auth_repository.dart';
import 'package:upsc_ca_ui/core/services/analytics_service.dart';
import 'package:upsc_ca_ui/data/services/firestore_service.dart';
import 'package:upsc_ca_ui/features/subscription/screens/terms_and_conditions_screen.dart';

import 'package:upsc_ca_ui/features/profile/screens/profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _agreeToTerms = false;
  final AuthRepository _authRepository = AuthRepository();
  final FirestoreService _firestoreService = FirestoreService();

  Future<void> _handleSignIn() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check "I agree to the Terms and Conditions" to continue.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authRepository.signInWithGoogle();
    
    if (!mounted) return;
    
    if (result != null && result.user != null) {
      // Log login event
      if (mounted) {
        context.read<AnalyticsService>().logLogin('google');
      }

      // Save user to Firestore
      await _firestoreService.saveUser(result.user!);
      
      if (!mounted) return;
      
      unawaited(Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      ));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please try again.')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLandscape = constraints.maxWidth > constraints.maxHeight;
          final isTablet = constraints.maxWidth >= 600;

          // Only use split layout if it's actually in Landscape mode.
          // For Tablet Portrait, we want a centered premium card.
          if (isLandscape) {
            return _buildLandscapeLayout(context);
          } else {
            return _buildPortraitLayout(context, isTablet: isTablet);
          }
        },
      ),
    );
  }

  Widget _buildPortraitLayout(BuildContext context, {bool isTablet = false}) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: GlassCard(
            maxWidth: isTablet ? 500 : 420, // Slightly wider for tablets
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildCommonContent(context, textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLandscapeLayout(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.of(context).size.height,
        ),
        child: Row(
          children: [
            // Left Side - Branding
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(64),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const AnimatedLogo(),
                    const SizedBox(height: 48),
                    Text(
                      'UPSC\nCurrent Affairs',
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        fontSize: 56,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Revision That\nActually Works.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontSize: 22,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Right Side - Login Card
            Expanded(
              flex: 1,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  child: GlassCard(
                    maxWidth: 420,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Welcome back',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Elevate your preparation with premium insights.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 48),
                        _buildTermsCheckbox(context),
                        const SizedBox(height: 16),
                        GoogleSignInButton(
                          isLoading: _isLoading,
                          onPressed: () => unawaited(_handleSignIn()),
                        ),
                        const SizedBox(height: 40),
                        const Text(
                          'By continuing, you agree to our\nPrivacy Policy and Terms of Service.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildCommonContent(BuildContext context, {required TextAlign textAlign}) {
    return [
      const AnimatedLogo(),
      const SizedBox(height: 40),
      Text(
        'UPSC CA',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      const SizedBox(height: 12),
      Text(
        'Revision That Actually Works.',
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 56),
      _buildTermsCheckbox(context),
      const SizedBox(height: 16),
      GoogleSignInButton(
        isLoading: _isLoading,
        onPressed: () => unawaited(_handleSignIn()),
      ),
      const SizedBox(height: 48),
      const Text(
        'Privacy Policy  •  Terms of Service',
        style: TextStyle(
          color: Colors.white24,
          fontSize: 12,
          letterSpacing: 0.5,
        ),
      ),
    ];
  }

  Widget _buildTermsCheckbox(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: Checkbox(
              value: _agreeToTerms,
              onChanged: (val) => setState(() => _agreeToTerms = val ?? false),
              activeColor: primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Wrap(
              children: [
                const Text(
                  'I agree to the ',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TermsAndConditionsScreen(showAcceptance: false),
                        fullscreenDialog: true,
                      ),
                    );
                  },
                  child: Text(
                    'Terms & Conditions',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}











