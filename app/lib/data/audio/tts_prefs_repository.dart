import 'package:shared_preferences/shared_preferences.dart';

/// Per-user TTS preferences. v0 persists `voiceName` + `voiceLocale` (the
/// locale is pinned alongside the name so that switching reading language
/// can ignore an override that no longer matches). `speed` is stored but the
/// in-app slider is deferred to a follow-up — see specs/0004-audio-reader.
class TtsPrefs {
  const TtsPrefs({
    required this.speed,
    required this.voiceName,
    required this.voiceLocale,
  });

  final double speed; // 0.75 | 1.0 | 1.25 | 1.5
  final String? voiceName;
  final String? voiceLocale;

  static const TtsPrefs defaults = TtsPrefs(
    speed: 1.0,
    voiceName: null,
    voiceLocale: null,
  );

  TtsPrefs copyWith({
    double? speed,
    String? voiceName,
    String? voiceLocale,
    bool clearVoice = false,
  }) =>
      TtsPrefs(
        speed: speed ?? this.speed,
        voiceName: clearVoice ? null : (voiceName ?? this.voiceName),
        voiceLocale: clearVoice ? null : (voiceLocale ?? this.voiceLocale),
      );
}

class TtsPrefsRepository {
  TtsPrefsRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kSpeed = 'tts.speed';
  static const _kVoiceName = 'tts.voiceName';
  static const _kVoiceLocale = 'tts.voiceLocale';

  TtsPrefs read() {
    return TtsPrefs(
      speed: _prefs.getDouble(_kSpeed) ?? 1.0,
      voiceName: _prefs.getString(_kVoiceName),
      voiceLocale: _prefs.getString(_kVoiceLocale),
    );
  }

  Future<void> write(TtsPrefs prefs) async {
    await _prefs.setDouble(_kSpeed, prefs.speed);
    if (prefs.voiceName == null) {
      await _prefs.remove(_kVoiceName);
    } else {
      await _prefs.setString(_kVoiceName, prefs.voiceName!);
    }
    if (prefs.voiceLocale == null) {
      await _prefs.remove(_kVoiceLocale);
    } else {
      await _prefs.setString(_kVoiceLocale, prefs.voiceLocale!);
    }
  }
}
