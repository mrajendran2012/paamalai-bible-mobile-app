# Known bugs

A short, dated list of in-flight bugs and limitations. Each entry links to
the affected spec (the spec is still the source of truth — when a bug is
fixed, update the spec's verification table and remove the entry here).

Format:
- **B-NNNN** — one-line headline. _affects: <spec id(s)>_ &nbsp;<sub>logged YYYY-MM-DD</sub>
  - **Symptom:** what the user sees.
  - **Root cause:** what's actually wrong (or "unknown — investigate" if not yet diagnosed).
  - **Fix:** what unblocks resolution.

---

## B-0001 — Tamil verse text shows in English &nbsp;<sub>logged 2026-04-26</sub>

_Affects: specs/0001-bible-reader/ (FR-BR-02, FR-BR-03), specs/0002-yearly-plan/ (FR-YP-02 chapter cards transitively)_

- **Symptom:** With language = Tamil selected during onboarding, the chapter view in the Reader still shows English verses; chapter cards on the Plan screen open into the same English-only chapter view.
- **Root cause:** No Tamil Bible source is bundled. `tools/build_bible_db.dart` only produces `web.sqlite`; `BibleRepository._dbFor(Lang.ta)` falls back to the WEB DB whenever the Tamil DB is absent.
- **Fix:** Pick a Tamil source under an open license, wire it into `_sources` in `tools/build_bible_db.dart`, ship the resulting `ta_*.sqlite` as a bundled asset, and add CC-BY-SA attribution surface in the app. Two candidates already vetted on eBible.org, both **CC-BY-SA 4.0**:
  - `tam2017` — Tamil Indian Revised Version (traditional register).
  - `tamocv` — Tamil Open Contemporary Version (modern register).
  - Pending project-owner pick. See `specs/0001-bible-reader/spec.md` §Risks.

---

## B-0002 — Plan screen chapter card book names may render in English &nbsp;<sub>logged 2026-04-26</sub>

_Affects: specs/0002-yearly-plan/ (FR-YP-02)_

- **Symptom:** With language = Tamil, headers and buttons on the Plan screen render in Tamil but chapter card book names appear in English (e.g. "Genesis 1" instead of "ஆதியாகமம் 1").
- **Root cause:** Unknown — investigate. Commit `65397a4` switched `_ChapterCard` to `bookNameFor(code, lang == Lang.ta)` which reads from `bookNamesTa`; tests pass, but the user-visible bug was reported on a build that may pre-date that commit. Need to confirm whether this reproduces against `main` HEAD before treating it as a real defect.
- **Fix:** Reproduce on a clean build at `main`. If the bug persists, add a widget test that pumps the Plan screen with `Lang.ta` and asserts a Tamil book name shows up in `_ChapterCard`. If it doesn't repro, close as "stale build."
