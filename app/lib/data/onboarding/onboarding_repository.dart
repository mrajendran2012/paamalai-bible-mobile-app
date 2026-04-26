import 'package:shared_preferences/shared_preferences.dart';

/// Which feature(s) the user opted into during onboarding.
///
/// Persisted as their `name` (`'yearly'` / `'devotion'`).
enum Persona { yearly, devotion }

/// Local-only persistence for the onboarding completion flag, persona
/// selection, and interest tags. The chosen reading language is owned by
/// [ReaderPrefsRepository] (shared with the Reader) and is not duplicated here.
///
/// Implements FR-ON-04 (mark complete) and FR-ON-05 (skip once completed).
class OnboardingRepository {
  OnboardingRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kCompleted = 'onboarding.completed';
  static const _kPersonas = 'onboarding.personas';
  static const _kInterests = 'onboarding.interests';

  bool get isCompleted => _prefs.getBool(_kCompleted) ?? false;

  Set<Persona> get personas {
    final list = _prefs.getStringList(_kPersonas) ?? const [];
    return {
      for (final s in list)
        for (final p in Persona.values)
          if (p.name == s) p,
    };
  }

  Set<String> get interests {
    return (_prefs.getStringList(_kInterests) ?? const []).toSet();
  }

  /// Persists the user's choices and flips the completed flag. Idempotent.
  Future<void> finish({
    required Set<Persona> personas,
    required Set<String> interests,
  }) async {
    await _prefs.setStringList(
      _kPersonas,
      personas.map((p) => p.name).toList(),
    );
    await _prefs.setStringList(_kInterests, interests.toList());
    await _prefs.setBool(_kCompleted, true);
  }

  /// Wipes onboarding state. Debug-only; not exposed in UI v0.
  Future<void> reset() async {
    await _prefs.remove(_kCompleted);
    await _prefs.remove(_kPersonas);
    await _prefs.remove(_kInterests);
  }
}
