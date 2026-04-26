# tools/

One-shot CLI scripts for prepping data the app and the backend depend on. Not part of the runtime.

## Setup

```bash
cd tools
dart pub get
```

## `build_bible_db.dart` — produce bundled SQLite Bibles

Reads USFM source archives from `tools/_cache/<TRANSLATION>.zip` and writes
`app/assets/bible/web.sqlite` + `app/assets/bible/ta_uv.sqlite`.

```bash
# First run: download + build
dart run build_bible_db.dart --fetch

# Subsequent runs: re-use cached archives
dart run build_bible_db.dart

# Build only one translation
dart run build_bible_db.dart --only=WEB
```

**Sources** (public domain):

| Code | Translation | URL |
|---|---|---|
| `WEB`  | World English Bible | <https://ebible.org/web/> |
| `TAUV` | Tamil Union Version 1957 | <https://ebible.org/tamil1857/> |

The USFM parser inside `_parseUsfmZip` is a TODO — see `specs/0001-bible-reader/tasks.md` T1 for the implementation contract. Stub deliberately throws so a missing parser surfaces loudly.

## `load_bible_to_postgres.dart` — mirror SQLite into Supabase

Required for the `generate-devotion` edge function to look up arbitrary plan-day passages (it cannot read the bundled SQLite). Idempotent: re-running replaces all rows for each translation.

Local dev:

```bash
dart run load_bible_to_postgres.dart \
  --pg-url='postgres://postgres:postgres@localhost:54322/postgres'
```

Production: use the project's transaction-pooler URL from Supabase **Settings → Database → Connection string (URI)**. The script issues batched `INSERT`s of 500 rows; full upload of one translation takes ~1 minute on a Pooler connection.

## Cache directory

`tools/_cache/` is gitignored. Re-creating it from scratch costs one fresh download (≈10 MB per translation).
