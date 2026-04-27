import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../bible/book.dart';
import 'tts_voice.dart';

/// Playback state surfaced to the UI. v0 is intentionally narrow:
/// `idle` / `playing` / `paused`. Verse highlighting and progress fields
/// land with FR-AR-02 in a follow-up PR.
enum TtsPlaybackState { idle, playing, paused }

/// BCP-47 locale tag for `flutter_tts.setLanguage`.
String localeFor(Lang lang) => lang == Lang.ta ? 'ta-IN' : 'en-US';

/// Thin wrapper around `flutter_tts` that exposes:
///   * a per-verse utterance queue with completion-driven advance,
///   * play / pause / stop,
///   * voice listing for a given locale,
///   * voice override (set via [setVoice], cleared via [clearVoice]).
///
/// Implements FR-AR-01 + FR-AR-06 (v0 slice). The controller is created once
/// per app session via Riverpod and reused across chapter views.
class TtsController {
  TtsController({FlutterTts? tts}) : _tts = tts ?? FlutterTts() {
    _tts.setCompletionHandler(_onUtteranceComplete);
    _tts.setErrorHandler((msg) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('[tts] error: $msg');
      }
      _state = TtsPlaybackState.idle;
      _stateController.add(_state);
    });
  }

  final FlutterTts _tts;
  final _stateController = StreamController<TtsPlaybackState>.broadcast();

  /// One-shot platform setup. Must complete before the first [speak]:
  ///   * iOS audio session category must be `playback` or audio is silently
  ///     routed to nowhere (most common cause of "play does nothing").
  ///   * On Android the TTS engine binds lazily; the first `speak()` can be
  ///     dropped if it fires before the binding completes. Calling a cheap
  ///     query method first (`getLanguages`) forces the bind.
  /// Idempotent — repeated calls are cheap.
  Future<void> _ensureInit() async {
    if (_initialised) return;
    _initialised = true;

    // Use the completion-handler pattern (default). Setting this to `true`
    // would make `speak()` itself await completion, which would deadlock with
    // our pause flow because `pause()` does not resolve an in-flight speak.
    await _tts.awaitSpeakCompletion(false);

    if (defaultTargetPlatform == TargetPlatform.iOS) {
      await _tts.setSharedInstance(true);
      await _tts.setIosAudioCategory(
        IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.duckOthers,
        ],
        IosTextToSpeechAudioMode.spokenAudio,
      );
    }

    // Force engine binding so the first user-initiated speak isn't dropped.
    try {
      await _tts.getLanguages;
    } catch (_) {
      // Web / unsupported platforms — ignore.
    }

    // Set volume + pitch to neutral defaults. Some Android engines come up
    // with attenuated volume which the user perceives as muffled / static-y
    // playback; pinning these guarantees full output level.
    try {
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
    } catch (_) {
      // Some web implementations don't support these — ignore.
    }
  }

  bool _initialised = false;

  Stream<TtsPlaybackState> get stateStream => _stateController.stream;
  TtsPlaybackState get state => _state;
  TtsPlaybackState _state = TtsPlaybackState.idle;

  List<String> _queue = const [];
  int _index = 0;

  /// Voices available for [locale]. Returns an empty list if the platform
  /// reports no voices (web / unsupported). Callers should treat unknown
  /// gender as "Auto"-eligible — see [TtsVoice.gender].
  Future<List<TtsVoice>> voicesFor(String locale) async {
    final raw = await _tts.getVoices;
    if (raw is! List) return const [];
    final out = <TtsVoice>[];
    for (final v in raw) {
      final voice = TtsVoice.tryFromMap(v);
      if (voice == null) continue;
      // Compare on the language prefix so 'en-US' matches both 'en' and 'en-GB'.
      if (_matchesLocale(voice.locale, locale)) out.add(voice);
    }
    out.sort((a, b) {
      // 1. Quality first — premium/enhanced voices are noticeably less
      //    robotic, so the user lands on the best option even if they
      //    don't read the badges.
      final qa = qualityRank(a.quality);
      final qb = qualityRank(b.quality);
      if (qa != qb) return qa.compareTo(qb);
      // 2. Then by gender (F, M, other, unknown).
      final ga = _genderRank(a.gender);
      final gb = _genderRank(b.gender);
      if (ga != gb) return ga.compareTo(gb);
      // 3. Finally alphabetical for stable ordering.
      return a.name.compareTo(b.name);
    });
    return out;
  }

  /// Pin a specific voice. Pass [name]+[locale] or call [clearVoice].
  Future<void> setVoice({required String name, required String locale}) async {
    await _tts.setVoice({'name': name, 'locale': locale});
  }

  Future<void> clearVoice() async {
    // flutter_tts has no explicit "unset voice" API; setting language alone
    // is enough — the platform reverts to the locale's default voice.
  }

  Future<void> setLanguage(Lang lang) async {
    await _tts.setLanguage(localeFor(lang));
  }

  Future<void> setSpeed(double speed) async {
    // flutter_tts speech rate isn't 1.0 = normal across platforms — Android
    // treats 0.5 as "normal", iOS treats ~0.5 as normal too. We map our
    // user-facing 1.0 to 0.5 platform value as a reasonable default.
    await _tts.setSpeechRate(speed * 0.5);
  }

  /// Begins reading [verses] in order. Replaces any in-flight playback.
  Future<void> playChapter({
    required List<Verse> verses,
    required Lang lang,
    String? voiceName,
    String? voiceLocale,
    double speed = 1.0,
  }) async {
    await _ensureInit();
    await _tts.stop();
    await setLanguage(lang);
    await setSpeed(speed);
    final wantedLocale = localeFor(lang);
    if (voiceName != null &&
        voiceLocale != null &&
        _matchesLocale(voiceLocale, wantedLocale)) {
      await setVoice(name: voiceName, locale: voiceLocale);
    }
    _queue = verses.map((v) => v.text).toList(growable: false);
    _index = 0;
    if (_queue.isEmpty) return;
    _state = TtsPlaybackState.playing;
    _stateController.add(_state);
    if (kDebugMode) {
      // ignore: avoid_print
      print('[tts] speak verse ${_index + 1}/${_queue.length}'
          ' lang=$wantedLocale voice=$voiceName');
    }
    await _tts.speak(_queue[_index]);
  }

  Future<void> pause() async {
    if (_state != TtsPlaybackState.playing) return;
    final ok = await _tts.pause();
    if (ok == 1) {
      _state = TtsPlaybackState.paused;
      _stateController.add(_state);
    } else {
      // Some Android engines don't support pause — fall back to stop.
      await stop();
    }
  }

  Future<void> resume() async {
    if (_state != TtsPlaybackState.paused) return;
    if (_index >= _queue.length) {
      _state = TtsPlaybackState.idle;
      _stateController.add(_state);
      return;
    }
    _state = TtsPlaybackState.playing;
    _stateController.add(_state);
    await _tts.speak(_queue[_index]);
  }

  Future<void> stop() async {
    await _tts.stop();
    _state = TtsPlaybackState.idle;
    _stateController.add(_state);
    _queue = const [];
    _index = 0;
  }

  Future<void> dispose() async {
    await _tts.stop();
    await _stateController.close();
  }

  Future<void> _onUtteranceComplete() async {
    _index += 1;
    if (_index < _queue.length && _state == TtsPlaybackState.playing) {
      await _tts.speak(_queue[_index]);
    } else if (_index >= _queue.length) {
      _state = TtsPlaybackState.idle;
      _stateController.add(_state);
    }
  }

  /// Treat 'en' / 'en-US' / 'en_US' / 'en-GB' as compatible — flutter_tts
  /// returns wildly varying locale strings across platforms.
  bool _matchesLocale(String voiceLocale, String wantedLocale) {
    final v = voiceLocale.replaceAll('_', '-').toLowerCase();
    final w = wantedLocale.replaceAll('_', '-').toLowerCase();
    final vPrefix = v.split('-').first;
    final wPrefix = w.split('-').first;
    return vPrefix == wPrefix;
  }

  int _genderRank(TtsGender g) => switch (g) {
        TtsGender.female => 0,
        TtsGender.male => 1,
        TtsGender.other => 2,
        TtsGender.unknown => 3,
      };
}
