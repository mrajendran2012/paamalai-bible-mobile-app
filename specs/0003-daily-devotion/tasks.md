# 0003 — Daily Devotion — Tasks

- [ ] **T1** Add `bible_verses` and `devotion_regenerations` tables to `supabase/migrations/0001_init.sql`.
- [ ] **T2** Loader script `tools/load_bible_to_postgres.dart` — uploads SQLite contents into Supabase `bible_verses` (one-shot per translation).
- [ ] **T3** `supabase/functions/generate-devotion/index.ts` — HTTP entry, JWT auth, cache check, rate-limit check, anchor passage resolution, Anthropic call, persist, response shape per spec §Data contracts. _[FR-DD-01..03, FR-DD-05]_
- [ ] **T4** `prompts.ts` — system prompt with prompt-caching cache_control. Reviewed by project owner before merge.
- [ ] **T5** `passages.ts` — ~120 curated `(passage_ref, theme)` rotations.
- [ ] **T6** Local Anthropic client wrapper with retry on 5xx / 429.
- [ ] **T7** App: `data/devotion/devotion_repository.dart` — invoke + cache locally + handle error codes per spec.
- [ ] **T8** App: `features/devotion/devotion_screen.dart` — Markdown render + TTS control hookup + re-roll + AI footer.
- [ ] **T9** Offline empty state + last-7-days history list. _[FR-DD-04]_
- [ ] **T10** Cost + latency instrumentation: log Anthropic `usage` and wall-time per call to a Supabase analytics table. Used for NFR-COST and NFR-PERF-03 verification.

## Done when

All FR-DD-* and the relevant NFR rows in `spec.md` pass; one full week of dogfooding confirms NFR-COST p50 ≤ $0.005/user-day.
