import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../data/plan/canon.dart';
import '../../data/plan/yearly_plan.dart';
import 'plan_providers.dart';

/// Lists missed plan days newest-first with a Mark-complete affordance.
/// Implements FR-YP-04. Nothing is auto-skipped or auto-marked.
class CatchUpScreen extends ConsumerWidget {
  const CatchUpScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(activePlanProvider);
    final missed = ref.watch(missedDayIndicesProvider);
    final state = ref.watch(planControllerProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/plan'),
        ),
        title: const Text('Catch up'),
      ),
      body: missed.isEmpty || plan == null
          ? const _AllCaughtUp()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: missed.length,
              itemBuilder: (_, i) {
                // Newest first: walk the list in reverse plan order.
                final dayIdx = missed[missed.length - 1 - i];
                final day = plan[dayIdx - 1];
                final completed = state.completedDays.contains(dayIdx);
                return _MissedDayCard(day: day, completed: completed);
              },
            ),
    );
  }
}

class _MissedDayCard extends ConsumerWidget {
  const _MissedDayCard({required this.day, required this.completed});

  final PlanDay day;
  final bool completed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel = DateFormat('EEEE, MMM d').format(day.date);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Day ${day.dayIndex}',
                style: TextStyle(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final ch in day.chapters)
                    ActionChip(
                      label: Text(
                        '${bookNamesEn[ch.bookCode] ?? ch.bookCode} ${ch.chapter}',
                      ),
                      onPressed: () => context
                          .go('/reader/${ch.bookCode}/${ch.chapter}'),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: completed
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
      ),
    );
  }
}

class _AllCaughtUp extends StatelessWidget {
  const _AllCaughtUp();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              "You're all caught up.",
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
