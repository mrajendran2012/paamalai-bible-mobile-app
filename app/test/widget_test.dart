// Smoke test: the app builds, the router lands on onboarding, and the
// title renders. Does not exercise Supabase (Env.isConfigured guards that).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/app.dart';
import 'package:paamalai/core/providers.dart';
import 'package:paamalai/data/prefs/reader_prefs_repository.dart';
import 'package:paamalai/features/reader/reader_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('app boots and shows onboarding title', (tester) async {
    SharedPreferences.setMockInitialValues({});
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

    expect(find.text('Paamalai'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
