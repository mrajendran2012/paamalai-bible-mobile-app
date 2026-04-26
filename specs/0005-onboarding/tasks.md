# 0005 — Onboarding — Tasks

Order matters. Each task lists the FRs it satisfies; tick when verification passes.

- [ ] **T1** `data/onboarding/interest_tags.dart` — 22 stable codes with EN + TA labels (TA labels marked for native-speaker review). _[FR-ON-03]_
- [ ] **T2** `data/onboarding/onboarding_repository.dart` — SharedPreferences-backed read/write of `completed`, `personas`, `interests`. _[FR-ON-04, FR-ON-05]_
- [ ] **T3** `features/onboarding/onboarding_providers.dart` — `OnboardingDraft` notifier seeded from current `ReaderPrefs.language`.
- [ ] **T4** `features/onboarding/steps/language_step.dart` — pickable cards; writes through `ReaderPrefsNotifier.setLanguage`. _[FR-ON-01]_
- [ ] **T5** `features/onboarding/steps/persona_step.dart` — two switch tiles with the "≥1 required" rule. _[FR-ON-02]_
- [ ] **T6** `features/onboarding/steps/interests_step.dart` — FilterChip wrap, localized labels, "≥1 required" rule. _[FR-ON-03]_
- [ ] **T7** Replace stub `features/onboarding/onboarding_screen.dart` with PageView host, dynamic step count, *Continue* / *Done* buttons. _[FR-ON-04]_
- [ ] **T8** Wire router `redirect` so first-launch lands on `/onboarding` and post-completion lands on the persona-driven home. _[FR-ON-05]_
- [ ] **T9** Tests: `test/onboarding_repository_test.dart` + `test/onboarding_routing_test.dart`. Existing `widget_test.dart` continues to pass.
- [ ] **T10** `flutter analyze` + `flutter test` green.

## Done when

All FR-ON-01..05 verification rows in `spec.md` pass. FR-ON-06 (anonymous Supabase auth) is intentionally deferred and tracked in 0003's tasks.
