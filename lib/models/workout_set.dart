// models/workout_set.dart
import 'package:hive_ce/hive.dart';

class WorkoutSet extends HiveObject {
  final String name;
  final int reps;
  final int timeOn; //use better type
  final int timeOff; //use better type
  final bool enableGetReady; // Enable "Get Ready" period before each rep

  WorkoutSet({
    required this.name,
    required this.reps,
    required this.timeOn,
    required this.timeOff,
    this.enableGetReady = false,
  });

  WorkoutSet copyWith({
    String? name,
    int? reps,
    int? timeOn,
    int? timeOff,
    bool? enableGetReady,
  }) {
    return WorkoutSet(
      name: name ?? this.name,
      reps: reps ?? this.reps,
      timeOn: timeOn ?? this.timeOn,
      timeOff: timeOff ?? this.timeOff,
      enableGetReady: enableGetReady ?? this.enableGetReady,
    );
  }
}

