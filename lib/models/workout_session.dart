// models/workout_session.dart
import 'package:hive_ce/hive.dart';

class WorkoutSession extends HiveObject {
  final int workoutKey;        // Links to Workout via Hive key
  final DateTime date;          // When the session occurred
  final int durationSeconds;    // Total time spent
  final bool completed;         // Finished or abandoned
  
  // Computed from date for quick lookups
  final int year;
  final int month;
  final int day;

  WorkoutSession({
    required this.workoutKey,
    required this.date,
    required this.durationSeconds,
    required this.completed,
  })  : year = date.year,
        month = date.month,
        day = date.day;

  WorkoutSession copyWith({
    int? workoutKey,
    DateTime? date,
    int? durationSeconds,
    bool? completed,
  }) {
    return WorkoutSession(
      workoutKey: workoutKey ?? this.workoutKey,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      completed: completed ?? this.completed,
    );
  }
  
  /// Check if this session is on the same day as another date
  bool isSameDay(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}

