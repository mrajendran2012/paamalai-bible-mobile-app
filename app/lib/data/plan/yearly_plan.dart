import 'canon.dart';

/// A reference to a single Bible chapter (e.g. `GEN 1`, `REV 22`).
class ChapterRef {
  final String bookCode;
  final int chapter;

  const ChapterRef(this.bookCode, this.chapter);

  @override
  String toString() => '$bookCode $chapter';

  @override
  bool operator ==(Object other) =>
      other is ChapterRef &&
      other.bookCode == bookCode &&
      other.chapter == chapter;

  @override
  int get hashCode => Object.hash(bookCode, chapter);
}

/// One day of the yearly reading plan.
class PlanDay {
  final int dayIndex; // 1..365
  final DateTime date;
  final List<ChapterRef> chapters;

  const PlanDay({
    required this.dayIndex,
    required this.date,
    required this.chapters,
  });
}

const int _planLength = 365;
const int _bigDayCount = totalChapters - 3 * _planLength; // = 94 days with 4 chapters

/// Generate a deterministic 365-day plan covering all 1,189 canonical chapters
/// in Genesis -> Revelation order. Each day has 3 or 4 chapters; exactly 94
/// "big" days have 4 chapters, distributed evenly across the year via a
/// Bresenham-style step.
///
/// Pure function. See specs/0002-yearly-plan/spec.md FR-YP-01.
List<PlanDay> yearlyPlan(DateTime startDate) {
  // 1. Build the full ordered chapter list (length == 1189).
  final allRefs = <ChapterRef>[];
  for (final code in canonOrder) {
    final count = canonChapterCounts[code]!;
    for (var c = 1; c <= count; c++) {
      allRefs.add(ChapterRef(code, c));
    }
  }
  assert(
    allRefs.length == totalChapters,
    'canon tables must sum to $totalChapters',
  );

  // 2. Slice into per-day buckets via Bresenham: day i gets 3 + (floor(i*94/365) - floor((i-1)*94/365)).
  final days = <PlanDay>[];
  var cursor = 0;
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  for (var i = 1; i <= _planLength; i++) {
    final extra = (i * _bigDayCount) ~/ _planLength -
        ((i - 1) * _bigDayCount) ~/ _planLength;
    final count = 3 + extra; // always 3 or 4
    final slice = allRefs.sublist(cursor, cursor + count);
    cursor += count;
    days.add(
      PlanDay(
        dayIndex: i,
        date: start.add(Duration(days: i - 1)),
        chapters: slice,
      ),
    );
  }
  assert(cursor == totalChapters, 'plan must consume every chapter exactly once');
  return days;
}

/// Returns the index (1..365) of [date] within a plan started on [startDate],
/// or `null` if the date is before the plan or after day 365.
int? planDayIndex({required DateTime startDate, required DateTime date}) {
  final start = DateTime(startDate.year, startDate.month, startDate.day);
  final d = DateTime(date.year, date.month, date.day);
  final diff = d.difference(start).inDays;
  if (diff < 0 || diff >= _planLength) return null;
  return diff + 1;
}
