# 0005 — Onboarding

## Context

The master spec defines onboarding inline (FR-ON-01..05). This per-feature spec is the working copy that drives implementation. Onboarding runs once on first launch and configures three things that the rest of the app depends on:

1. **Language** — controls UI strings and the default Bible translation. Read elsewhere as `ReaderPrefs.language`.
2. **Personas** — which features the user wants on (yearly plan, daily devotion). Drives the post-onboarding landing tab and gates the interests step.
3. **Interest tags** — required by Daily Devotion (FR-DD-01); collected here so 0003 has data to consume.

Anonymous Supabase auth (FR-ON-04, FR-ON-05) is **scoped out of v0** of this feature: the local Supabase stack is not yet running, and onboarding does not write any cross-device state. The screen will silently call `signInAnonymously()` once Supabase is configured, but that wiring lands with feature 0003 (Daily Devotion), which is the first feature that actually needs an authenticated user.

## Personas

All three (P1 Yearly Reader, P2 Devotional Reader, P3 Listener) pass through this screen on first launch. After v0 it should never be shown again unless the user explicitly resets.

## Functional requirements

### FR-ON-01 — Language selection on first launch
- *As a* new user *I want* to pick English or Tamil up front *so that* the app meets me in my language from the first screen.
- **Given** a fresh install, **When** the app launches, **Then** the very first screen is a language picker (English / Tamil); choice is persisted via `ReaderPrefsRepository`.
- The picker is non-skippable; English is the default highlight. The choice can be changed later from settings (master FR-ST-01) — out of scope here.

### FR-ON-02 — Persona/intent selection
- **Given** language is set, **When** the user advances, **Then** they see two toggles — *Yearly plan* and *Daily devotion* — both **on** by default. They can disable either; **at least one must remain on** to advance.

### FR-ON-03 — Interest tags
- **Given** *Daily devotion* is enabled, **When** the user advances past personas, **Then** they see a multi-select grid of ≥20 starter tags labelled in their chosen language; **at least one tag is required** to finish onboarding while devotion is enabled. They may go back and disable devotion to skip.
- **Given** *Daily devotion* is disabled, **Then** the interests step is skipped entirely.

### FR-ON-04 — Mark onboarding complete
- **Given** the user finishes the last step, **When** they tap *Done*, **Then** an `onboarding.completed = true` flag is persisted locally **and** the app routes to `/plan` if Yearly was selected, otherwise `/devotion` if Devotion was selected, otherwise `/reader`.

### FR-ON-05 — Skip onboarding once completed
- **Given** `onboarding.completed = true`, **When** the app launches, **Then** the router redirects away from `/onboarding` to the user's home tab (same priority as FR-ON-04).

### FR-ON-06 (deferred) — Anonymous Supabase auth
- Tracked here for traceability. **Not implemented in v0 of this feature.** Lands with 0003 because that's the first call that needs an authed user. Will call `Supabase.instance.client.auth.signInAnonymously()` immediately after FR-ON-04 if `Env.isConfigured`.

## Non-functional

- **No blocking I/O on first frame.** Onboarding state is read once at app start (already done for `ReaderPrefs`); no async fetch on mount.
- **A11y:** all controls ≥44 pt tap target, dynamic type respected (NFR-A11Y).
- **i18n:** every visible string in onboarding has both EN and TA translations bundled at compile time. v1 keeps strings inline (no ARB yet — that's deferred until a third language).

## Data contracts

Local-only, persisted via `shared_preferences`:

```
onboarding.completed : bool         // FR-ON-05 gate
onboarding.personas  : string[]     // subset of {'yearly','devotion'}, length ≥1
onboarding.interests : string[]     // stable interest tag codes; length ≥1 iff 'devotion' in personas
reader.language      : 'en'|'ta'    // already owned by ReaderPrefsRepository (FR-ON-01)
```

The `reader.language` key is shared with the existing reader prefs, **not** duplicated here. Onboarding writes to it via the existing `ReaderPrefsNotifier.setLanguage`.

Interest tag codes are stable English snake_case identifiers (e.g. `anxiety`, `marriage`, `work`). Display labels (EN + TA) live in `data/onboarding/interest_tags.dart`. Once 0003 ships and Supabase is wired, the same codes go into the `interests(user_id, tag)` table — no migration needed.

## Out of scope

- Supabase anonymous sign-in (deferred — see FR-ON-06).
- Account upgrade UI (FR-ON-05 in master spec — deferred to settings work).
- Editing interests later (will live in settings, not onboarding).
- ARB-based localization (deferred until a third language is added).
- Reset-onboarding affordance (debug-only menu later).

## Risks / open questions

1. **Tamil interest tag translations** need a native-speaker review before launch. v0 ships best-effort translations seeded by the project owner; flag for review in `interest_tags.dart`.
2. **Tamil reader text not yet bundled** (see 0001 spec §Risks). When language=TA is selected here, the reader still falls back to English text until a Tamil source is shipped — verified by 0001 FR-BR-03 behavior.

## Verification

| ID | Test |
|----|------|
| FR-ON-01 | Fresh install (no `shared_preferences`) → first screen is language picker; pick Tamil → reader header strings render in Tamil after onboarding finishes. |
| FR-ON-02 | Disable both persona toggles → *Continue* is disabled; re-enable one → *Continue* enables. |
| FR-ON-03 | Devotion on, zero interests selected → *Done* disabled; pick one → enabled. Devotion off → interests step never shown. |
| FR-ON-04 | Finish onboarding with Yearly only → land on `/plan`. With Devotion only → land on `/devotion`. With neither (impossible per FR-ON-02) → would land on `/reader`. |
| FR-ON-05 | Kill app and relaunch → no longer sees onboarding; lands on home tab directly. Manually navigating to `/onboarding` redirects out. |
