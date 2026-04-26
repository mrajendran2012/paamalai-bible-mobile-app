import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/app.dart';
import 'package:paamalai/core/providers.dart';
import 'package:paamalai/data/onboarding/onboarding_repository.dart';
import 'package:paamalai/data/prefs/reader_prefs_repository.dart';
import 'package:paamalai/features/reader/reader_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(WidgetTester tester) async {
  final sharedPrefs = await SharedPreferences.getInstance();
  final prefsRepo = ReaderPrefsRepository(sharedPrefs);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        prefsRepositoryProvider.overrideWithValue(prefsRepo),
        initialReaderPrefsProvider.overrideWithValue(prefsRepo.read()),
      ],
      child: const PaamalaiApp(),
    ),
  );
  await tester.pumpAndSettle(const Duration(seconds: 1));
}

void main() {
  testWidgets(
    'fresh install lands on onboarding (FR-ON-01)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      await _pumpApp(tester);

      // Onboarding step 1 prompt is visible.
      expect(find.text('Choose your language'), findsOneWidget);
      // Bottom nav from HomeShell should NOT be present.
      expect(find.byType(NavigationBar), findsNothing);
    },
  );

  testWidgets(
    'completed onboarding with yearly persona lands on /plan (FR-ON-04, FR-ON-05)',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = OnboardingRepository(prefs);
      await repo.finish(
        personas: {Persona.yearly},
        interests: const {},
      );

      await _pumpApp(tester);

      // Plan screen header.
      expect(find.text("Today's Plan"), findsOneWidget);
      expect(find.text('Choose your language'), findsNothing);
      // HomeShell with bottom nav is rendered.
      expect(find.byType(NavigationBar), findsOneWidget);
    },
  );

  testWidgets(
    'completed onboarding with devotion-only lands on /devotion',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final repo = OnboardingRepository(prefs);
      await repo.finish(
        personas: {Persona.devotion},
        interests: {'hope'},
      );

      await _pumpApp(tester);

      expect(find.text('Today’s Devotion'), findsOneWidget);
    },
  );
}
