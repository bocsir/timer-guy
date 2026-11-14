// models/exercise.dart
//when you change stuff:
//dart run build_runner build --delete-conflicting-outputs

import 'package:hive_ce/hive.dart';

part 'exercise.g.dart';

/// How a single exercise is performed.
@HiveType(typeId: 3)
enum ExerciseType {
  /// The exercise alternates a timed working period and a timed rest period.
  @HiveField(0)
  interval,

  /// The user performs the prescribed reps at their own pace, then taps
  /// "Done" to start the exercise's rest timer.
  @HiveField(1)
  reps,
}

/// A single exercise inside a [Workout].
///
/// Interval exercises use [timeOn] as the length of each work interval and
/// [reps] as the number of intervals per set. Sets & reps exercises use [reps]
/// as the number of reps per set, [sets] as the number of sets, and [timeOff]
/// as the rest between sets.
@HiveType(typeId: 1)
class Exercise {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int reps;

  @HiveField(2)
  final int timeOn;

  @HiveField(3)
  final int timeOff;

  @HiveField(4)
  final int sets;

  @HiveField(5)
  final ExerciseType type;

  Exercise({
    required this.name,
    required this.reps,
    required this.timeOn,
    required this.timeOff,
    required this.type,
    this.sets = 1,
  });

  bool get isInterval => type == ExerciseType.interval;
  bool get isReps => type == ExerciseType.reps;

  /// Total amount of work in this exercise (reps or timed intervals).
  int get totalReps => isReps ? reps * sets : reps;

  /// Number of sets in this exercise. Interval exercises are a single set.
  int get totalSets => isReps ? sets : 1;

  Exercise copyWith({
    String? name,
    int? reps,
    int? timeOn,
    int? timeOff,
    int? sets,
    ExerciseType? type,
  }) {
    return Exercise(
      name: name ?? this.name,
      reps: reps ?? this.reps,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
      sets: sets ?? this.sets,
      type: type ?? this.type,
    );
  }
}
