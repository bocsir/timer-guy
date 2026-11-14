// hive/register_adapters.dart
//
// Registers the hand-written adapters together with the generated ones.
//
// [MigratingWorkoutAdapter] and [MigratingExerciseAdapter] replace the
// generated `WorkoutAdapter`/`ExerciseAdapter` so old Workout and Exercise
// records can still be read. If another Hive type is added to the app,
// register its generated adapter here as well.
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/hive/exercise_adapter.dart';
import 'package:timer_guy/hive/workout_adapter.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/models/workout_session.dart';

void registerAdapters() {
  Hive.registerAdapter(MigratingWorkoutAdapter());
  Hive.registerAdapter(MigratingExerciseAdapter());
  Hive.registerAdapter(WorkoutSessionAdapter());
  Hive.registerAdapter(ExerciseTypeAdapter());
}
