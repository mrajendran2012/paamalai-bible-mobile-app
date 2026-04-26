# 0004 — Audio Reader — Tasks

Built incrementally. **v0** is the smallest slice that lets a user pick a
voice and hear a chapter. Items below are split into v0 (in-progress) and
follow-up (tracked, deferred).

## v0 — voice picker + play/pause

- [x] **T1** `flutter_tts` and `app_settings` already in `pubspec.yaml` (added during scaffolding).
- [ ] **T2** `data/audio/tts_prefs_repository.dart` — `TtsPrefs` (speed, voiceName, voiceLocale) over `shared_preferences`. _[FR-AR-06]_
- [ ] **T3** `data/audio/tts_controller.dart` — wraps `flutter_tts`; per-verse utterance queue with completion-driven advance; `playChapter`, `pause`, `stop`, `setVoice`. _[FR-AR-01, FR-AR-06]_
- [ ] **T4** `data/audio/tts_providers.dart` — Riverpod controller + voices-for-locale provider.
- [ ] **T5** Reader settings sheet: "Voice" section listing voices for the active language with `(Female)` / `(Male)` tag where the OS reports it; *Auto* clears the override. _[FR-AR-06]_
- [ ] **T6** Chapter view: play/pause FAB driven by the controller. _[FR-AR-01]_
- [ ] **T7** Tests: `tts_prefs_repository_test.dart` round-trip + defaults.

## Follow-ups (tracked, not in v0)

- [ ] **T8** Verse highlighting + tap-to-seek. _[FR-AR-02]_
- [ ] **T9** Playback controls bar — ±15 s + speed selector + language voice override. _[FR-AR-03]_
- [ ] **T10** `markdown_to_speech.dart` + devotion playback wiring. _[FR-AR-04]_
- [ ] **T11** Voice detection + missing-voice snackbar with system-settings CTA via `app_settings`. _[FR-AR-05]_
- [ ] **T12** Manual matrix test: iOS 17 / 18, Android 13 / 14 / 15, both languages.

## Done when

All FR-AR-* verification rows pass on at least one iOS and one Android
physical device. v0 is "done" when FR-AR-01 + FR-AR-06 pass.
