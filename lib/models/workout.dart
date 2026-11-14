// models/workout.dart
//when you change stuff:
//dart run build_runner build --delete-conflicting-outputs

import 'package:hive_ce/hive.dart';
import 'package:timer_guy/models/exercise.dart';

part 'workout.g.dart';

// extension has .save(), .delete(), and key
@HiveType(typeId: 0)
class Workout extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<Exercise> exercises;

  @HiveField(2)
  final String? description;

  Workout({required this.name, required this.exercises, this.description});

  int get totalReps =>
      exercises.fold(0, (sum, exercise) => sum + exercise.totalReps);

  int get totalSets =>
      exercises.fold(0, (sum, exercise) => sum + exercise.totalSets);

  Workout copyWith({
    String? name,
    List<Exercise>? exercises,
    String? description,
  }) {
    return Workout(
      name: name ?? this.name,
      exercises: exercises ?? this.exercises,
      description: description ?? this.description,
    );
  }
}
