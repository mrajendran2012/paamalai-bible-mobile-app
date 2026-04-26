import 'package:flutter/material.dart' as material show ThemeMode;
import 'package:shared_preferences/shared_preferences.dart';

import '../bible/book.dart';

enum FontSize { s, m, l, xl }

extension FontSizeScale on FontSize {
  /// Multiplier applied to the base verse text style.
  double get scale => switch (this) {
        FontSize.s => 0.85,
        FontSize.m => 1.0,
        FontSize.l => 1.20,
        FontSize.xl => 1.45,
      };
}

class ReaderPrefs {
  const ReaderPrefs({
    required this.fontSize,
    required this.themeMode,
    required this.language,
  });

  final FontSize fontSize;
  final material.ThemeMode themeMode;
  final Lang language;

  ReaderPrefs copyWith({
    FontSize? fontSize,
    material.ThemeMode? themeMode,
    Lang? language,
  }) =>
      ReaderPrefs(
        fontSize: fontSize ?? this.fontSize,
        themeMode: themeMode ?? this.themeMode,
        language: language ?? this.language,
      );

  static const ReaderPrefs defaults = ReaderPrefs(
    fontSize: FontSize.m,
    themeMode: material.ThemeMode.system,
    language: Lang.en,
  );
}

/// Wraps [SharedPreferences] for the reader's display + language prefs.
class ReaderPrefsRepository {
  ReaderPrefsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kFontSize = 'reader.fontSize';
  static const _kThemeMode = 'reader.themeMode';
  static const _kLanguage = 'reader.language';

  ReaderPrefs read() {
    return ReaderPrefs(
      fontSize: _readEnum(_kFontSize, FontSize.values, FontSize.m),
      themeMode: _readEnum(
        _kThemeMode,
        material.ThemeMode.values,
        material.ThemeMode.system,
      ),
      language: _readEnum(_kLanguage, Lang.values, Lang.en),
    );
  }

  Future<void> write(ReaderPrefs prefs) async {
    await _prefs.setString(_kFontSize, prefs.fontSize.name);
    await _prefs.setString(_kThemeMode, prefs.themeMode.name);
    await _prefs.setString(_kLanguage, prefs.language.name);
  }

  T _readEnum<T extends Enum>(String key, List<T> values, T fallback) {
    final s = _prefs.getString(key);
    if (s == null) return fallback;
    for (final v in values) {
      if (v.name == s) return v;
    }
    return fallback;
  }
}
