# 0004 — Audio Reader — Tasks

- [ ] **T1** Add `flutter_tts` and `app_settings` to `pubspec.yaml`.
- [ ] **T2** `shared/audio/tts_controller.dart` per `design.md` — per-verse utterance queue with completion-driven advance. _[FR-AR-01]_
- [ ] **T3** `shared/audio/tts_state.dart` — Riverpod state + voice override + speed.
- [ ] **T4** Wire reader chapter view: highlight current verse, tap-to-seek, controls bar. _[FR-AR-02, FR-AR-03]_
- [ ] **T5** `markdown_to_speech.dart` + devotion playback wiring. _[FR-AR-04]_
- [ ] **T6** Voice detection + missing-voice snackbar with system-settings CTA. _[FR-AR-05]_
- [ ] **T7** Manual matrix test: iOS 17 / 18, Android 13 / 14 / 15, both languages. Note any device that fails Tamil (FR-AR-05).

## Done when

All FR-AR-* verification rows pass on at least one iOS and one Android physical device.
