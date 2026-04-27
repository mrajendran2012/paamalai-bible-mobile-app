# 0006 — Settings

## Context

Master spec FR-ST-01..03 (Settings & privacy) defines settings as cross-cutting. They've been partly fulfilled scattered across feature surfaces — the Reader's modal sheet has font / theme / voice / about; onboarding writes the initial language. There is **no app-wide settings home**, which means the language picker is currently only reachable during onboarding (FR-ST-01 violation: "Change preferred language **any time**").

This feature lands the missing surface: a dedicated `/settings` screen, reachable from every tab, that owns the app-wide preferences and gives future settings (interests editor, devotion frequency, account, etc.) a known home.

## Personas

All three personas pass through here whenever they want to adjust app-wide preferences.

## Functional requirements

### FR-SE-01 — Reach settings from any tab
- *As a* user *I want* a settings entry point that's always visible *so that* I don't have to remember which screen owns which preference.
- **Given** the user is on any of the three home tabs (Plan / Devotion / Reader), **Then** a gear icon appears in the AppBar's top-right and tapping it opens the settings screen.
- The same gear is reachable from sub-routes (Catch-up, Chapter view) where it makes sense; for v0 we add it only to the three home tabs and `HomeShell` itself.

### FR-SE-02 — Change preferred language (FR-ST-01)
- **Given** the user is on `/settings`, **When** they tap the language card and choose EN or TA, **Then** `ReaderPrefs.language` is persisted immediately and every screen rebuilds in the new language. No restart required.
- The currently active language is highlighted; tapping it again is a no-op.

### FR-SE-03 — Settings shell is forward-compatible
- The screen is rendered as a sectioned `ListView`. v0 contains the **Language** section and a footer entry that routes to `/about`.
- Sections that aren't built yet (Interests, Account, Notifications, …) are **not shown** in v0 — they are added by their respective feature PRs. Avoid scaffolding them as "Coming soon" tiles; the empty space communicates clearly that settings is small today.

### FR-SE-04 (deferred) — Edit interests
- Tracked here for traceability — lands with feature 0003 follow-up. v0 does not surface this.

### FR-SE-05 (deferred) — Account / sign-in upgrade
- Tracked here for traceability — lands once Supabase is running locally.

## Non-functional

- **A11y:** every row ≥44 pt tap target; language row uses radio semantics so screen-readers announce it correctly.
- **i18n:** all strings inline-bilingual via `core/i18n.dart`'s `Lang.t` helper, matching the rest of the app shell.

## Data contracts

No new persistence. Language is owned by the existing `ReaderPrefsRepository`; the settings screen is just a UI over it.

## Out of scope

- Moving the existing Reader settings sheet content (font / theme / voice) into `/settings`. v0 leaves the sheet as-is — consolidation is a future PR.
- Reset-onboarding affordance (debug-only menu, deferred).

## Verification

| ID | Test |
|----|------|
| FR-SE-01 | On Plan tab → see gear icon → tap → land on `/settings` with the gear-tap gesture animating. Repeat on Devotion and Reader. |
| FR-SE-02 | On `/settings` with EN active → tap TA → AppBar title flips to Tamil immediately; relaunch app → still TA. |
| FR-SE-03 | v0 settings screen shows exactly two cards: Language + About. No "Coming soon" tiles. |
