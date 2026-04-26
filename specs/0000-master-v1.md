# Master v1 Spec — Paamalai

## Vision

A mobile Bible app (iOS + Android) that lets a reader (a) progress through the whole Bible in a year and (b) receive a short daily devotion personalized to their interests, in **English or Tamil**, with **in-app audio reading** in the chosen language.

## Personas

| ID | Name | Goal | Success looks like |
|----|------|------|--------------------|
| P1 | **Yearly Reader** | Finish the Bible in a year. | Opens app daily, sees today's reading, marks it complete, sees streak/progress. |
| P2 | **Devotional Reader** | Get a short, relevant daily reflection. | Opens app, reads ~300-word devotion tied to their interests + today's passage. |
| P3 | **Listener** (cross-cuts P1 + P2) | Consume content by ear. | Taps play on any chapter or devotion; hears it in their language at chosen speed. |

A single user may be P1 + P2 + P3 simultaneously.

## Decisions (confirmed)

| Area | Choice |
|---|---|
| Framework | Flutter (Dart) |
| Backend | Supabase (Postgres + Auth + Edge Functions + Storage) |
| Devotions | Claude API server-side (`claude-haiku-4-5-20251001`, prompt caching) |
| TTS | Device-native via `flutter_tts` |
| Translations v1 | WEB (English, public domain) + Tamil Union 1957 (public domain) |
| Auth | Anonymous-first; optional email / Google / Apple link |
| Personalization | Multi-select interest tags |
| Yearly plan shape | Chronological canonical order, ~3.25 chapters/day |

## Per-feature specs

| ID | Feature | Spec |
|----|---------|------|
| 0001 | Bible reader (browse, render, translation toggle, display prefs) | [`0001-bible-reader/spec.md`](0001-bible-reader/spec.md) |
| 0002 | Yearly reading plan | [`0002-yearly-plan/spec.md`](0002-yearly-plan/spec.md) |
| 0003 | Daily devotion (Claude-generated) | [`0003-daily-devotion/spec.md`](0003-daily-devotion/spec.md) |
| 0004 | Audio reader (TTS) | [`0004-audio-reader/spec.md`](0004-audio-reader/spec.md) |

Onboarding, identity, settings, and the Supabase data model are cross-cutting and defined inline in this master spec; the per-feature specs reference back to them.

## Cross-cutting requirements

### Onboarding & identity

**FR-ON-01** — Language selection on first launch
- **Given** a fresh install, **When** the app launches, **Then** the user sees a language picker (English, Tamil) before any other screen, and the choice is persisted.

**FR-ON-02** — Persona/intent selection
- **Given** language is set, **When** the user advances, **Then** they pick one or both of *Yearly plan*, *Daily devotion*. Both are enabled by default.

**FR-ON-03** — Interest tags
- **Given** *Daily devotion* is enabled, **When** the user advances, **Then** they multi-select from ≥20 starter tags. At least one tag is required to enable devotions; user may skip and enable later.

**FR-ON-04** — Anonymous-first auth
- **Given** the user finishes onboarding, **When** any data is written, **Then** they are silently signed in as an anonymous Supabase user. No email/password prompt is shown.

**FR-ON-05** — Optional account upgrade
- **Given** an anonymous user, **When** they tap *Save my progress*, **Then** they can link an email/Google/Apple identity, **and** their existing progress, interests, and devotion history remain attached to the same `user_id`.

### Settings & privacy

**FR-ST-01** — Change preferred language any time without losing progress.
**FR-ST-02** — Edit interests any time; changes affect *future* devotions only.
**FR-ST-03** — Delete account → cascades through all user-owned tables (RLS + `on delete cascade`).

### Non-functional

| ID | Requirement |
|----|------|
| NFR-PERF-01 | Cold start to first interactive screen ≤ 2.5 s on a mid-tier 2022 Android. |
| NFR-PERF-02 | Chapter open ≤ 500 ms offline. |
| NFR-PERF-03 | Devotion generation p95 ≤ 6 s end-to-end. |
| NFR-OFFLINE | All Bible reading, yearly-plan navigation, and previously-cached devotions work offline. |
| NFR-A11Y | Dynamic type respected; minimum tap target 44 pt; TTS = first-class citizen. |
| NFR-PRIV | No third-party analytics in v1. Server stores only what's needed for sync + devotions. |
| NFR-SEC | Anthropic API key only ever in the Supabase Edge Function secret store. RLS enforced on every user table. |
| NFR-COST | Devotion cost ≤ ~US$0.005 per user-day at p50 (Haiku + prompt caching). |
| NFR-I18N | App shell strings localized via ARB; new languages = add `.arb`, no code changes. |

## Canonical Supabase schema

```sql
create table profiles (
  id uuid primary key references auth.users on delete cascade,
  display_name text,
  preferred_language text not null default 'en' check (preferred_language in ('en','ta')),
  created_at timestamptz default now()
);

create table interests (
  user_id uuid references profiles on delete cascade,
  tag text not null,
  primary key (user_id, tag)
);

create table reading_plans (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references profiles on delete cascade,
  kind text not null check (kind in ('yearly_canonical')),
  started_on date not null,
  created_at timestamptz default now()
);

create table reading_progress (
  plan_id uuid references reading_plans on delete cascade,
  day_index int not null check (day_index between 1 and 365),
  completed_at timestamptz not null default now(),
  primary key (plan_id, day_index)
);

create table devotions_cache (
  user_id uuid references profiles on delete cascade,
  for_date date not null,
  language text not null check (language in ('en','ta')),
  passage_ref text not null,
  body_md text not null,
  model text not null,
  created_at timestamptz default now(),
  primary key (user_id, for_date, language)
);
```

RLS on every table: `using (user_id = auth.uid())` (or, for `reading_progress`, joined through `reading_plans.user_id`).

## Out of scope (v1)

- Pre-recorded audio Bible (device TTS only)
- Highlights, notes, social sharing
- Push notifications, streaks, gamification
- In-app purchase / paid translations
- Languages beyond English + Tamil
- Cross-device sync settings UI (data already syncs, just no surfaced screen)

## Risks

1. **BSI Tamil license** — copyrighted; v1 falls back to Tamil Union 1957 PD text until BSI license is signed.
2. **App store policies** — personalized AI content may need an "AI-generated" disclosure in store listing and in-app footer.
3. **Tamil TTS quality** varies by Android OEM; some lack `ta-IN`. Surface a "limited audio" notice rather than failing silently.
4. **Asset size** — bundling both translations adds ~30 MB. If we ever ship 5+ translations, switch to first-launch download per language.

## Follow-ups (post-launch)

- ~2 weeks post-launch: scheduled agent to pull devotion-cost + Claude latency stats from Supabase function logs and report.
- Once BSI license signed: scheduled agent to swap default Tamil from Union 1957 → BSI and bump asset version.
