import 'package:flutter/material.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  final bool showAcceptance;
  final VoidCallback? onAccept;

  const TermsAndConditionsScreen({
    super.key,
    this.showAcceptance = false,
    this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontWeight: FontWeight.w800)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(24, 24, 24, showAcceptance ? 120 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Terms and Conditions",
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Prelims Prep — UPSC Current Affairs & Revision App",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Version: 1.0\nLast Updated: May 2026\nDeveloper: Nandu Kishore Bangari\nContact: bangari.nandukishore@gmail.com\nLocation: Hyderabad, Telangana, India",
                  style: TextStyle(color: Colors.grey, height: 1.5, fontWeight: FontWeight.w600),
                ),
                const Divider(height: 40),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: const Text(
                    "By creating an account or signing in to Prelims Prep, you confirm that you have read, understood, and agreed to these Terms and Conditions in their entirety. If you do not agree to any part of these terms, you must not use this App.",
                    style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(height: 32),

                _buildSection(theme, "1. Introduction and Acceptance", 
                  "1.1 These Terms and Conditions (\"Terms\") constitute a legally binding agreement between you (\"User\") and Nandu Kishore Bangari (\"Developer\", \"I\", \"me\") governing your use of the Prelims Prep mobile application (\"App\").\n\n"
                  "1.2 By signing in, registering an account, or otherwise accessing or using the App, you agree to be fully bound by these Terms.\n\n"
                  "1.3 If you are under the age of 18, you must have the consent of a parent or legal guardian to use this App.\n\n"
                  "1.4 These Terms apply to all versions of the App including current and future updates."),
                
                _buildSection(theme, "2. About the App", 
                  "2.1 Prelims Prep is a personal study tool designed to help UPSC Civil Services Examination aspirants by aggregating publicly available current affairs articles and quizzes from third-party educational websites, and providing a spaced repetition revision scheduling system.\n\n"
                  "2.2 The App functions as a content aggregator and reading companion. It does not create, produce, publish, or own any of the study material, articles, or quizzes displayed within it.\n\n"
                  "2.3 The App provides:\n"
                  "• Curated daily links to current affairs articles from third-party sources\n"
                  "• Access to daily quiz links from third-party coaching platforms\n"
                  "• A personal reading tracker and progress monitor\n"
                  "• A spaced repetition revision reminder system\n"
                  "• A distraction-free reading experience via in-app browser and reader mode\n\n"
                  "2.4 The App does not provide:\n"
                  "• Original study content created by the Developer\n"
                  "• Guaranteed or verified accuracy of any third-party content\n"
                  "• Official coaching, mentorship, or guidance\n"
                  "• Any assurance of examination success"),

                _buildSection(theme, "3. User Account and Registration", 
                  "3.1 To use certain features of the App, you must create an account by providing your name and preparation start date.\n\n"
                  "3.2 You are responsible for maintaining the confidentiality of your account credentials and for all activities that occur under your account.\n\n"
                  "3.3 You agree to provide accurate and truthful information during registration and to keep your account information updated.\n\n"
                  "3.4 You may not share your account with any other person. Each account is for individual use only.\n\n"
                  "3.5 The Developer reserves the right to suspend or terminate any account that is found to be shared, misused, or in violation of these Terms.\n\n"
                  "3.6 You may delete your account at any time by contacting the Developer at bangari.nandukishore@gmail.com. Account deletion will remove your personal data but will not entitle you to any refund for any remaining subscription period."),

                _buildSection(theme, "4. Third-Party Content and Sources", 
                  "4.1 The App aggregates content from third-party educational platforms including but not limited to: InsightsIAS, Vajiram & Ravi, VisionIAS, NextIAS, Drishti IAS, Chahal Academy, etc.\n\n"
                  "4.2 The App is not affiliated with, endorsed by, sponsored by, or officially associated with any of the mentioned institutions.\n\n"
                  "4.3 All third-party content remains exclusively owned by the respective third-party sources.\n\n"
                  "4.4 The Developer does not claim any ownership, authorship, or rights over any third-party content accessed through the App.\n\n"
                  "4.5 Third-party content is accessed through Custom Chrome Tabs or an in-app reader and is subject to the terms, conditions, and policies of the respective content owners.\n\n"
                  "4.6 The Developer makes no representations or warranties regarding accuracy, relevance, availability, or completeness of third-party content.\n\n"
                  "4.7 Third-party sources may at any time and without prior notice change their website structure, restrict access, or shut down their platforms entirely.\n\n"
                  "4.8 The Developer will make reasonable efforts to update the App in response to such changes but does not guarantee timely resolution.\n\n"
                  "4.9 If any content owner believes their intellectual property has been used inappropriately, they may contact the Developer at bangari.nandukishore@gmail.com and corrective action will be taken promptly."),

                _buildSection(theme, "5. Subscription Plans and Pricing", 
                  "5.1 The App may offer free and premium access options. Premium access is available through recurring subscriptions at the pricing displayed within the App at the time of purchase.\n\n"
                  "5.2 Additional subscription plans may be introduced in the future.\n\n"
                  "5.3 All prices are inclusive of applicable taxes unless stated otherwise.\n\n"
                  "5.4 The Developer reserves the right to change subscription pricing at any time.\n\n"
                  "5.5 All payments are processed and managed exclusively through Google Play Billing. The Developer does not collect, store, or process any payment card information directly.\n\n"
                  "5.6 By subscribing, you authorize Google Play to charge your associated payment method on a recurring basis.\n\n"
                  "5.7 Subscriptions automatically renew unless cancelled at least 24 hours before the renewal date.\n\n"
                  "5.8 You can manage and cancel your subscription at any time through Google Play Store settings.\n\n"
                  "5.9 Cancellation will take effect at the end of the current billing period."),

                _buildSection(theme, "6. Free Trial", 
                  "6.1 The App may offer a free trial period for new users.\n"
                  "6.2 During the trial, full access to premium features is provided at no charge.\n"
                  "6.3 At the end of the trial, the subscription will automatically convert to a paid plan unless cancelled.\n"
                  "6.4 The Developer reserves the right to modify or discontinue the free trial offer at any time.\n"
                  "6.5 Creating multiple accounts to obtain repeated free trials is a violation of these Terms."),

                _buildSection(theme, "7. Refund Policy", 
                  "7.1 All payments made through the App are strictly non-refundable.\n\n"
                  "7.2 No refunds will be issued for partial use, dissatisfaction with content/features, technical issues, unavailability of third-party content, app removal from store, or account termination.\n\n"
                  "7.3 In the event the App is removed from the Google Play Store, no refunds will be issued for unused portions of active subscriptions.\n\n"
                  "7.4 If a refund is mandated by applicable law, it will be processed through Google Play and limited to the current billing cycle amount.\n\n"
                  "7.5 For payment-related disputes, contact Google Play Support directly."),

                _buildSection(theme, "8. Service Availability", 
                  "8.1 The App is provided on an \"as is\" and \"as available\" basis.\n"
                  "8.2 The Developer does not guarantee that the App will be available at all times, free from bugs, or compatible with all devices.\n"
                  "8.3 The App may be unavailable due to maintenance, infrastructure failures, connectivity issues, Play Store decisions, or legal actions.\n"
                  "8.4 The Developer reserves the right to modify, suspend, or permanently discontinue the App at any time."),

                _buildSection(theme, "9. No Guarantee of Maintenance", 
                  "9.1 Prelims Prep is developed and maintained by an individual developer. It is not a product of a registered company.\n"
                  "9.2 There is no guarantee that the App will be actively maintained, updated for future Android versions, or supported with customer service at all times.\n"
                  "9.3 The Developer may be unable to maintain the App due to personal or professional circumstances, and may discontinue it without notice.\n"
                  "9.4 Features may be removed, modified, or replaced at any time."),

                _buildSection(theme, "10. App Removal from Store", 
                  "10.1 The App may be removed from Google Play Store due to policy violations, copyright complaints, developer decision, or legal action.\n"
                  "10.2 In the event of removal: existing installations may continue to function temporarily, no new users can download the App, and no refunds will be issued.\n"
                  "10.3 The Developer will make reasonable efforts to communicate any planned removal if feasible."),

                _buildSection(theme, "11. User Conduct", 
                  "11.1 You agree not to: use the App for unlawful purposes, reverse engineer it, bypass paywalls, exploit free trials, share accounts, damage functionality, or infringe on intellectual property rights.\n"
                  "11.2 Violation may result in immediate account termination without refund."),

                _buildSection(theme, "12. Intellectual Property", 
                  "12.1 The App's name, logo, UI design, and original features are the intellectual property of the Developer.\n"
                  "12.2 Users may not copy or redistribute any part of the App without written permission.\n"
                  "12.3 Third-party trademarks and content remain the property of their respective owners."),

                _buildSection(theme, "13. Privacy and Data", 
                  "13.1 The App collects basic data: name, start date, reading history, revision progress, and preferences.\n"
                  "13.2 Data is stored securely using Google Firebase/Firestore.\n"
                  "13.3 The Developer does not sell or share personal user data for commercial purposes.\n"
                  "13.4 No sensitive financial or government ID data is collected.\n"
                  "13.5 Third-party services (Firebase, Google Play) have their own privacy policies.\n"
                  "13.6 A separate Privacy Policy governs these practices in detail."),

                _buildSection(theme, "14. Disclaimers", 
                  "14.1 The App is a study aid tool and does not guarantee examination success.\n"
                  "14.2 The Developer is not a coaching institute or examination authority.\n"
                  "14.3 Content accessed is for informational purposes and should not be the sole source of preparation.\n"
                  "14.4 Use is at the user's own risk."),

                _buildSection(theme, "15. Limitation of Liability", 
                  "15.1 The Developer is not liable for data loss, study setbacks, App discontinuation, financial loss from subscription charges, or reliance on third-party content.\n"
                  "15.2 Total liability shall not exceed the amount paid by the user in the preceding three months."),

                _buildSection(theme, "16. Indemnification", 
                  "You agree to indemnify the Developer from any claims arising from your misuse of the App, violation of Terms, or violation of third-party rights."),

                _buildSection(theme, "17. Changes to Terms", 
                  "17.1 The Developer reserves the right to update these Terms at any time.\n"
                  "17.2 Updated Terms will be available within the App.\n"
                  "17.3 Continued use constitutes acceptance of revised Terms."),

                _buildSection(theme, "18. Termination", 
                  "18.1 The Developer may suspend or terminate your account if you violate Terms or if the App is discontinued.\n"
                  "18.2 Upon termination, rights to use the App cease immediately without refund."),

                _buildSection(theme, "19. Governing Law", 
                  "19.1 Governed by the laws of India.\n"
                  "19.2 Disputes are subject to the exclusive jurisdiction of the courts in Hyderabad, Telangana, India.\n"
                  "19.3 Pre-litigation: attempt resolution with the Developer for at least 30 days."),

                _buildSection(theme, "20. Severability", 
                  "If any provision is found invalid, it shall be modified to the minimum extent necessary or severed, while remaining provisions continue in effect."),

                _buildSection(theme, "21. Entire Agreement", 
                  "These Terms and the Privacy Policy constitute the entire agreement regarding the use of the App."),

                _buildSection(theme, "22. Contact Information", 
                  "For questions or complaints:\n"
                  "Developer: Nandu Kishore Bangari\n"
                  "Email: bangari.nandukishore@gmail.com\n"
                  "Location: Hyderabad, Telangana, India"),

                const SizedBox(height: 20),
                const Text(
                  "*By tapping \"I agree to the Terms & Conditions\" or by signing in to Prelims Prep, you acknowledge that you have read this document in full, understood its contents, and agree to be legally bound by these Terms and Conditions.*",
                  style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 12),
                const Text(
                  "© 2026 Nandu Kishore Bangari. All rights reserved.",
                  style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
          if (showAcceptance)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _AcceptanceBar(
                onAccept: () {
                  if (onAccept != null) {
                    onAccept!();
                  } else {
                    Navigator.pop(context, true);
                  }
                },
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSection(ThemeData theme, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

class _AcceptanceBar extends StatefulWidget {
  final VoidCallback? onAccept;
  const _AcceptanceBar({this.onAccept});

  @override
  State<_AcceptanceBar> createState() => _AcceptanceBarState();
}

class _AcceptanceBarState extends State<_AcceptanceBar> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Checkbox(
                value: _agreed,
                onChanged: (val) => setState(() => _agreed = val ?? false),
                activeColor: theme.colorScheme.primary,
              ),
              const Expanded(
                child: Text(
                  "I have read and agree to the Terms & Conditions",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _agreed ? widget.onAccept : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: const Text(
                "CONTINUE",
                style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
