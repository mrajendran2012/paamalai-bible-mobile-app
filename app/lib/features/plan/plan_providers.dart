import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../data/plan/plan_repository.dart';
import '../../data/plan/yearly_plan.dart';

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PlanRepository(prefs);
});

/// Today's date with the time component zeroed (matches the plan's daily grid).
final _todayProvider = Provider<DateTime>((_) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Notifier for plan state — completed days + start date. Bumps a tick so
/// dependent providers rebuild when the user marks a day complete.
class PlanState {
  const PlanState({
    required this.startedOn,
    required this.completedDays,
  });

  final DateTime? startedOn;
  final Set<int> completedDays;

  bool get hasPlan => startedOn != null;
}

class PlanController extends Notifier<PlanState> {
  @override
  PlanState build() {
    final repo = ref.watch(planRepositoryProvider);
    return PlanState(
      startedOn: repo.startedOn,
      completedDays: repo.completedDays,
    );
  }

  Future<void> startPlan() async {
    await ref.read(planRepositoryProvider).startPlanToday();
    _refresh();
  }

  Future<void> markComplete(int dayIndex) async {
    await ref.read(planRepositoryProvider).markComplete(dayIndex);
    _refresh();
  }

  Future<void> unmark(int dayIndex) async {
    await ref.read(planRepositoryProvider).unmark(dayIndex);
    _refresh();
  }

  void _refresh() {
    final repo = ref.read(planRepositoryProvider);
    state = PlanState(
      startedOn: repo.startedOn,
      completedDays: repo.completedDays,
    );
  }
}

final planControllerProvider =
    NotifierProvider<PlanController, PlanState>(PlanController.new);

/// 1..365 if today falls within the active plan; null otherwise.
final todayDayIndexProvider = Provider<int?>((ref) {
  final state = ref.watch(planControllerProvider);
  final today = ref.watch(_todayProvider);
  final start = state.startedOn;
  if (start == null) return null;
  return planDayIndex(startDate: start, date: today);
});

/// The 365-day plan derived from the user's start date, or null if no plan.
final activePlanProvider = Provider<List<PlanDay>?>((ref) {
  final state = ref.watch(planControllerProvider);
  final start = state.startedOn;
  if (start == null) return null;
  return yearlyPlan(start);
});

/// Today's PlanDay, or null if no plan / before-start / after-day-365.
final todaysReadingProvider = Provider<PlanDay?>((ref) {
  final plan = ref.watch(activePlanProvider);
  final idx = ref.watch(todayDayIndexProvider);
  if (plan == null || idx == null) return null;
  return plan[idx - 1];
});

/// Indices of past plan days (strictly before today) not marked complete.
final missedDayIndicesProvider = Provider<List<int>>((ref) {
  final state = ref.watch(planControllerProvider);
  final today = ref.watch(_todayProvider);
  final start = state.startedOn;
  if (start == null) return const [];
  final todayIdx = planDayIndex(startDate: start, date: today);
  if (todayIdx == null || todayIdx <= 1) return const [];
  return [
    for (var i = 1; i < todayIdx; i++)
      if (!state.completedDays.contains(i)) i,
  ];
});

/// The 7 plan days centered on today (today + previous 6 if available).
/// Used for the week-strip on the plan screen.
final weekStripProvider = Provider<List<PlanDay>>((ref) {
  final plan = ref.watch(activePlanProvider);
  final idx = ref.watch(todayDayIndexProvider);
  if (plan == null || idx == null) return const [];
  final start = (idx - 6).clamp(1, 365);
  final end = idx.clamp(1, 365);
  return plan.sublist(start - 1, end);
});
