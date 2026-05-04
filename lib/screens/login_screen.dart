import 'package:flutter/material.dart';
import '../components/gradient_background.dart';
import '../components/glass_card.dart';
import '../components/animated_logo.dart';
import '../components/google_sign_in_button.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

import 'profile_setup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  void _handleSignIn() async {
    setState(() => _isLoading = true);
    
    final result = await _authService.signInWithGoogle();
    
    if (!mounted) return;
    
    if (result != null && result.user != null) {
      // Save user to Firestore
      await _firestoreService.saveUser(result.user!);
      
      if (!mounted) return;
      
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const ProfileSetupScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in failed. Please try again.')),
      );
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return GradientBackground(
      child: LayoutBuilder(
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
                      'Read today.\nRecall tomorrow.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.white70,
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
                        const SizedBox(height: 56),
                        GoogleSignInButton(
                          isLoading: _isLoading,
                          onPressed: _handleSignIn,
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
        'Read today. Recall tomorrow.',
        textAlign: textAlign,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: Colors.white70,
        ),
      ),
      const SizedBox(height: 64),
      GoogleSignInButton(
        isLoading: _isLoading,
        onPressed: _handleSignIn,
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
}
