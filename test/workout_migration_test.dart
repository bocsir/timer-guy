import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/hive/exercise_adapter.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/hive/register_adapters.dart';
import 'package:timer_guy/hive/workout_adapter.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/models/workout.dart';

/// Writes records using the schema from before `Workout.exercises` became a
/// list of exercises:
/// 0: name, 1: reps, 2: number of sets, 3: timeOn, 4: timeOff.
class LegacyWorkout {
  LegacyWorkout(this.name, this.reps, this.sets, this.timeOn, this.timeOff);
  final String name;
  final int reps;
  final int sets;
  final int timeOn;
  final int timeOff;
}

class LegacyWorkoutAdapter extends TypeAdapter<LegacyWorkout> {
  @override
  final typeId = 0;

  @override
  LegacyWorkout read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, LegacyWorkout obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.sets)
      ..writeByte(3)
      ..write(obj.timeOn)
      ..writeByte(4)
      ..write(obj.timeOff);
  }
}

/// Writes records using the set-creator branch's layout:
/// Workout: 0: name, 2: exercises
/// Exercise: 0: reps, 1: timeOn, 2: timeOff, 3: enableGetReady, 4: name.
class SetCreatorWorkout {
  SetCreatorWorkout(this.name, this.exercises);
  final String name;
  final List<SetCreatorExercise> exercises;
}

class SetCreatorExercise {
  SetCreatorExercise(this.name, this.reps, this.timeOn, this.timeOff);
  final String name;
  final int reps;
  final int timeOn;
  final int timeOff;
}

class SetCreatorWorkoutAdapter extends TypeAdapter<SetCreatorWorkout> {
  @override
  final typeId = 0;

  @override
  SetCreatorWorkout read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, SetCreatorWorkout obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.exercises);
  }
}

class SetCreatorExerciseAdapter extends TypeAdapter<SetCreatorExercise> {
  @override
  final typeId = 1;

  @override
  SetCreatorExercise read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, SetCreatorExercise obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.reps)
      ..writeByte(1)
      ..write(obj.timeOn)
      ..writeByte(2)
      ..write(obj.timeOff)
      ..writeByte(3)
      ..write(false)
      ..writeByte(4)
      ..write(obj.name);
  }
}

/// Writes records using the previous schema, where the workout itself had a
/// type:
/// Workout: 0: name, 1: exercises, 2: description, 3: type
/// Exercise: 0: name, 1: reps, 2: timeOn, 3: timeOff.
enum LegacyWorkoutType { interval, reps }

class TypedWorkout {
  TypedWorkout(this.name, this.exercises, this.type);
  final String name;
  final List<TypedExercise> exercises;
  final LegacyWorkoutType type;
}

class TypedExercise {
  TypedExercise(this.name, this.reps, this.timeOn, this.timeOff);
  final String name;
  final int reps;
  final int timeOn;
  final int timeOff;
}

class TypedWorkoutAdapter extends TypeAdapter<TypedWorkout> {
  @override
  final typeId = 0;

  @override
  TypedWorkout read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, TypedWorkout obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.exercises)
      ..writeByte(2)
      ..write(null)
      ..writeByte(3)
      ..write(obj.type);
  }
}

class TypedExerciseAdapter extends TypeAdapter<TypedExercise> {
  @override
  final typeId = 1;

  @override
  TypedExercise read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, TypedExercise obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.timeOn)
      ..writeByte(3)
      ..write(obj.timeOff);
  }
}

class LegacyWorkoutTypeAdapter extends TypeAdapter<LegacyWorkoutType> {
  @override
  final typeId = 3;

  @override
  LegacyWorkoutType read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, LegacyWorkoutType obj) {
    writer.writeByte(obj.index);
  }
}

