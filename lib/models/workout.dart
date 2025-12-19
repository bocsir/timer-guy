// models/workout.dart
//when you change stuff:
//dart run build_runner build --delete-conflicting-outputs

// models/workout.dart
import 'package:hive_ce/hive.dart';
import 'package:proj/models/workout_set.dart';

// extension has .save(), .delete(), and key
class Workout extends HiveObject {
  final String name;
  final List<WorkoutSet> sets;

  Workout({
    required this.name,
    required this.sets,
  });

  Workout copyWith({
    String? name,
    List<WorkoutSet>? sets,
  }) {
    return Workout(
      name: name ?? this.name,
      sets: sets ?? this.sets,
    );
  }
}
