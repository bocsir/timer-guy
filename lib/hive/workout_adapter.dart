// hive/workout_adapter.dart
//
// The Workout model used to store a single reps/duration triple:
//   0: name, 1: reps, 2: number of sets, 3: timeOn, 4: timeOff
//
// It now stores a list of WorkoutSet objects in field 1. Records written with
// the old schema therefore fail the generated adapter's `fields[1] as List`
// cast. This adapter understands both formats and converts old records on the
// fly, so existing boxes keep opening after an upgrade.
//
// This file is hand-written and is deliberately kept out of the generated
// workout.g.dart so running build_runner does not remove the migration.
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/models/workout.dart';

class MigratingWorkoutAdapter extends WorkoutAdapter {
  /// Whether [read] encountered a record written with an old schema.
  ///
  /// `main` rewrites the box when this is true so the migration only has to
  /// run once per box.
  static bool migratedLegacyData = false;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Current schema.
    final sets = fields[1];
    if (sets is List) {
      return Workout(name: fields[0] as String, sets: sets.cast<WorkoutSet>());
    }

    // An intermediate schema stored the set list in field 2.
    final legacySets = fields[2];
    if (legacySets is List) {
      migratedLegacyData = true;
      return Workout(
        name: fields[0] as String,
        sets: legacySets.cast<WorkoutSet>(),
      );
    }

    // Original schema. Every set shared the same reps and durations, so fan the
    // values out into the current per-set model.
    migratedLegacyData = true;
    final reps = (fields[1] as num?)?.toInt() ?? 0;
    final setCount = (fields[2] as num?)?.toInt() ?? 0;
    final timeOn = (fields[3] as num?)?.toInt() ?? 0;
    final timeOff = (fields[4] as num?)?.toInt() ?? 0;

    return Workout(
      name: fields[0] as String,
      sets: List.generate(
        setCount,
        (index) => WorkoutSet(
          name: 'Set ${index + 1}',
          reps: reps,
          timeOn: timeOn,
          timeOff: timeOff,
        ),
      ),
    );
  }
}
