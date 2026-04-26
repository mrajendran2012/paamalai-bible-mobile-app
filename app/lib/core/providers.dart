import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Bound at app start in `main.dart` after `SharedPreferences.getInstance`.
/// Used by repositories that persist to local key-value storage.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (_) => throw StateError('sharedPreferencesProvider not initialised'),
);
