/// Lightweight, platform-neutral descriptor for a device TTS voice.
///
/// `flutter_tts` returns voices as `Map<String, String>` (or sometimes
/// `Map<dynamic, dynamic>` on Android) with at least `name` + `locale`. We
/// normalise gender + quality into our own enums so the UI can render tags
/// without re-doing the platform sniffing.
enum TtsGender { female, male, other, unknown }

/// Quality bucket inferred from per-platform metadata. Higher = better
/// audio fidelity; users will hear noticeably less static / robotic
/// artifacts on `enhanced` and `premium` voices.
///
/// Mapping rules:
///   * iOS exposes `quality: 'default' | 'enhanced' | 'premium'` directly.
///   * Android exposes `networkConnectionRequired: 'true' | 'false'` —
///     Network voices are Google's neural ones (high quality). Some engines
///     also expose a numeric `quality` key (300 = very low, 500 = normal,
///     400 = high, 500/600 = very high). We bucket those.
enum TtsQuality { premium, enhanced, network, standard, lowLatency, unknown }

class TtsVoice {
  const TtsVoice({
    required this.name,
    required this.locale,
    required this.gender,
    required this.quality,
  });

  final String name;
  final String locale;
  final TtsGender gender;
  final TtsQuality quality;

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
      quality: _parseQuality(raw),
    );
  }

  static TtsGender _parseGender(Map<dynamic, dynamic> raw) {
    final tag = raw['gender']?.toString().toLowerCase();
    if (tag != null) {
      if (tag.contains('female')) return TtsGender.female;
      if (tag.contains('male')) return TtsGender.male;
      if (tag.isNotEmpty) return TtsGender.other;
    }
    final features = raw['features'];
    if (features is List) {
      final joined =
          features.map((f) => f.toString().toLowerCase()).join(',');
      if (joined.contains('female')) return TtsGender.female;
      if (joined.contains('male')) return TtsGender.male;
    }
    return TtsGender.unknown;
  }

  static TtsQuality _parseQuality(Map<dynamic, dynamic> raw) {
    // iOS: `quality` is a string we can read directly.
    final q = raw['quality']?.toString().toLowerCase();
    if (q != null) {
      if (q.contains('premium')) return TtsQuality.premium;
      if (q.contains('enhanced')) return TtsQuality.enhanced;
      if (q.contains('default') || q == 'standard') return TtsQuality.standard;
      // Some Android engines emit an int as a string ('400', '500', ...).
      final n = int.tryParse(q);
      if (n != null) {
        if (n >= 500) return TtsQuality.enhanced;
        if (n >= 400) return TtsQuality.standard;
        return TtsQuality.lowLatency;
      }
    }
    // Android Google TTS: `networkConnectionRequired` flags neural voices.
    final network = raw['networkConnectionRequired']?.toString().toLowerCase();
    if (network == 'true') return TtsQuality.network;

    // Heuristic on voice name as a last resort. Some engines name premium
    // voices with hints like "(Enhanced)" or "Neural" or "WaveNet".
    final nameLc = raw['name']?.toString().toLowerCase() ?? '';
    if (nameLc.contains('premium')) return TtsQuality.premium;
    if (nameLc.contains('enhanced') || nameLc.contains('neural') ||
        nameLc.contains('wavenet')) {
      return TtsQuality.enhanced;
    }
    if (nameLc.contains('compact') || nameLc.contains('-language')) {
      // iOS "-language" voices are the small, low-quality compact ones.
      return TtsQuality.lowLatency;
    }
    return TtsQuality.unknown;
  }
}

/// Lower number = higher quality. Used to sort the picker so the best voice
/// is at the top and "Auto"-leaning users land on something good.
int qualityRank(TtsQuality q) => switch (q) {
      TtsQuality.premium => 0,
      TtsQuality.enhanced => 1,
      TtsQuality.network => 2,
      TtsQuality.standard => 3,
      TtsQuality.unknown => 4,
      TtsQuality.lowLatency => 5,
    };
