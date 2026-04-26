# 0004 — Audio Reader (TTS)

## Context

Persona P3 wants to listen rather than read — while commuting, exercising, doing chores. We use **device-native** TTS (no cloud, no extra cost) for both Bible chapters and devotions, in the user's preferred language.

## Personas

P3 (Listener), cross-cutting P1 + P2.

## Functional requirements

### FR-AR-01 — Play any chapter
- *As a* listener *I want* to tap play on a chapter *so that* it reads to me.
- **Given** the user is in a chapter, **When** they tap play, **Then** TTS reads verses in order using the device voice for the current language (`en-US` for WEB, `ta-IN` for Tamil).

### FR-AR-02 — Verse highlighting
- **Given** TTS is playing, **Then** the currently-spoken verse is visually highlighted; tapping any verse seeks playback to it.

### FR-AR-03 — Playback controls
- Play / pause; ±15 s; speed (0.75× / 1× / 1.25× / 1.5×); language voice override (e.g. let a Tamil reader play the English text in `en-US`).

### FR-AR-04 — Devotion playback
- The same playback controls work on the devotion screen (FR-DD body content, with Markdown stripped).

### FR-AR-05 — Tamil device support detection
- **Given** the device lacks an installed `ta-IN` TTS voice, **When** the user attempts Tamil playback, **Then** they see a non-blocking notice ("Tamil voice isn't installed on this device — open system settings to add one") instead of silent failure.

## Non-functional

- TTS interactions must remain available offline (covered by NFR-OFFLINE; device TTS is local on both platforms).
- Inherits NFR-A11Y — playback controls are minimum 44 pt tap targets, screen-reader-labeled.

## Data contracts

No new tables. Per-user playback prefs (last speed, voice override) live in `shared_preferences`:

```dart
class TtsPrefs {
  double speed;             // 0.75 | 1.0 | 1.25 | 1.5
  String? voiceOverride;    // null = use language default
}
```

## Out of scope

- Background audio (lock screen controls, audio focus on a phone call). Deferred — would need `audio_service` integration.
- Sleep timer.
- Custom voice download UI; we just point users to system settings.
- Pre-recorded human-narrated audio Bible.

## Risks

- **Tamil TTS gap on some Android OEMs** — surfaced via FR-AR-05.
- **Verse-boundary highlighting accuracy** depends on `flutter_tts` `setProgressHandler` granularity; on some Androids it fires per-utterance, not per-word. We split each chapter into per-verse utterances so the handler fires at verse boundaries reliably.

## Verification

| ID | Test |
|----|------|
| FR-AR-01 | Open Genesis 1 in Tamil → tap play → hear Tamil voice. Open John 3 in English → tap play → hear English voice. |
| FR-AR-02 | While playing, the highlighted verse advances in lockstep; tapping verse 7 jumps playback to verse 7. |
| FR-AR-03 | Play / pause, ±15 s, 1.5× speed all behave as expected; voice override changes voice mid-utterance. |
| FR-AR-04 | Open today's devotion → play → hear Markdown-stripped body. |
| FR-AR-05 | On an Android emulator without Tamil TTS installed, attempting Tamil playback shows the "voice not installed" notice. |
