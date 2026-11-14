// models/workout.dart
//when you change stuff:
//dart run build_runner build --delete-conflicting-outputs

// models/workout.dart
import 'package:hive_ce/hive.dart';

part 'workout.g.dart';

/// How a workout is performed.
@HiveType(typeId: 3)
enum WorkoutType {
  /// Each set alternates a timed working period and a timed rest period.
  @HiveField(0)
  interval,

  /// The user performs the prescribed reps at their own pace, then taps
  /// "Done" to start the set's rest timer.
  @HiveField(1)
  reps,
}

// extension has .save(), .delete(), and key
@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<WorkoutSet> sets;

  @HiveField(2)
  final String? description;

  @HiveField(3)
  final WorkoutType type;

  Workout({
    required this.name,
    required this.sets,
    this.description,
    this.type = WorkoutType.interval,
  });

  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  bool get isInterval => type == WorkoutType.interval;
  bool get isReps => type == WorkoutType.reps;

  Workout copyWith({
    String? name,
    List<WorkoutSet>? sets,
    String? description,
    WorkoutType? type,
  }) {
    return Workout(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      description: description ?? this.description,
      type: type ?? this.type,
    );
  }
}

@HiveType(typeId: 1)
class WorkoutSet extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final int reps;

  @HiveField(2)
  //TODO: use dateTime
  final int timeOn;

  @HiveField(3)
  final int timeOff;

  WorkoutSet({
    required this.name,
    required this.reps,
    required this.timeOn,
    required this.timeOff,
  });

  WorkoutSet copyWith({String? name, int? reps, int? timeOn, int? timeOff}) {
    return WorkoutSet(
      name: name ?? this.name,
      reps: reps ?? this.reps,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
    );
  }
}
