import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';
import 'core/providers.dart';
import 'data/prefs/reader_prefs_repository.dart';
import 'features/reader/reader_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load date-format symbols for both supported locales so Plan / Catch-up
  // can render localized weekday + month names without per-screen await.
  await initializeDateFormatting('en');
  await initializeDateFormatting('ta');

  if (Env.isConfigured) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } else if (kDebugMode) {
    debugPrint(
      'paamalai: SUPABASE_URL / SUPABASE_ANON_KEY not set via --dart-define; '
      'running with backend disabled.',
    );
  }

  final sharedPrefs = await SharedPreferences.getInstance();
  final prefsRepo = ReaderPrefsRepository(sharedPrefs);
  final initialPrefs = prefsRepo.read();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        prefsRepositoryProvider.overrideWithValue(prefsRepo),
        initialReaderPrefsProvider.overrideWithValue(initialPrefs),
      ],
      child: const PaamalaiApp(),
    ),
  );
}
