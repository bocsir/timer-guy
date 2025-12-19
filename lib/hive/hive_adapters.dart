// hive/hive_adapters.dart
import 'package:hive_ce/hive.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/models/workout_set.dart';
import 'package:proj/models/workout_session.dart';

part 'hive_adapters.g.dart';

@GenerateAdapters([
  AdapterSpec<Workout>(),
  AdapterSpec<WorkoutSet>(),
  AdapterSpec<WorkoutSession>(),
])
class HiveAdapters {}
