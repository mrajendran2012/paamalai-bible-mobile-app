# 0004 — Audio Reader — Design

## Architecture

```
shared/audio/
   tts_controller.dart        # wraps flutter_tts; splits content into per-verse utterances
   tts_state.dart             # Riverpod state: playing, currentVerseIndex, speed
   tts_prefs.dart             # shared_preferences persistence

features/reader/chapter_view.dart    # consumes TtsController, highlights current verse
features/devotion/devotion_screen.dart  # ditto, with Markdown-stripped body
```

## Why per-verse utterances

`flutter_tts` `speak()` accepts a single string. To get reliable verse-level progress events across iOS and Android, we **enqueue one utterance per verse** and rely on `setCompletionHandler` firing per utterance to advance the `currentVerseIndex`.

```dart
class TtsController {
  Future<void> playChapter(List<Verse> verses, {required String langCode}) async {
    await _tts.setLanguage(langCode);
    await _tts.setSpeechRate(_prefs.speed);
    _queue = verses;
    _index = 0;
    await _speakNext();
  }

  Future<void> _speakNext() async {
    if (_index >= _queue.length) return;
    _state.setCurrentVerse(_queue[_index].number);
    await _tts.speak(_queue[_index].text);
    // _completionHandler bumps _index and recurses.
  }

  Future<void> seekToVerse(int verseNumber) async {
    await _tts.stop();
    _index = _queue.indexWhere((v) => v.number == verseNumber);
    await _speakNext();
  }

  Future<void> skipSeconds(int delta) async {
    final jump = (delta / _avgSecondsPerVerse).round();
    await seekToVerse(_queue[(_index + jump).clamp(0, _queue.length - 1)].number);
  }
}
```

`_avgSecondsPerVerse` defaults to 12 and updates via EMA based on observed completion deltas.

## Devotion playback (FR-AR-04)

The devotion body is Markdown. Strip to plain text via a small `markdown_to_speech.dart` helper that removes headings (read once as a header line), pray/reflect labels, and converts list bullets to pauses. Then enqueue one utterance per paragraph (or per question in the Reflect list).

## Tamil voice detection (FR-AR-05)

```dart
final voices = await _tts.getVoices;
final hasTamil = voices.any((v) => v['locale']?.toString().startsWith('ta') == true);
```

If `hasTamil == false` and the user requests Tamil playback, raise a `TtsVoiceMissingException` and let the UI render a snackbar with a *Settings* CTA (`AppSettings.openTTSSettings()` via `app_settings` package).
