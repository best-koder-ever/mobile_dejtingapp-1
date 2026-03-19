import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dejtingapp/screens/account_consent_screen.dart';
import '../helpers/core_screen_test_helper.dart';

void main() {
  group('AccountConsentScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('shows app branding', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.local_fire_department), findsOneWidget);
      expect(find.text('DejTing'), findsOneWidget);
    });

    testWidgets('consent text is displayed', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      // The legal consent text links appear in both the RichText body and footer
      final hasConsentText =
          find
                  .textContaining('integritetspolicyn', findRichText: true)
                  .evaluate()
                  .isNotEmpty ||
              find
                  .textContaining('privacy policy', findRichText: true)
                  .evaluate()
                  .isNotEmpty;
      expect(hasConsentText, isTrue);
      final hasTermsText =
          find
                  .textContaining('användarvillkoren', findRichText: true)
                  .evaluate()
                  .isNotEmpty ||
              find
                  .textContaining('terms of use', findRichText: true)
                  .evaluate()
                  .isNotEmpty;
      expect(hasTermsText, isTrue);
    });

    testWidgets('continue (agree) button is present and tappable',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
          extraRoutes: {
            '/onboarding/phone-entry': (_) =>
                const Scaffold(body: Text('phone-entry')),
          },
        ),
      );
      await tester.pumpAndSettle();
      // Swedish default: 'Fortsätt'; English: 'Continue'
      final continueButton =
          find.text('Fortsätt').evaluate().isNotEmpty
              ? find.text('Fortsätt')
              : find.text('Continue');
      expect(continueButton, findsOneWidget);
      await tester.tap(continueButton);
      await tester.pumpAndSettle();
      expect(find.text('phone-entry'), findsOneWidget);
    });

    testWidgets('decline / use another account button is present',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      // Swedish default: 'Använd ett annat konto'; English: 'Use another account'
      final hasDeclineButton =
          find.text('Använd ett annat konto').evaluate().isNotEmpty ||
              find.text('Use another account').evaluate().isNotEmpty;
      expect(hasDeclineButton, isTrue);
      expect(find.byType(OutlinedButton), findsOneWidget);
    });

    testWidgets('shows user name and email in account card', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(
            authProvider: 'google',
            userName: 'Jane Doe',
            userEmail: 'jane@example.com',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Jane Doe'), findsOneWidget);
      expect(find.text('jane@example.com'), findsOneWidget);
    });

    testWidgets('shows default user placeholder when no name provided',
        (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'phone'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('User'), findsOneWidget);
    });

    testWidgets('language dropdown is present', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('switching language to English updates UI text', (tester) async {
      await tester.pumpWidget(
        buildCoreScreenTestApp(
          home: const AccountConsentScreen(authProvider: 'google'),
        ),
      );
      await tester.pumpAndSettle();
      // Default is Swedish
      expect(find.text('Fortsätt'), findsOneWidget);

      // Open the language dropdown and select English
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('🇬🇧 English').last);
      await tester.pumpAndSettle();

      // UI should now show English text
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Use another account'), findsOneWidget);
    });
  });
}
