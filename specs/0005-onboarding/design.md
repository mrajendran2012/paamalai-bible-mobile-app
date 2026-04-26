# 0005 — Onboarding — Design

## File layout

```
app/lib/
├── data/
│   └── onboarding/
│       ├── onboarding_repository.dart   # SharedPreferences I/O for onboarding flags
│       └── interest_tags.dart           # canonical tag codes + EN/TA labels
└── features/
    └── onboarding/
        ├── onboarding_screen.dart       # PageView host, navigation, "Done" wiring
        ├── onboarding_providers.dart    # Riverpod state for in-progress selections
        └── steps/
            ├── language_step.dart       # FR-ON-01
            ├── persona_step.dart        # FR-ON-02
            └── interests_step.dart      # FR-ON-03 (skipped if devotion off)
```

## State model

```dart
enum Persona { yearly, devotion }

class OnboardingDraft {
  final Lang language;
  final Set<Persona> personas;     // both default-on
  final Set<String> interests;     // tag codes
}
```

Held in a `Notifier<OnboardingDraft>` provider seeded with `(language: ReaderPrefs.language, personas: {yearly, devotion}, interests: {})`. Writes happen on every selection so the user can hop between steps without losing partial input.

`OnboardingDraft.canFinish`:
- `personas.isNotEmpty`
- if `personas.contains(devotion)` then `interests.isNotEmpty`

## Persistence

`OnboardingRepository(SharedPreferences)`:

```dart
bool get isCompleted;
Set<Persona> get personas;
Set<String> get interests;

Future<void> finish({
  required Set<Persona> personas,
  required Set<String> interests,
});

Future<void> reset();           // debug only; not exposed in UI v0
```

Persona codes serialize as `'yearly' | 'devotion'`; interests as their stable English snake_case codes. Storage keys: `onboarding.completed`, `onboarding.personas`, `onboarding.interests`.

Language is **not** owned by this repo — it goes through `ReaderPrefsNotifier.setLanguage` so the existing reader UI stays in sync the moment the user picks on step 1.

## Routing

`router.dart` gains a `redirect` that runs on every navigation:

```dart
GoRouter(
  initialLocation: '/onboarding',
  redirect: (ctx, state) {
    final completed = ref.read(onboardingRepositoryProvider).isCompleted;
    final going = state.matchedLocation;
    if (!completed && going != '/onboarding') return '/onboarding';
    if (completed && going == '/onboarding') return _homeFor(ref);
    return null;
  },
  ...
)
```

`_homeFor(ref)` reads stored personas: yearly → `/plan`, else devotion → `/devotion`, else `/reader`. The same helper drives the *Done* button's post-onboarding navigation so both paths agree.

The repository is a synchronous read (SharedPreferences is already loaded at `main()` time before `runApp`), so the redirect is a plain function — no async navigation flicker.

## Step screens

### LanguageStep (FR-ON-01)
Two big tappable cards: **English** and **தமிழ்**, with the EN card pre-selected. Tapping a card calls `ReaderPrefsNotifier.setLanguage(...)`, then the user taps *Continue* to advance. The choice is persisted at tap time, not at *Continue* time, so a later-step rebuild already shows TA strings if the user picked TA.

### PersonaStep (FR-ON-02)
Two switch tiles. *Continue* is disabled while both are off. Default state: both on.

### InterestsStep (FR-ON-03)
Wrap of `FilterChip`s, one per tag in the canonical order. Localized label via the active language. *Done* disabled until ≥1 chip selected. Skipped entirely if `devotion` not in personas — `_steps` getter on the screen returns 2 pages instead of 3.

## Interest tags (≥20 starter set)

Codes are English snake_case and stable. Initial set (≥20 to satisfy FR-ON-03; exact list in `interest_tags.dart`):

```
anxiety, marriage, parenting, work, identity, purpose, grief, finances,
forgiveness, doubt, suffering, gratitude, leadership, friendship,
loneliness, addiction, sickness, anger, hope, justice, prayer, fasting
```

22 tags. Tamil labels seeded by project owner; flagged `// TODO: native-speaker review` per spec §Risks.

## Tests

`test/onboarding_repository_test.dart`
- Round-trip personas + interests through SharedPreferences mock.
- `isCompleted` flips false→true after `finish()`.
- `reset()` clears all three keys.

`test/onboarding_routing_test.dart` (widget test)
- Fresh prefs → first-frame route is `/onboarding`.
- After calling `finish(...)` and pumping → route lands on `/plan` (yearly path) or `/devotion` (devotion-only path).
- Manually navigating to `/onboarding` after completion → redirects to the home tab.

The existing `widget_test.dart` smoke test continues to expect onboarding on a fresh install — no change needed.

## Out of scope (this feature)

- Anonymous Supabase sign-in (FR-ON-06) — deferred to 0003.
- Settings-based language/interest editing — deferred.
- Localized strings for the rest of the app shell — deferred until a third language motivates ARB.
