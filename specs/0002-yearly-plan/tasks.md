# 0002 — Yearly Plan — Tasks

- [ ] **T1** `data/plan/canon.dart` — `canonOrder` (66 codes) and `canonChapterCounts` (sum = 1189). Add `assert` in a test that the sum is 1189.
- [ ] **T2** `data/plan/yearly_plan.dart` — pure `yearlyPlan(DateTime)` per `design.md`. _[FR-YP-01]_
- [ ] **T3** `test/yearly_plan_test.dart` — assert: 365 days, sum 1189, no duplicates, Day 1 starts at GEN 1, Day 365 ends at REV 22.
- [ ] **T4** `data/plan/plan_repository.dart` — create plan, list progress, mark day complete, queue offline. Uses local Drift writable DB + Supabase.
- [ ] **T5** `features/plan/plan_screen.dart` — Today card + week overview + Mark complete. _[FR-YP-02, FR-YP-03]_
- [ ] **T6** Catch-up banner + screen. _[FR-YP-04]_
- [ ] **T7** Background sync of queued progress rows to Supabase on app resume + connectivity change.

## Done when

All FR-YP-* verification rows pass; `flutter test test/yearly_plan_test.dart` is green; manual two-device sync test confirms cross-device progress.
