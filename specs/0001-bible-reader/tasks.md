# 0001 — Bible Reader — Tasks

Order matters. Each task lists the FRs it satisfies; tick when verification passes.

- [ ] **T1** Generate bundled Bibles via `tools/build_bible_db.dart` — see `specs/0001-bible-reader/spec.md` data contract. Verify row counts (WEB ≈ 31,102 verses, Tamil Union ≈ 31,170). _Blocks all reader work._
- [ ] **T2** Add `assets/bible/web.sqlite`, `assets/bible/ta_uv.sqlite` to `pubspec.yaml` `assets:`. Add Android `android:extractNativeLibs="true"` and a `noCompress` rule for `.sqlite`.
- [ ] **T3** `data/bible/bible_database.dart` — Drift schema + `LazyDatabase` loaders for both translations.
- [ ] **T4** `data/bible/bible_repository.dart` — `listBooks`, `chapterCounts`, `getChapter`. Unit-test against the bundled SQLite.
- [ ] **T5** `data/prefs/reader_prefs_repository.dart` — font size + theme + current language via `shared_preferences`.
- [ ] **T6** `features/reader/reader_screen.dart` — book list grouped OT/NT. _[FR-BR-01]_
- [ ] **T7** `features/reader/chapter_view.dart` — verse list with `ScrollablePositionedList`; verse-number-anchored language toggle. _[FR-BR-02, FR-BR-03]_
- [ ] **T8** Display prefs UI in settings + applied at runtime. _[FR-BR-04]_
- [ ] **T9** Bundle Noto Sans Tamil; configure `fontFamilyFallback`.
- [ ] **T10** Instrument chapter-open with `Stopwatch`; confirm ≤500 ms on a mid-tier device. _[NFR-PERF-02]_

## Done when

All four FR-BR-* verification rows in `spec.md` pass on iOS and Android, and `flutter analyze` + `flutter test` are green.
