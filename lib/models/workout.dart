// models/workout.dart
//when you change stuff:
//dart run build_runner build --delete-conflicting-outputs

// models/workout.dart
import 'package:hive_ce/hive.dart';

part 'workout.g.dart';

// extension has .save(), .delete(), and key
@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<WorkoutSet> sets;

  @HiveField(2)
  final String? description;

  Workout({required this.name, required this.sets, this.description});

  int get totalReps => sets.fold(0, (sum, set) => sum + set.reps);

  Workout copyWith({
    String? name,
    List<WorkoutSet>? sets,
    String? description,
    int? reps,
    int? timeOn,
    int? timeOff,
  }) {
    return Workout(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      description: description ?? this.description,
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

  WorkoutSet({required this.name, required this.reps, required this.timeOn, required this.timeOff});

  WorkoutSet copyWith({String? name, int? reps, int? timeOn, int? timeOff}) {
    return WorkoutSet(
      name: name ?? this.name,
      reps: reps ?? this.reps,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
    );
  }
}
