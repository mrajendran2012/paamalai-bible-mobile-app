# 0006 — Settings — Tasks

## v0

- [ ] **T1** `features/settings/settings_screen.dart` — sectioned ListView with Language + About cards, bilingual labels via `Lang.t`. _[FR-SE-02, FR-SE-03]_
- [ ] **T2** Router: add `/settings` route inside the existing `ShellRoute`. _[FR-SE-01]_
- [ ] **T3** Add a gear icon to the AppBar of `PlanScreen`, `DevotionScreen`, `ReaderScreen`. _[FR-SE-01]_
- [ ] **T4** `test/settings_screen_test.dart` — language toggle persists + AppBar title updates.
- [ ] **T5** `flutter analyze` + `flutter test` green; commit + push.

## Follow-ups (tracked, not in v0)

- [ ] **T6** Interests editor section (lands with feature 0003 follow-up). _[FR-SE-04]_
- [ ] **T7** Account / sign-in upgrade section (lands once Supabase is running). _[FR-SE-05]_
- [ ] **T8** Consolidation: move font / theme / voice picker out of the Reader's modal sheet into `/settings` so settings live in one place.
- [ ] **T9** Debug-only "reset onboarding" affordance (long-press the version line).

## Done when

All FR-SE-01..03 verification rows in `spec.md` pass.
