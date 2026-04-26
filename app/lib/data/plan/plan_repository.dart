import 'package:shared_preferences/shared_preferences.dart';

import 'yearly_plan.dart';

/// Local-only persistence for the yearly plan: when the user opted in
/// (`startedOn`) and which day indices they have marked complete.
///
/// Supabase sync (FR-YP-03 cross-device, T7) is deferred until the backend is
/// running locally — see specs/0002-yearly-plan/spec.md.
class PlanRepository {
  PlanRepository(this._prefs);
  final SharedPreferences _prefs;

  static const _kStartedOn = 'plan.startedOn';
  static const _kCompletedDays = 'plan.completedDays';

  /// Date the user opted into the yearly plan (midnight, local time), or null
  /// if no plan is active yet.
  DateTime? get startedOn {
    final s = _prefs.getString(_kStartedOn);
    if (s == null) return null;
    final parsed = DateTime.tryParse(s);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  /// True iff the user has opted in.
  bool get hasPlan => startedOn != null;

  /// The full 365-day plan, or null if no plan is active.
  List<PlanDay>? plan() {
    final start = startedOn;
    if (start == null) return null;
    return yearlyPlan(start);
  }

  /// 1..365 if [date] falls within the plan; null otherwise.
  int? dayIndexFor(DateTime date) {
    final start = startedOn;
    if (start == null) return null;
    return planDayIndex(startDate: start, date: date);
  }

  /// Which days the user has marked complete (1-based).
  Set<int> get completedDays {
    final list = _prefs.getStringList(_kCompletedDays) ?? const [];
    final out = <int>{};
    for (final s in list) {
      final i = int.tryParse(s);
      if (i != null && i >= 1 && i <= 365) out.add(i);
    }
    return out;
  }

  /// Indices of days strictly before [today] that are not yet marked complete.
  /// Capped at the bounds of the plan.
  List<int> missedDays(DateTime today) {
    final start = startedOn;
    if (start == null) return const [];
    final todayIdx = planDayIndex(startDate: start, date: today);
    if (todayIdx == null || todayIdx <= 1) return const [];
    final completed = completedDays;
    return [
      for (var i = 1; i < todayIdx; i++)
        if (!completed.contains(i)) i,
    ];
  }

  /// Begins a plan starting today. No-op if a plan already exists.
  Future<void> startPlanToday() async {
    if (hasPlan) return;
    final now = DateTime.now();
    await _prefs.setString(_kStartedOn, _isoDate(now));
  }

  /// Marks [dayIndex] complete. Idempotent.
  Future<void> markComplete(int dayIndex) async {
    final s = completedDays..add(dayIndex);
    await _prefs.setStringList(
      _kCompletedDays,
      s.map((i) => '$i').toList(),
    );
  }

  /// Removes a previous mark-complete. Idempotent.
  Future<void> unmark(int dayIndex) async {
    final s = completedDays..remove(dayIndex);
    await _prefs.setStringList(
      _kCompletedDays,
      s.map((i) => '$i').toList(),
    );
  }

  /// Wipes plan state entirely. Used for tests / debug.
  Future<void> reset() async {
    await _prefs.remove(_kStartedOn);
    await _prefs.remove(_kCompletedDays);
  }
}

String _isoDate(DateTime dt) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${dt.year.toString().padLeft(4, '0')}-${two(dt.month)}-${two(dt.day)}';
}
