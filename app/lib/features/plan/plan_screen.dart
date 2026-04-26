import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/plan/canon.dart';
import '../../data/plan/yearly_plan.dart';
import 'plan_providers.dart';

/// Persona P1 — Yearly Reader. Today's plan is the home screen for them.
/// Implements FR-YP-02 (today + chapter cards + mark complete) and FR-YP-04
/// (catch-up banner). Cross-device sync (FR-YP-03) is local-only in v0.
class PlanScreen extends ConsumerWidget {
  const PlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text("Today's Plan")),
      body: state.hasPlan ? const _ActivePlanBody() : const _EmptyPlanBody(),
    );
  }
}

class _EmptyPlanBody extends ConsumerWidget {
  const _EmptyPlanBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Start the year-long plan',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              'Read the whole Bible in 365 days, three to four chapters a day.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start today'),
              onPressed: () =>
                  ref.read(planControllerProvider.notifier).startPlan(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivePlanBody extends ConsumerWidget {
  const _ActivePlanBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todaysReadingProvider);
    final missed = ref.watch(missedDayIndicesProvider);

    if (today == null) {
      // Either before plan start (clock skew) or past day 365 (plan complete).
      return const _PlanCompleteBody();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (missed.isNotEmpty) _CatchUpBanner(missedCount: missed.length),
        _TodayCard(day: today),
        const SizedBox(height: 16),
        const _WeekStrip(),
      ],
    );
  }
}

class _CatchUpBanner extends StatelessWidget {
  const _CatchUpBanner({required this.missedCount});
  final int missedCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final word = missedCount == 1 ? 'day' : 'days';
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go('/plan/catch-up'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.history, color: scheme.onTertiaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You're $missedCount $word behind",
                    style: TextStyle(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  'Catch up',
                  style: TextStyle(color: scheme.onTertiaryContainer),
                ),
                Icon(Icons.chevron_right, color: scheme.onTertiaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.day});
  final PlanDay day;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(planControllerProvider);
    final isComplete = state.completedDays.contains(day.dayIndex);
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEEE, MMMM d').format(day.date);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Day ${day.dayIndex} of 365',
              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(dateLabel, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            for (final ch in day.chapters)
              _ChapterCard(chapter: ch, completed: isComplete),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: isComplete
                  ? OutlinedButton.icon(
                      icon: const Icon(Icons.check_circle, size: 18),
                      label: const Text('Completed — undo'),
                      onPressed: () => ref
                          .read(planControllerProvider.notifier)
                          .unmark(day.dayIndex),
                    )
                  : FilledButton.icon(
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Mark complete'),
                      onPressed: () => ref
                          .read(planControllerProvider.notifier)
                          .markComplete(day.dayIndex),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard({required this.chapter, required this.completed});
  final ChapterRef chapter;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final name = bookNamesEn[chapter.bookCode] ?? chapter.bookCode;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () =>
              context.go('/reader/${chapter.bookCode}/${chapter.chapter}'),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.menu_book_outlined, color: scheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$name ${chapter.chapter}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (completed)
                  Icon(Icons.check_circle, color: scheme.primary, size: 20),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WeekStrip extends ConsumerWidget {
  const _WeekStrip();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final week = ref.watch(weekStripProvider);
    final state = ref.watch(planControllerProvider);
    if (week.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    final today = ref.watch(todayDayIndexProvider);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This week',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final d in week)
                  Expanded(
                    child: _WeekCell(
                      day: d,
                      completed: state.completedDays.contains(d.dayIndex),
                      isToday: d.dayIndex == today,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekCell extends StatelessWidget {
  const _WeekCell({
    required this.day,
    required this.completed,
    required this.isToday,
  });

  final PlanDay day;
  final bool completed;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final weekday = DateFormat('E').format(day.date).substring(0, 1);
    final bg = isToday
        ? scheme.primary
        : completed
            ? scheme.primaryContainer
            : Colors.transparent;
    final fg = isToday
        ? scheme.onPrimary
        : completed
            ? scheme.onPrimaryContainer
            : scheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          Text(weekday, style: TextStyle(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 6),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: completed && !isToday
                ? Icon(Icons.check, size: 16, color: fg)
                : Text(
                    '${day.date.day}',
                    style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PlanCompleteBody extends StatelessWidget {
  const _PlanCompleteBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.celebration,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Plan complete',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            const Text(
              "You've finished the 365-day plan. Start a new one anytime.",
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
