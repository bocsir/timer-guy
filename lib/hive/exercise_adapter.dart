// hive/exercise_adapter.dart
//
// Exercise replaced WorkoutSet while keeping Hive type id 1, so existing boxes
// still contain records in one of the old layouts:
//
// Current:
//   0: name, 1: reps, 2: timeOn, 3: timeOff, 4: sets, 5: type, 6: description
//
// Previous:
//   0: name, 1: reps, 2: timeOn, 3: timeOff
//
// set-creator branch:
//   0: reps, 1: timeOn, 2: timeOff, 3: enableGetReady, 4: name
//
// The generated adapter only understands the current layout, so this adapter
// detects all three and converts records on read. `main` rewrites the box when
// [migratedLegacyData] is true.
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/models/exercise.dart';

class MigratingExerciseAdapter extends ExerciseAdapter {
  /// Whether [read] encountered an exercise written with an old layout.
  static bool migratedLegacyData = false;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };

    // Current schema stores the exercise type in field 5.
    if (fields[5] is ExerciseType) {
      return Exercise(
        name: fields[0] as String,
        reps: (fields[1] as num?)?.toInt() ?? 0,
        timeOn: (fields[2] as num?)?.toInt() ?? 0,
        timeOff: (fields[3] as num?)?.toInt() ?? 0,
        sets: (fields[4] as num?)?.toInt() ?? 1,
        type: fields[5] as ExerciseType,
        description: fields[6] as String?,
      );
    }

    // Previous schema stores the name in field 0 and reps in field 1.
    if (fields[0] is String) {
      migratedLegacyData = true;
      return Exercise(
        name: fields[0] as String,
        reps: (fields[1] as num?)?.toInt() ?? 0,
        timeOn: (fields[2] as num?)?.toInt() ?? 0,
        timeOff: (fields[3] as num?)?.toInt() ?? 0,
        type: ExerciseType.interval,
      );
    }

    // set-creator schema stores the name in field 4.
    migratedLegacyData = true;
    return Exercise(
      name: fields[4] as String? ?? 'Exercise',
      reps: (fields[0] as num?)?.toInt() ?? 0,
      timeOn: (fields[1] as num?)?.toInt() ?? 0,
      timeOff: (fields[2] as num?)?.toInt() ?? 0,
      type: ExerciseType.interval,
    );
  }
}