void main() {
  test('reads and rewrites legacy workout records', () async {
    final dir = Directory.systemTemp.createTempSync('timer_guy_hive_test');

    // Create a box using the old schema.
    Hive.init(dir.path);
    Hive.resetAdapters();
    Hive.registerAdapter(LegacyWorkoutAdapter());
    final legacyBox = await Hive.openBox<LegacyWorkout>(workoutBox);
    await legacyBox.add(LegacyWorkout('emil', 6, 2, 10, 20));
    await legacyBox.close();

    // Reopen it with the current adapters, as the app does on startup.
    Hive.resetAdapters();
    registerAdapters();

    final box = await Hive.openBox<Workout>(workoutBox);
    final workout = box.values.single;

    expect(workout.name, 'emil');
    expect(workout.exercises, hasLength(2));
    expect(workout.exercises.first.name, 'Set 1');
    expect(workout.exercises.first.reps, 6);
    expect(workout.exercises.first.timeOn, 10);
    expect(workout.exercises.first.timeOff, 20);
    expect(workout.exercises.first.sets, 1);
    expect(workout.exercises.first.type, ExerciseType.interval);
    expect(workout.exercises.last.name, 'Set 2');
    expect(MigratingWorkoutAdapter.migratedLegacyData, isTrue);

    // Persist the converted records, then reopen to check they are in the
    // current format.
    await box.putAll({
      for (final entry in box.toMap().entries) entry.key: entry.value,
    });
    await box.compact();
    await box.close();

    MigratingWorkoutAdapter.migratedLegacyData = false;
    final reopened = await Hive.openBox<Workout>(workoutBox);
    expect(reopened.values.single.exercises, hasLength(2));
    expect(reopened.values.single.exercises.first.name, 'Set 1');
    expect(MigratingWorkoutAdapter.migratedLegacyData, isFalse);

    await reopened.close();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('reads and rewrites set-creator workout records', () async {
    final dir = Directory.systemTemp.createTempSync('timer_guy_hive_test');

    // Create a box using the set-creator branch's schema.
    Hive.init(dir.path);
    Hive.resetAdapters();
    Hive.registerAdapter(SetCreatorWorkoutAdapter());
    Hive.registerAdapter(SetCreatorExerciseAdapter());
    final legacyBox = await Hive.openBox<SetCreatorWorkout>(workoutBox);
    await legacyBox.add(
      SetCreatorWorkout('emil', [
        SetCreatorExercise('Warmup', 6, 10, 20),
        SetCreatorExercise('Work', 8, 30, 15),
      ]),
    );
    await legacyBox.close();

    // Reopen it with the current adapters, as the app does on startup.
    Hive.resetAdapters();
    registerAdapters();

    final box = await Hive.openBox<Workout>(workoutBox);
    final workout = box.values.single;

    expect(workout.name, 'emil');
    expect(workout.exercises, hasLength(2));
    expect(workout.exercises.first.name, 'Warmup');
    expect(workout.exercises.first.reps, 6);
    expect(workout.exercises.first.timeOn, 10);
    expect(workout.exercises.first.timeOff, 20);
    expect(workout.exercises.first.type, ExerciseType.interval);
    expect(workout.exercises.last.name, 'Work');
    expect(MigratingExerciseAdapter.migratedLegacyData, isTrue);

    // Persist the converted records, then reopen to check they are in the
    // current format.
    await box.putAll({
      for (final entry in box.toMap().entries) entry.key: entry.value,
    });
    await box.compact();
    await box.close();

    MigratingExerciseAdapter.migratedLegacyData = false;
    final reopened = await Hive.openBox<Workout>(workoutBox);
    expect(reopened.values.single.exercises.first.name, 'Warmup');
    expect(reopened.values.single.exercises.last.reps, 8);
    expect(MigratingExerciseAdapter.migratedLegacyData, isFalse);

    await reopened.close();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('moves the workout-level type onto each exercise', () async {
    final dir = Directory.systemTemp.createTempSync('timer_guy_hive_test');

    Hive.init(dir.path);
    Hive.resetAdapters();
    Hive.registerAdapter(TypedWorkoutAdapter());
    Hive.registerAdapter(TypedExerciseAdapter());
    Hive.registerAdapter(LegacyWorkoutTypeAdapter());
    final legacyBox = await Hive.openBox<TypedWorkout>(workoutBox);
    await legacyBox.add(
      TypedWorkout('strength', [
        TypedExercise('Push Ups', 12, 0, 90),
        TypedExercise('Squats', 10, 0, 60),
      ], LegacyWorkoutType.reps),
    );
    await legacyBox.close();

    Hive.resetAdapters();
    registerAdapters();

    final box = await Hive.openBox<Workout>(workoutBox);
    final workout = box.values.single;

    expect(workout.exercises, hasLength(2));
    expect(workout.exercises.first.type, ExerciseType.reps);
    expect(workout.exercises.last.type, ExerciseType.reps);
    expect(workout.exercises.first.reps, 12);
    expect(MigratingWorkoutAdapter.migratedLegacyData, isTrue);

    await box.putAll({
      for (final entry in box.toMap().entries) entry.key: entry.value,
    });
    await box.compact();
    await box.close();

    MigratingWorkoutAdapter.migratedLegacyData = false;
    final reopened = await Hive.openBox<Workout>(workoutBox);
    final reopenedWorkout = reopened.values.single;
    expect(reopenedWorkout.exercises.first.type, ExerciseType.reps);
    expect(reopenedWorkout.exercises.last.type, ExerciseType.reps);
    expect(MigratingWorkoutAdapter.migratedLegacyData, isFalse);

    await reopened.close();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });

  test('persists per-exercise types and set counts', () async {
    final dir = Directory.systemTemp.createTempSync('timer_guy_hive_test');

    Hive.init(dir.path);
    Hive.resetAdapters();
    registerAdapters();

    final box = await Hive.openBox<Workout>(workoutBox);
    await box.add(
      Workout(
        name: 'mixed',
        exercises: [
          Exercise(
            name: 'Plank',
            reps: 4,
            timeOn: 30,
            timeOff: 15,
            sets: 2,
            restBetweenSets: 30,
            type: ExerciseType.interval,
          ),
          Exercise(
            name: 'Push Ups',
            reps: 12,
            timeOn: 0,
            timeOff: 90,
            sets: 3,
            type: ExerciseType.reps,
          ),
        ],
      ),
    );
    await box.close();

    final reopened = await Hive.openBox<Workout>(workoutBox);
    final workout = reopened.values.single;

    expect(workout.exercises, hasLength(2));
    expect(workout.exercises.first.isInterval, isTrue);
    expect(workout.exercises.first.sets, 2);
    expect(workout.exercises.first.restBetweenSets, 30);
    expect(workout.exercises.last.isReps, isTrue);
    expect(workout.exercises.last.name, 'Push Ups');
    expect(workout.exercises.last.reps, 12);
    expect(workout.exercises.last.sets, 3);
    expect(workout.exercises.last.timeOff, 90);
    expect(workout.totalSets, 5);
    expect(workout.totalReps, 4 * 2 + 12 * 3);

    await reopened.close();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });
}
