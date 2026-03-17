import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dejtingapp/l10n/generated/app_localizations.dart';

/// Wraps a core app screen for widget testing.
/// Provides localization and dummy routes for navigation.
Widget buildCoreScreenTestApp({
  required Widget home,
  Map<String, WidgetBuilder>? extraRoutes,
}) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    theme: ThemeData.dark(),
    home: home,
    routes: {
      '/welcome': (_) => const Scaffold(body: Text('Welcome')),
      '/onboarding/phone': (_) => const Scaffold(body: Text('Phone')),
      '/login': (_) => const Scaffold(body: Text('Login')),
      '/home': (_) => const Scaffold(body: Text('Home')),
      '/matches': (_) => const Scaffold(body: Text('Matches')),
      '/chat': (_) => const Scaffold(body: Text('Chat')),
      '/profile': (_) => const Scaffold(body: Text('Profile')),
      '/settings': (_) => const Scaffold(body: Text('Settings')),
      '/profile/detail': (_) => const Scaffold(body: Text('Profile Detail')),
      '/profile/edit': (_) => const Scaffold(body: Text('Edit Profile')),
      ...?extraRoutes,
    },
  );
}

/// Prevents any real HTTP requests in tests.
/// Returns a transparent 1x1 PNG for image requests.
class _TestHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (_, __, ___) => true;
  }
}

void setupTestHttpOverrides() {
  HttpOverrides.global = _TestHttpOverrides();
}
