import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app.dart';
import 'core/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ProviderScope(child: PaamalaiApp()));
}
