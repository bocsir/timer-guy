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
/// Interval exercises use [timeOn] as the length of each work interval,
/// [timeOff] as the rest between intervals, and [restBetweenSets] as the rest
/// between sets. Sets & reps exercises use [reps] as the number of reps per
/// set, and [timeOff] as the rest between sets.
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

  /// Optional free-form notes or instructions shown alongside the exercise.
  @HiveField(6)
  final String? description;

  /// Rest between sets, in seconds.
  ///
  /// Only used by interval exercises. Sets & reps exercises use [timeOff] as
  /// the rest between sets.
  @HiveField(7)
  final int restBetweenSets;

  Exercise({
    required this.name,
    required this.reps,
    required this.timeOn,
    required this.timeOff,
    required this.type,
    this.sets = 1,
    this.description,
    this.restBetweenSets = 0,
  });

  bool get isInterval => type == ExerciseType.interval;
  bool get isReps => type == ExerciseType.reps;

  /// Total amount of work in this exercise (reps or timed intervals).
  int get totalReps => reps * sets;

  /// Number of sets in this exercise.
  int get totalSets => sets;

  Exercise copyWith({
    String? name,
    int? reps,
    int? timeOn,
    int? timeOff,
    int? sets,
    ExerciseType? type,
    String? description,
    int? restBetweenSets,
  }) {
    return Exercise(
      name: name ?? this.name,
      reps: reps ?? this.reps,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
      sets: sets ?? this.sets,
      type: type ?? this.type,
      description: description ?? this.description,
      restBetweenSets: restBetweenSets ?? this.restBetweenSets,
    );
  }
}
