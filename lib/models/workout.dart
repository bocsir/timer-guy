// models/workout.dart
import 'package:hive_ce/hive.dart';

// extension has .save(), .delete(), and key
class Workout extends HiveObject {
  final String name;
  final int reps;
  final int sets;
  final String timeOn; //use better type
  final String timeOff; //use better type

  Workout({
    required this.name,
    required this.reps,
    required this.sets,
    required this.timeOn,
    required this.timeOff,
  });

  Workout copyWith({
    String? name,
    int? reps,
    int? sets,
    String? timeOn,
    String? timeOff,
  }) {
    return Workout(
      name: name ?? this.name,
      reps: reps ?? this.reps,
      sets: sets ?? this.sets,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
    );
  }
}
