# 0002 — Yearly Plan — Design

## Algorithm

**Problem:** distribute 1,189 chapters across 365 days so each day has 3 or 4 chapters and the totals sum exactly.

`1189 = 3*365 + 94` → exactly **94 days get 4 chapters** and **271 days get 3 chapters**.

**Distribution:** spread the 94 "big" days as evenly as possible. We use Bresenham-style stepping:
- For each day index `i` (1-based), `chaptersToday = 3 + (((i * 94) ~/ 365) - (((i-1) * 94) ~/ 365))`.
- Sums to `94 + 3*365 = 1189` and never exceeds 4 per day.

**Chapter order:** flatten the canonical book order into `List<ChapterRef>` (1,189 refs from `Genesis 1` to `Revelation 22`). Walk that list, slicing per day's `chaptersToday`.

## API

```dart
// data/plan/yearly_plan.dart  — pure, no I/O
class ChapterRef {
  final String bookCode;     // 'GEN', 'REV', ...
  final int chapter;
  const ChapterRef(this.bookCode, this.chapter);
}

class PlanDay {
  final int dayIndex;        // 1..365
  final DateTime date;
  final List<ChapterRef> chapters;
}

List<PlanDay> yearlyPlan(DateTime startDate);
```

The list of chapter counts per book lives in `data/plan/canon.dart` as a `const`:

```dart
const Map<String, int> canonChapterCounts = {
  'GEN': 50, 'EXO': 40, ..., 'REV': 22,
};
const List<String> canonOrder = [
  'GEN','EXO','LEV','NUM','DEU', ..., 'REV',
];
// total = 1189; asserted in a test.
```

## Persistence

`reading_plans` row is written **once** on opt-in: `kind = 'yearly_canonical'`, `started_on = today`. The plan is regenerated from that date on every device.

`reading_progress` rows are written when the user marks a day complete:
- Local SQLite (Drift writable DB) gets the row immediately for offline.
- A background sync uploads queued rows to Supabase when online.
- On launch, pull all rows for the user's plan and reconcile with local — Supabase is the source of truth on conflict (last write wins by `completed_at`).

## UI (`features/plan/`)

```
plan_screen.dart            # Today + Catch-up banner + week overview
plan_providers.dart         # currentPlanProvider, todaysReadingProvider, missedDaysProvider
mark_complete_button.dart
```

## Catch-up logic (FR-YP-04)

```
missed = [day in plan where day.date < today and not in progress.set]
banner shown iff missed.isNotEmpty
catch-up screen lists `missed` newest-first
```

Marking a missed day complete writes its row with `completed_at = now()` (we record when, not for-when).
