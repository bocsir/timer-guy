// services/analytics_service.dart
import 'package:hive_ce/hive.dart';
import 'package:proj/hive/hive_boxes.dart';
import 'package:proj/models/workout_session.dart';

class AnalyticsService {
  static AnalyticsService? _instance;
  late Box<WorkoutSession> _sessionsBox;
  
  AnalyticsService._();
  
  static AnalyticsService get instance {
    _instance ??= AnalyticsService._();
    return _instance!;
  }
  
  /// Initialize the service (call after Hive boxes are opened)
  void initialize() {
    _sessionsBox = Hive.box<WorkoutSession>(workoutSessionBox);
  }
  
  /// Record a workout session
  Future<void> recordSession({
    required int workoutKey,
    required int durationSeconds,
    required bool completed,
  }) async {
    final session = WorkoutSession(
      workoutKey: workoutKey,
      date: DateTime.now(),
      durationSeconds: durationSeconds,
      completed: completed,
    );
    await _sessionsBox.add(session);
  }
  
  /// Get all sessions for a workout
  List<WorkoutSession> getSessionsForWorkout(int workoutKey) {
    return _sessionsBox.values
        .where((session) => session.workoutKey == workoutKey)
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Most recent first
  }
  
  /// Get sessions for a specific month
  List<WorkoutSession> getSessionsForMonth(int workoutKey, int year, int month) {
    return _sessionsBox.values
        .where((session) =>
            session.workoutKey == workoutKey &&
            session.year == year &&
            session.month == month)
        .toList();
  }
  
  /// Get sessions for a specific year
  List<WorkoutSession> getSessionsForYear(int workoutKey, int year) {
    return _sessionsBox.values
        .where((session) =>
            session.workoutKey == workoutKey && session.year == year)
        .toList();
  }
  
  /// Get session count for a specific day
  int getSessionCountForDay(int workoutKey, DateTime date) {
    return _sessionsBox.values
        .where((session) =>
            session.workoutKey == workoutKey && session.isSameDay(date))
        .length;
  }
  
  /// Get total duration for a specific day
  int getDurationForDay(int workoutKey, DateTime date) {
    return _sessionsBox.values
        .where((session) =>
            session.workoutKey == workoutKey && session.isSameDay(date))
        .fold(0, (sum, session) => sum + session.durationSeconds);
  }
  
  /// Calculate current streak (consecutive days with at least one session)
  int getCurrentStreak(int workoutKey) {
    final sessions = getSessionsForWorkout(workoutKey);
    if (sessions.isEmpty) return 0;
    
    // Get unique days with sessions
    final daysWithSessions = <String>{};
    for (final session in sessions) {
      daysWithSessions.add('${session.year}-${session.month}-${session.day}');
    }
    
    // Start from today and count consecutive days
    int streak = 0;
    DateTime checkDate = DateTime.now();
    
    // Check if there's a session today
    final todayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
    if (!daysWithSessions.contains(todayKey)) {
      // Check yesterday (allow 1 day grace)
      checkDate = checkDate.subtract(const Duration(days: 1));
      final yesterdayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (!daysWithSessions.contains(yesterdayKey)) {
        return 0;
      }
    }
    
    // Count consecutive days going backward
    while (true) {
      final dayKey = '${checkDate.year}-${checkDate.month}-${checkDate.day}';
      if (daysWithSessions.contains(dayKey)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    
    return streak;
  }
  
  /// Calculate longest streak
  int getLongestStreak(int workoutKey) {
    final sessions = getSessionsForWorkout(workoutKey);
    if (sessions.isEmpty) return 0;
    
    // Get unique days with sessions, sorted
    final daysWithSessions = <DateTime>[];
    final seenDays = <String>{};
    
    for (final session in sessions) {
      final dayKey = '${session.year}-${session.month}-${session.day}';
      if (!seenDays.contains(dayKey)) {
        seenDays.add(dayKey);
        daysWithSessions.add(DateTime(session.year, session.month, session.day));
      }
    }
    
    if (daysWithSessions.isEmpty) return 0;
    
    daysWithSessions.sort((a, b) => a.compareTo(b));
    
    int longestStreak = 1;
    int currentStreak = 1;
    
    for (int i = 1; i < daysWithSessions.length; i++) {
      final diff = daysWithSessions[i].difference(daysWithSessions[i - 1]).inDays;
      if (diff == 1) {
        currentStreak++;
        if (currentStreak > longestStreak) {
          longestStreak = currentStreak;
        }
      } else {
        currentStreak = 1;
      }
    }
    
    return longestStreak;
  }
  
  /// Get total duration for a period
  int getTotalDuration(int workoutKey, DateTime start, DateTime end) {
    return _sessionsBox.values
        .where((session) =>
            session.workoutKey == workoutKey &&
            !session.date.isBefore(start) &&
            !session.date.isAfter(end))
        .fold(0, (sum, session) => sum + session.durationSeconds);
  }
  
  /// Get total duration for all sessions of a workout
  int getTotalDurationAll(int workoutKey) {
    return _sessionsBox.values
        .where((session) => session.workoutKey == workoutKey)
        .fold(0, (sum, session) => sum + session.durationSeconds);
  }
  
  /// Get average session duration
  double getAverageDuration(int workoutKey) {
    final sessions = getSessionsForWorkout(workoutKey);
    if (sessions.isEmpty) return 0;
    
    final total = sessions.fold(0, (sum, session) => sum + session.durationSeconds);
    return total / sessions.length;
  }
  
  /// Get workout frequency (average sessions per week over the last N days)
  double getWeeklyFrequency(int workoutKey, {int days = 28}) {
    final now = DateTime.now();
    final start = now.subtract(Duration(days: days));
    
    final count = _sessionsBox.values
        .where((session) =>
            session.workoutKey == workoutKey &&
            !session.date.isBefore(start))
        .length;
    
    final weeks = days / 7;
    return count / weeks;
  }
  
  /// Get session count for a month
  int getMonthlySessionCount(int workoutKey, int year, int month) {
    return getSessionsForMonth(workoutKey, year, month).length;
  }
  
  /// Get session count for all time
  int getTotalSessionCount(int workoutKey) {
    return getSessionsForWorkout(workoutKey).length;
  }
  
  /// Build a map of day -> session count for a year (for heatmap)
  Map<DateTime, int> getYearHeatmapData(int workoutKey, int year) {
    final sessions = getSessionsForYear(workoutKey, year);
    final Map<DateTime, int> heatmap = {};
    
    for (final session in sessions) {
      final day = DateTime(session.year, session.month, session.day);
      heatmap[day] = (heatmap[day] ?? 0) + 1;
    }
    
    return heatmap;
  }
  
  /// Build a map of day -> total duration for a year (for heatmap)
  Map<DateTime, int> getYearDurationHeatmapData(int workoutKey, int year) {
    final sessions = getSessionsForYear(workoutKey, year);
    final Map<DateTime, int> heatmap = {};
    
    for (final session in sessions) {
      final day = DateTime(session.year, session.month, session.day);
      heatmap[day] = (heatmap[day] ?? 0) + session.durationSeconds;
    }
    
    return heatmap;
  }
}

