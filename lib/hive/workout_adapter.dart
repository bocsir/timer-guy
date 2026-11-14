// hive/workout_adapter.dart
//
// Workout used to store a single reps/duration triple:
//   0: name, 1: reps, 2: number of sets, 3: timeOn, 4: timeOff
//
// It then stored a list of WorkoutSet objects in field 1, later adding a
// workout-level type in field 3. Workouts now store a list of Exercise objects
// in field 1, and each exercise carries its own type.
//
// This adapter understands all three layouts and converts old records on the
// fly. It is hand-written so running build_runner does not remove the migration.
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/models/exercise.dart';
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

    // Current schema: field 1 is a list of Exercise objects. Field 3 is only
    // present on records written before types moved down to exercises, where it
    // held the type shared by every set in the workout.
    final exercises = fields[1];
    if (exercises is List) {
      var converted = exercises.cast<Exercise>();
      final legacyType = fields[3];

      if (legacyType is ExerciseType) {
        migratedLegacyData = true;
        converted = converted
            .map((exercise) => exercise.copyWith(type: legacyType, sets: 1))
            .toList();
      }

      return Workout(
        name: fields[0] as String,
        exercises: converted,
        description: fields[2] as String?,
      );
    }

    // An intermediate schema stored the exercise list in field 2.
    final legacyExercises = fields[2];
    if (legacyExercises is List) {
      migratedLegacyData = true;
      return Workout(
        name: fields[0] as String,
        exercises: legacyExercises.cast<Exercise>(),
      );
    }

    // Original schema. Every set shared the same reps and durations, so fan the
    // values out into the current per-exercise model.
    migratedLegacyData = true;
    final reps = (fields[1] as num?)?.toInt() ?? 0;
    final setCount = (fields[2] as num?)?.toInt() ?? 0;
    final timeOn = (fields[3] as num?)?.toInt() ?? 0;
    final timeOff = (fields[4] as num?)?.toInt() ?? 0;

    return Workout(
      name: fields[0] as String,
      exercises: List.generate(
        setCount,
        (index) => Exercise(
          name: 'Set ${index + 1}',
          reps: reps,
          timeOn: timeOn,
          timeOff: timeOff,
          type: ExerciseType.interval,
        ),
      ),
    );
  }
}
