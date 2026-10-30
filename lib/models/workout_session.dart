// models/workout_session.dart
import 'package:hive_ce/hive.dart';

part 'workout_session.g.dart';

/// A single completed (or abandoned) run of a workout.
///
/// Sessions are stored separately from workouts so the analytics views can
/// aggregate history without touching the workout records.
@HiveType(typeId: 2)
class WorkoutSession extends HiveObject {
  @HiveField(0)
  final int workoutKey;

  @HiveField(1)
  final DateTime date;

  @HiveField(2)
  final int durationSeconds;

  @HiveField(3)
  final bool completed;

  WorkoutSession({
    required this.workoutKey,
    required this.date,
    required this.durationSeconds,
    required this.completed,
  });

  int get year => date.year;
  int get month => date.month;
  int get day => date.day;

  /// Whether this session happened on the same calendar day as [other].
  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;

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
}
