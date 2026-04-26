import 'package:flutter_test/flutter_test.dart';
import 'package:paamalai/data/plan/canon.dart';
import 'package:paamalai/data/plan/yearly_plan.dart';

void main() {
  group('canon tables', () {
    test('66 books', () {
      expect(canonOrder.length, 66);
      expect(canonChapterCounts.length, 66);
      expect(canonOrder.toSet(), canonChapterCounts.keys.toSet());
    });

    test('chapter counts sum to 1189', () {
      final sum = canonChapterCounts.values.fold<int>(0, (a, b) => a + b);
      expect(sum, totalChapters);
    });
  });

  group('yearlyPlan', () {
    final plan = yearlyPlan(DateTime(2026, 1, 1));

    test('has exactly 365 days', () {
      expect(plan.length, 365);
    });

    test('every day has 3 or 4 chapters', () {
      for (final d in plan) {
        expect(d.chapters.length, anyOf(3, 4),
            reason: 'day ${d.dayIndex} had ${d.chapters.length}');
      }
    });

    test('exactly 94 days have 4 chapters', () {
      final big = plan.where((d) => d.chapters.length == 4).length;
      expect(big, 94);
    });

    test('covers all 1189 chapters with no duplicates and no gaps', () {
      final flat = plan.expand((d) => d.chapters).toList();
      expect(flat.length, totalChapters);
      expect(flat.toSet().length, totalChapters,
          reason: 'duplicate chapter references in plan');
    });

    test('starts at Genesis 1 on day 1', () {
      expect(plan.first.chapters.first, const ChapterRef('GEN', 1));
    });

    test('ends at Revelation 22 on day 365', () {
      expect(plan.last.chapters.last, const ChapterRef('REV', 22));
    });

    test('chapter order matches the canonical sequence', () {
      final flat = plan.expand((d) => d.chapters).toList();
      var i = 0;
      for (final code in canonOrder) {
        for (var c = 1; c <= canonChapterCounts[code]!; c++) {
          expect(flat[i], ChapterRef(code, c),
              reason: 'mismatch at position $i');
          i++;
        }
      }
    });

    test('day dates increment by one calendar day', () {
      for (var i = 1; i < plan.length; i++) {
        expect(plan[i].date.difference(plan[i - 1].date).inDays, 1);
      }
    });

    test('day 1 date matches start date (midnight)', () {
      final p = yearlyPlan(DateTime(2026, 4, 25, 9, 30));
      expect(p.first.date, DateTime(2026, 4, 25));
    });
  });

  group('planDayIndex', () {
    final start = DateTime(2026, 1, 1);

    test('start date is day 1', () {
      expect(planDayIndex(startDate: start, date: start), 1);
    });

    test('day 365 is the last valid index', () {
      expect(
        planDayIndex(startDate: start, date: start.add(const Duration(days: 364))),
        365,
      );
    });

    test('returns null before start', () {
      expect(
        planDayIndex(startDate: start, date: start.subtract(const Duration(days: 1))),
        isNull,
      );
    });

    test('returns null after day 365', () {
      expect(
        planDayIndex(startDate: start, date: start.add(const Duration(days: 365))),
        isNull,
      );
    });
  });
}
