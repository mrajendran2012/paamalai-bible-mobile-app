# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this project is

Paamalai is a Flutter (iOS + Android) Bible app for English and Tamil readers, with a Supabase backend and a Claude-powered daily devotion. See `README.md` for the stack overview and `specs/` for what each feature is supposed to do.

## Spec-driven development — read this first

This repo uses **spec-driven development**. Before writing or changing code for any non-trivial feature, locate or create a spec in `specs/000N-<feature>/`:

- `spec.md` — the **what & why**: user stories, requirements, acceptance criteria, contracts. The single source of truth.
- `design.md` — the **how**: architecture, file layout, data shapes, libraries.
- `tasks.md` — ordered, checkable implementation steps.

Workflow rules:

1. **Spec change before code change.** If implementation reveals the spec is wrong, update the spec in the same PR, don't drift silently.
2. **PRs cite their spec.** Reference the FR/NFR ID(s) the change implements (e.g. `Implements FR-DD-02`).
3. **Acceptance criteria == verification.** A task isn't done until its acceptance criteria pass; the spec's verification table is the test plan.
4. The master v1 spec lives at `specs/README.md` (mirrored from the planning doc). Per-feature specs in `specs/000N/` are the authoritative working copies.

## Required SDKs (none are vendored)

- **Flutter ≥ 3.22** for the mobile app
- **Supabase CLI ≥ 1.180** for local DB + edge function dev
- **Deno ≥ 1.40** (pulled in by Supabase CLI) for edge function runtime

If `flutter`, `supabase`, or `deno` are not on `PATH`, install them before attempting build/test commands. The repo provides no fallbacks.

## Common commands

```bash
# Flutter app (cwd = app/)
flutter pub get
flutter analyze
flutter test
flutter test test/yearly_plan_test.dart           # single test file
flutter test --plain-name "yearly plan covers"    # single test by name
flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...

# Supabase (cwd = repo root)
supabase start
supabase db reset                                  # re-run all migrations on local DB
supabase functions serve generate-devotion --env-file supabase/.env.local
supabase functions deploy generate-devotion

# Bible data importer (cwd = tools/)
dart run build_bible_db.dart                       # regenerates app/assets/bible/*.sqlite
```

The app reads Supabase config from `--dart-define` at build time — there is no `.env` file checked in. The Anthropic key is **only** a Supabase function secret (`supabase secrets set ANTHROPIC_API_KEY=...`); it must never be referenced from `app/`.

## Architecture — the big picture

```
Flutter app  ── reads ──▶  bundled SQLite Bibles (offline, immutable)
     │
     ├── reads/writes ──▶  Supabase Postgres (profiles, interests, plans, progress, devotions_cache)
     │                     RLS enforced on every table
     │
     └── invokes ───────▶  supabase/functions/generate-devotion (Deno)
                              │
                              └── calls Anthropic Messages API (server-side key)
```

Key data-flow rules:

- **Bible text is local and immutable.** All reading must work offline; never round-trip to a server for verses.
- **User data is user-owned.** Every user-scoped table has an RLS policy `using (user_id = auth.uid())`. The edge function authenticates via the caller's JWT and never reads across users.
- **Devotions are cached per `(user_id, for_date, language)`.** Re-opening the same day must not call Claude. Re-roll uses an explicit `force_regenerate=true` flag and is rate-limited (3/day).
- **Anonymous-first auth.** `signInAnonymously()` runs on first write. Linking an email/Google/Apple identity later preserves the same `auth.users.id`, so all child rows survive the upgrade.

## Conventions

- **Layering:** `lib/data/<domain>/` holds repositories (the only thing that touches Drift or Supabase). `lib/features/<screen>/` holds UI and per-screen Riverpod providers. Features depend on data; data does not depend on features.
- **Pure functions belong in `data/<domain>/` and must be unit-tested.** The yearly plan generator is the canonical example: take a date, return a 365-day schedule, no I/O.
- **No analytics or telemetry SDKs in v1.** NFR-PRIV in the master spec.
- **The Anthropic API contract** (model, prompt-caching, error codes) lives in `specs/0003-daily-devotion/spec.md`. Edge function changes that diverge from it require a spec update first.

## When code paths conflict with the spec

The spec wins. If you find code that contradicts a spec acceptance criterion, the bug is in the code, not the spec. Open the spec, confirm the intent, then fix the code (or update the spec in the same PR if the requirement has genuinely changed).
