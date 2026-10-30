// hive/register_adapters.dart
//
// Registers the hand-written adapters together with the generated ones.
//
// [MigratingWorkoutAdapter] replaces the generated `WorkoutAdapter` for typeId
// 0 so old Workout records can still be read. If another Hive type is added to
// the app, register its generated adapter here as well.
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/hive/workout_adapter.dart';
import 'package:timer_guy/models/workout.dart';

void registerAdapters() {
  Hive.registerAdapter(MigratingWorkoutAdapter());
  Hive.registerAdapter(WorkoutSetAdapter());
}
