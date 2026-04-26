/// Lightweight, platform-neutral descriptor for a device TTS voice.
///
/// `flutter_tts` returns voices as `Map<String, String>` (or sometimes
/// `Map<dynamic, dynamic>` on Android) with at least `name` + `locale`. iOS 17+
/// adds `gender` ('female' / 'male'); some Android engines surface gender via
/// `features` or a `gender` key. We normalise that into [TtsGender] so the UI
/// can render a tag without re-doing the platform sniffing.
enum TtsGender { female, male, other, unknown }

class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    required this.gender,
  });

  final String name;
  final String locale;
  final TtsGender gender;

  /// Best-effort parse of the `Map` shapes returned by `flutter_tts`.
  /// Unknown / non-string values simply fall through to defaults.
  static TtsVoice? tryFromMap(Object? raw) {
    if (raw is! Map) return null;
    final name = raw['name']?.toString();
    final locale = raw['locale']?.toString();
    if (name == null || locale == null) return null;
    return TtsVoice(
      name: name,
      locale: locale,
      gender: _parseGender(raw),
    );
  }

  static TtsGender _parseGender(Map<dynamic, dynamic> raw) {
    final tag = raw['gender']?.toString().toLowerCase();
    if (tag != null) {
      if (tag.contains('female')) return TtsGender.female;
      if (tag.contains('male')) return TtsGender.male;
      if (tag.isNotEmpty) return TtsGender.other;
    }
    // Android sometimes lists gender in `features`.
    final features = raw['features'];
    if (features is List) {
      final joined =
          features.map((f) => f.toString().toLowerCase()).join(',');
      if (joined.contains('female')) return TtsGender.female;
      if (joined.contains('male')) return TtsGender.male;
    }
    return TtsGender.unknown;
  }
}
