// hive/workout_set_adapter.dart
//
// WorkoutSet has existed in two layouts:
//
// Current:
//   0: name, 1: reps, 2: timeOn, 3: timeOff
//
// set-creator branch:
//   0: reps, 1: timeOn, 2: timeOff, 3: enableGetReady, 4: name
//
// The generated adapter only understands the current layout, so this adapter
// detects both and converts records on read. `main` rewrites the box when
// [migratedLegacyData] is true.
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/models/workout.dart';

class MigratingWorkoutSetAdapter extends WorkoutSetAdapter {
  /// Whether [read] encountered a set written with the old layout.
  static bool migratedLegacyData = false;

  @override
  WorkoutSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Current schema stores the name in field 0.
    if (fields[0] is String) {
      return WorkoutSet(
        name: fields[0] as String,
        reps: (fields[1] as num?)?.toInt() ?? 0,
        timeOn: (fields[2] as num?)?.toInt() ?? 0,
        timeOff: (fields[3] as num?)?.toInt() ?? 0,
      );
    }

    // set-creator schema stores the name in field 4.
    migratedLegacyData = true;
    return WorkoutSet(
      name: fields[4] as String? ?? 'Set',
      reps: (fields[0] as num?)?.toInt() ?? 0,
      timeOn: (fields[1] as num?)?.toInt() ?? 0,
      timeOff: (fields[2] as num?)?.toInt() ?? 0,
    );
  }
}
