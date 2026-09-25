import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'state/care_store.dart';
import 'state/store_scope.dart';
import 'ui/screens/home_shell.dart';
import 'ui/screens/onboarding_screen.dart';
import 'ui/theme.dart';

class BatonApp extends StatelessWidget {
  const BatonApp({super.key, required this.store});

  final CareStore store;

  @override
  Widget build(BuildContext context) {
    return StoreScope(
      store: store,
      child: MaterialApp(
        title: 'Baton',
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.light),
        darkTheme: buildTheme(Brightness.dark),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [
          Locale('en', 'US'),
          Locale('en', 'GB'),
          Locale('en', 'CA'),
          Locale('en', 'AU'),
          Locale('en', 'IE'),
          Locale('en', 'NZ'),
          Locale('en'),
        ],
        home: const _RootGate(),
      ),
    );
  }
}

/// Loading → error → onboarding → app.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final store = StoreScope.of(context);
    if (!store.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (store.loadError != null) {
      return Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  "Baton couldn't open its data on this device.",
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: store.load,
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return store.isSetUp ? const HomeShell() : const OnboardingScreen();
  }
}
