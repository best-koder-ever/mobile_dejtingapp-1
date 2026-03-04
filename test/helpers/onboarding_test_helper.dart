import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';
import 'package:dejtingapp/models/onboarding_data.dart';
import 'package:dejtingapp/providers/onboarding_provider.dart';

/// Helper to wrap a wizard screen for widget testing.
///
/// Provides [OnboardingProvider], sets route name for progress/goNext,
/// and registers dummy next-route so Navigator.pushNamed doesn't crash.
Widget buildOnboardingTestHarness({
  required Widget screen,
  required String routeName,
  OnboardingData? data,
  Map<String, WidgetBuilder>? extraRoutes,
}) {
  final onboardingData = data ?? OnboardingData();

  final routes = <String, WidgetBuilder>{
    '/onboarding/phone-entry': (_) => const Scaffold(body: Text('phone-entry')),
    '/onboarding/verify-code': (_) => const Scaffold(body: Text('verify-code')),
    '/onboarding/community-guidelines': (_) =>
        const Scaffold(body: Text('community-guidelines')),
    '/onboarding/first-name': (_) => const Scaffold(body: Text('first-name')),
    '/onboarding/birthday': (_) => const Scaffold(body: Text('birthday')),
    '/onboarding/gender': (_) => const Scaffold(body: Text('gender')),
    '/onboarding/orientation': (_) => const Scaffold(body: Text('orientation')),
    '/onboarding/match-preferences': (_) =>
        const Scaffold(body: Text('match-preferences')),
    '/onboarding/age-range': (_) => const Scaffold(body: Text('age-range')),
    '/onboarding/relationship-goals': (_) =>
        const Scaffold(body: Text('relationship-goals')),
    '/onboarding/lifestyle': (_) => const Scaffold(body: Text('lifestyle')),
    '/onboarding/interests': (_) => const Scaffold(body: Text('interests')),
    '/onboarding/about-me': (_) => const Scaffold(body: Text('about-me')),
    '/onboarding/photos': (_) => const Scaffold(body: Text('photos')),
    '/onboarding/location': (_) => const Scaffold(body: Text('location')),
    '/onboarding/notifications': (_) =>
        const Scaffold(body: Text('notifications')),
    '/onboarding/complete': (_) => const Scaffold(body: Text('complete')),
    '/welcome': (_) => const Scaffold(body: Text('welcome')),
    ...?extraRoutes,
  };

  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    onGenerateRoute: (settings) {
      if (settings.name == routeName || settings.name == '/') {
        return MaterialPageRoute(
          settings: RouteSettings(name: routeName),
          builder: (_) => OnboardingProvider(
            data: onboardingData,
            child: screen,
          ),
        );
      }
      final builder = routes[settings.name];
      if (builder != null) {
        return MaterialPageRoute(
          settings: settings,
          builder: (ctx) => OnboardingProvider(
            data: onboardingData,
            child: builder(ctx),
          ),
        );
      }
      return null;
    },
    initialRoute: routeName,
  );
}
