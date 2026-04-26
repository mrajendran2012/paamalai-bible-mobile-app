import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/i18n.dart';
import '../../data/bible/book.dart';
import '../../data/plan/canon.dart';
import '../../data/plan/yearly_plan.dart';
import '../reader/reader_providers.dart';
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
    final lang = ref.watch(readerPrefsProvider.select((p) => p.language));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/plan'),
        ),
        title: Text(lang.t('Catch up', 'பிடிக்க')),
      ),
      body: missed.isEmpty || plan == null
          ? _AllCaughtUp(lang: lang)
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: missed.length,
              itemBuilder: (_, i) {
                // Newest first: walk the list in reverse plan order.
                final dayIdx = missed[missed.length - 1 - i];
                final day = plan[dayIdx - 1];
                final completed = state.completedDays.contains(dayIdx);
                return _MissedDayCard(
                  day: day,
                  completed: completed,
                  lang: lang,
                );
              },
            ),
    );
  }
}

class _MissedDayCard extends ConsumerWidget {
  const _MissedDayCard({
    required this.day,
    required this.completed,
    required this.lang,
  });

  final PlanDay day;
  final bool completed;
  final Lang lang;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final dateLabel =
        DateFormat('EEEE, MMM d', dateLocaleFor(lang)).format(day.date);
    final dayLabel =
        lang == Lang.ta ? 'நாள் ${day.dayIndex}' : 'Day ${day.dayIndex}';
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
                dayLabel,
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
                        '${bookNameFor(ch.bookCode, lang == Lang.ta)} ${ch.chapter}',
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
                        label: Text(
                          lang.t('Completed — undo', 'முடிந்தது — மீட்டமை'),
                        ),
                        onPressed: () => ref
                            .read(planControllerProvider.notifier)
                            .unmark(day.dayIndex),
                      )
                    : FilledButton.icon(
                        icon: const Icon(Icons.check, size: 18),
                        label: Text(
                          lang.t('Mark complete', 'முடிந்தது என்று குறி'),
                        ),
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
  const _AllCaughtUp({required this.lang});
  final Lang lang;

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
              lang.t(
                "You're all caught up.",
                'நீங்கள் முழுமையாக பின்தொடர்ந்துள்ளீர்கள்.',
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
