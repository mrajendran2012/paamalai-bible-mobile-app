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

## Open

_(none)_

---

## Resolved

### B-0001 — Tamil verse text shows in English &nbsp;<sub>logged 2026-04-26 · resolved 2026-04-26</sub>

_Affected: specs/0001-bible-reader/ (FR-BR-02, FR-BR-03), specs/0002-yearly-plan/ (FR-YP-02 chapter cards transitively)_

- **Symptom:** With language = Tamil selected during onboarding, the chapter view in the Reader still shows English verses; chapter cards on the Plan screen open into the same English-only chapter view.
- **Root cause:** No Tamil Bible source was bundled. `tools/build_bible_db.dart` only produced `web.sqlite`; `BibleRepository._dbFor(Lang.ta)` fell back to the WEB DB whenever the Tamil DB was absent.
- **Fix:** Bundled the **Tamil Indian Revised Version** (`tam2017`, CC-BY-SA 4.0) at `app/assets/bible/ta_irv.sqlite`. Importer wired in `tools/build_bible_db.dart` `_sources['TAIRV']`; reader provider points at the new asset. CC-BY-SA attribution surfaced via the new About screen reachable from the Reader's settings sheet (`/about`). Spec 0001 §Risks #2 updated with the resolution.

### B-0002 — Plan screen chapter card book names render in English &nbsp;<sub>logged 2026-04-26 · closed 2026-04-26</sub>

_Affected: specs/0002-yearly-plan/ (FR-YP-02)_

- **Symptom:** With language = Tamil, chapter card book names appear in English (e.g. "Genesis 1" instead of "ஆதியாகமம் 1").
- **Closing note:** Could not reproduce against `main` HEAD. Commit `65397a4` had already wired `_ChapterCard` through `bookNameFor(code, lang == Lang.ta)`, which reads from `bookNamesTa` whose values match the SQLite `books.name_ta` column (verified during importer dev). The original report most likely came from a build that pre-dated `65397a4`. Re-open if the symptom resurfaces on a clean rebuild.
