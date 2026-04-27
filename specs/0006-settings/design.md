# 0006 — Settings — Design

## File layout

```
app/lib/features/settings/
└── settings_screen.dart       # Section list: Language + About link
```

No new providers, repository, or models — the screen is purely a UI over
`ReaderPrefsNotifier` (already exposes `setLanguage`).

## Routing

`/settings` lives **inside** the `ShellRoute` so the bottom nav stays visible
while the user adjusts preferences. The `HomeShell` `bottomNavBar` keeps its
three persona-aligned tabs; `/settings` does not get a dedicated tab — it's
reached via a gear icon in `HomeShell`'s `actions` row that's drawn over the
child screen via a `Stack`-less approach (each top-level screen's AppBar adds
the gear icon directly).

```dart
// router.dart — additions
ShellRoute(
  builder: (_, __, child) => HomeShell(child: child),
  routes: [
    GoRoute(path: '/plan', ...),
    GoRoute(path: '/devotion', ...),
    GoRoute(path: '/reader', ...),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
  ],
)
```

`HomeShell.bottomIndexFor` maps `/settings` to no selected tab (returns -1
or ignores it) so none of the three persona tabs lights up while the user is
in settings — visually communicating that settings is "above" the tabs.

## Gear icon placement

The gear lives in the **AppBar of each top-level screen** (Plan, Devotion,
Reader). Adding it once to `HomeShell` would require restructuring the shell
to own the AppBar, which is a wider refactor — the per-screen approach is a
3-line change per screen and consistent with how the Catch-up sub-route
already manages its own AppBar.

```dart
AppBar(
  title: ...,
  actions: [
    IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: lang.t('Settings', 'அமைப்புகள்'),
      onPressed: () => context.go('/settings'),
    ),
    ...existing actions,
  ],
);
```

## Settings screen layout

```
AppBar — back arrow + "Settings" title (bilingual)
ListView
  ┌─────────────────────────────────────┐
  │ LANGUAGE                            │  section header
  │ ┌─────────────────────────────────┐ │
  │ │  ●  English                     │ │  card with two ListTile rows;
  │ │ ───────────────────────────────  │ │  active option marked with a
  │ │  ○  தமிழ்                       │ │  filled radio circle.
  │ └─────────────────────────────────┘ │
  │                                     │
  │ ABOUT                               │  section header
  │ ┌─────────────────────────────────┐ │
  │ │  ⓘ  About & attributions      ›│ │  routes to /about
  │ └─────────────────────────────────┘ │
  └─────────────────────────────────────┘
```

Both cards use the existing app shape language (rounded 12 px, surface
container highest background).

## Tests

`test/settings_screen_test.dart`:

- Pump `MaterialApp.router` with onboarding completed (so `/settings` isn't
  redirected) and language = EN. Navigate to `/settings`. Assert the
  English row shows the filled radio.
- Tap the Tamil row. Pump. Assert:
  - The Tamil row shows the filled radio.
  - The AppBar title now reads `அமைப்புகள்`.
  - `SharedPreferences.getInstance().getString('reader.language')` == `'ta'`.

Existing `onboarding_routing_test` continues to pass — settings is not in
the redirect flow.
