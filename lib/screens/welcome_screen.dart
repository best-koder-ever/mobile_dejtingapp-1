import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/dev_mode_banner.dart';
import '../theme/app_theme.dart';

/// Welcome Screen — Two clear paths:
/// 1. "I'm ready to match" → registration/onboarding flow
/// 2. "Sign in" → returning user phone entry → home
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AppTheme.brandGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(216),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Flame icon
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_fire_department, color: Colors.white, size: 32),
                      ),
                      const SizedBox(height: 16),

                      Text(
                        l10n.createAccount,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      const SizedBox(height: 16),

                      // Terms text
                      RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          style: const TextStyle(fontSize: 12, color: Colors.white70, height: 1.4),
                          children: [
                            const TextSpan(text: 'By tapping Log In or Continue, you agree to our '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _openUrl('https://dejtingapp.com/terms'),
                                child: Text(l10n.termsLink, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, decoration: TextDecoration.underline)),
                              ),
                            ),
                            const TextSpan(text: '. Learn how we process your data in our '),
                            WidgetSpan(
                              child: GestureDetector(
                                onTap: () => _openUrl('https://dejtingapp.com/privacy'),
                                child: Text(l10n.privacyPolicyLink, style: const TextStyle(fontSize: 12, color: AppTheme.primaryColor, decoration: TextDecoration.underline)),
                              ),
                            ),
                            const TextSpan(text: '.'),
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // PRIMARY CTA — "I'm ready to match" → registration/onboarding
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                            elevation: 2,
                          ),
                          child: Text(
                            l10n.readyToMatch,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // SECONDARY — "Sign in" → returning user phone entry
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/signin/phone-entry'),
                        child: Text(
                          l10n.signInButton,
                          style: const TextStyle(
                            color: AppTheme.primaryColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // DevMode skip — jump straight into onboarding flow
              DevModeSkipButton(
                onSkip: () => Navigator.pushNamed(context, '/onboarding/phone-entry'),
                label: 'Skip to Onboarding',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openUrl(String urlString) async {
    final url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }
}
