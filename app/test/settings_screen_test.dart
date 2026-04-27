import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/app.dart';
import 'package:paamalai/core/providers.dart';
import 'package:paamalai/data/onboarding/onboarding_repository.dart';
import 'package:paamalai/data/prefs/reader_prefs_repository.dart';
import 'package:paamalai/features/reader/reader_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> _bootApp(
  WidgetTester tester, {
  required Set<Persona> personas,
}) async {
  SharedPreferences.setMockInitialValues({});
  final prefs = await SharedPreferences.getInstance();
  // Skip onboarding so the router redirect doesn't bounce us off /settings.
  await OnboardingRepository(prefs).finish(
    personas: personas,
    interests: const {},
  );

  final readerPrefsRepo = ReaderPrefsRepository(prefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        prefsRepositoryProvider.overrideWithValue(readerPrefsRepo),
        initialReaderPrefsProvider.overrideWithValue(readerPrefsRepo.read()),
      ],
      child: const PaamalaiApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
  return prefs;
}

void main() {
  testWidgets(
    'tap settings gear → land on settings → tap Tamil → AppBar flips, language persists',
    (tester) async {
      final prefs =
          await _bootApp(tester, personas: {Persona.yearly});

      // Plan tab is the default landing for the yearly persona; gear should
      // be present in its AppBar.
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
      // English is the default language; the radio for 'English' should be
      // checked, Tamil should not.
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('தமிழ்'), findsOneWidget);

      await tester.tap(find.text('தமிழ்'));
      await tester.pumpAndSettle();

      // AppBar title now Tamil.
      expect(find.text('அமைப்புகள்'), findsOneWidget);
      // ReaderPrefs persisted.
      expect(prefs.getString('reader.language'), 'ta');
    },
  );

  testWidgets(
    'settings reachable from Devotion tab (devotion-only persona)',
    (tester) async {
      await _bootApp(tester, personas: {Persona.devotion});

      // Devotion tab is the default landing here.
      expect(find.text('Today’s Devotion'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      await tester.tap(find.byIcon(Icons.settings_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Settings'), findsOneWidget);
    },
  );
}
