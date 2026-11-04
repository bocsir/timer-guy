// services/analytics_service.dart
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/models/workout_session.dart';

/// Reads and writes workout history used by the analytics screens.
class AnalyticsService {
  static AnalyticsService? _instance;
  late Box<WorkoutSession> _sessionsBox;

  AnalyticsService._();

  static AnalyticsService get instance => _instance ??= AnalyticsService._();

  /// Call once after the workout session box has been opened.
  void initialize() {
    _sessionsBox = Hive.box<WorkoutSession>(workoutSessionBox);
  }

  Future<void> recordSession({
    required int workoutKey,
    required int durationSeconds,
    required bool completed,
  }) async {
    await _sessionsBox.add(
      WorkoutSession(
        workoutKey: workoutKey,
        date: DateTime.now(),
        durationSeconds: durationSeconds,
        completed: completed,
      ),
    );
  }

  /// All sessions for [workoutKey], most recent first.
  List<WorkoutSession> getSessionsForWorkout(int workoutKey) {
    return _sessionsBox.values
        .where((session) => session.workoutKey == workoutKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<WorkoutSession> getSessionsForMonth(
    int workoutKey,
    int year,
    int month,
  ) {
    return _sessionsBox.values
        .where(
          (session) =>
              session.workoutKey == workoutKey &&
              session.year == year &&
              session.month == month,
        )
        .toList();
  }

  List<WorkoutSession> getSessionsForYear(int workoutKey, int year) {
    return _sessionsBox.values
        .where(
          (session) => session.workoutKey == workoutKey && session.year == year,
        )
        .toList();
  }

  int getSessionCountForDay(int workoutKey, DateTime date) {
    return _sessionsBox.values
        .where(
          (session) =>
              session.workoutKey == workoutKey && session.isSameDay(date),
        )
        .length;
  }

  int getDurationForDay(int workoutKey, DateTime date) {
    return _sessionsBox.values
        .where(
          (session) =>
              session.workoutKey == workoutKey && session.isSameDay(date),
        )
        .fold(0, (sum, session) => sum + session.durationSeconds);
  }

  /// Consecutive days with at least one session, allowing today to be empty
  /// (so a streak is not lost before the user has worked out today).
  int getCurrentStreak(int workoutKey) {
    final daysWithSessions = _daysWithSessions(workoutKey);
    if (daysWithSessions.isEmpty) return 0;

    var checkDate = _dateOnly(DateTime.now());
    if (!daysWithSessions.contains(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
      if (!daysWithSessions.contains(checkDate)) return 0;
    }

    var streak = 0;
    while (daysWithSessions.contains(checkDate)) {
      streak++;
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int getLongestStreak(int workoutKey) {
    final days = _daysWithSessions(workoutKey).toList()..sort();
    if (days.isEmpty) return 0;

    var longest = 1;
    var current = 1;
    for (var i = 1; i < days.length; i++) {
      if (days[i].difference(days[i - 1]).inDays == 1) {
        current++;
        if (current > longest) longest = current;
      } else {
        current = 1;
      }
    }
    return longest;
  }

  int getTotalDuration(int workoutKey, DateTime start, DateTime end) {
    return _sessionsBox.values
        .where(
          (session) =>
              session.workoutKey == workoutKey &&
              !session.date.isBefore(start) &&
              !session.date.isAfter(end),
        )
        .fold(0, (sum, session) => sum + session.durationSeconds);
  }

  int getTotalDurationAll(int workoutKey) {
    return _sessionsBox.values
        .where((session) => session.workoutKey == workoutKey)
        .fold(0, (sum, session) => sum + session.durationSeconds);
  }

  double getAverageDuration(int workoutKey) {
    final sessions = getSessionsForWorkout(workoutKey);
    if (sessions.isEmpty) return 0;
    final total = sessions.fold(
      0,
      (sum, session) => sum + session.durationSeconds,
    );
    return total / sessions.length;
  }

  /// Average sessions per week over the last [days] days.
  double getWeeklyFrequency(int workoutKey, {int days = 28}) {
    final start = DateTime.now().subtract(Duration(days: days));
    final count = _sessionsBox.values
        .where(
          (session) =>
              session.workoutKey == workoutKey && !session.date.isBefore(start),
        )
        .length;
    return count / (days / 7);
  }

  int getMonthlySessionCount(int workoutKey, int year, int month) {
    return getSessionsForMonth(workoutKey, year, month).length;
  }

  int getTotalSessionCount(int workoutKey) =>
      getSessionsForWorkout(workoutKey).length;

  /// Day -> session count for a year (used by the activity heatmap).
  Map<DateTime, int> getYearHeatmapData(int workoutKey, int year) {
    final heatmap = <DateTime, int>{};
    for (final session in getSessionsForYear(workoutKey, year)) {
      final day = _dateOnly(session.date);
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    return heatmap;
  }

  /// Day -> total duration for a year (used by the activity heatmap).
  Map<DateTime, int> getYearDurationHeatmapData(int workoutKey, int year) {
    final heatmap = <DateTime, int>{};
    for (final session in getSessionsForYear(workoutKey, year)) {
      final day = _dateOnly(session.date);
      heatmap[day] = (heatmap[day] ?? 0) + session.durationSeconds;
    }
    return heatmap;
  }

  Set<DateTime> _daysWithSessions(int workoutKey) =>
      getSessionsForWorkout(workoutKey).map((s) => _dateOnly(s.date)).toSet();

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
