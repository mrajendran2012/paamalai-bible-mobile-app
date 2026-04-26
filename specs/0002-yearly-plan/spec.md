# 0002 — Yearly Reading Plan

## Context

Persona P1 wants to finish the Bible in one year. We provide a deterministic 365-day plan that covers all 1,189 chapters in canonical order (Genesis → Revelation), surface today's reading, track per-day completion, and gracefully handle missed days.

## Personas

P1 (Yearly Reader). P3 (Listener) reaches the plan's chapters indirectly via the Reader.

## Functional requirements

### FR-YP-01 — Plan generation
- *As a* user opting into the yearly plan *I want* a complete schedule *so that* I always know what to read each day.
- **Given** *Yearly plan* is enabled, **Then** a 365-day plan is generated covering all 1,189 chapters in canonical order, each day containing 3–4 chapters such that the totals sum to 1,189 with no duplicates and no gaps.

### FR-YP-02 — Today's reading
- **Given** an active plan, **When** the user opens the Plan tab, **Then** they see today's chapters as tappable cards (each opens the Reader at that chapter) and a *Mark complete* action.

### FR-YP-03 — Progress tracking
- **Given** the user marks a day complete, **Then** a `reading_progress` row is written to Supabase **and** mirrored locally for offline. The day is shown as completed across devices for the same account.
- **v0 status (2026-04-25):** local persistence (SharedPreferences) is in place; Supabase write + cross-device read are deferred until the local Supabase stack is running. Tracked by tasks.md T7.

### FR-YP-04 — Catch-up
- **Given** the user has missed ≥1 day, **When** they open the Plan tab, **Then** a banner shows the count of missed days and a *Catch up* action listing the missed chapters; nothing is auto-skipped, nothing is auto-marked complete.

## Data contracts

`reading_plans` and `reading_progress` from the master spec. The plan itself is **not** stored — it is derived deterministically from `reading_plans.started_on`, so any device can rebuild it.

## Out of scope

- Multiple concurrent plans per user
- Alternate plan shapes (M'Cheyne, chronological-by-events, etc.) — deferred
- Streaks, badges, share cards

## Verification

| ID | Test |
|----|------|
| FR-YP-01 | Unit test `yearlyPlan(DateTime.parse('2026-01-01'))` → length 365, flatMap of all chapter refs has size 1,189, and `Set.from(refs).length == 1189` (no duplicates). |
| FR-YP-02 | Plan tab on day N shows N's chapters; tapping a card opens the Reader at that chapter. |
| FR-YP-03 | Mark today complete → row appears in Supabase `reading_progress`; sign in on a second device → day shown completed. |
| FR-YP-04 | Skip 2 days, return → banner shows "You're 2 days behind"; *Catch up* lists exactly the 2 missed days' chapters. |
