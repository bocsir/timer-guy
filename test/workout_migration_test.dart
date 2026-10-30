import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/hive/register_adapters.dart';
import 'package:timer_guy/hive/workout_adapter.dart';
import 'package:timer_guy/hive/workout_set_adapter.dart';
import 'package:timer_guy/models/workout.dart';

/// Writes records using the schema from before `Workout.sets` became a list:
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
/// Workout: 0: name, 2: sets
/// WorkoutSet: 0: reps, 1: timeOn, 2: timeOff, 3: enableGetReady, 4: name.
class SetCreatorWorkout {
  SetCreatorWorkout(this.name, this.sets);
  final String name;
  final List<SetCreatorSet> sets;
}

class SetCreatorSet {
  SetCreatorSet(this.name, this.reps, this.timeOn, this.timeOff);
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
      ..write(obj.sets);
  }
}

class SetCreatorSetAdapter extends TypeAdapter<SetCreatorSet> {
  @override
  final typeId = 1;

  @override
  SetCreatorSet read(BinaryReader reader) => throw UnimplementedError();

  @override
  void write(BinaryWriter writer, SetCreatorSet obj) {
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
    expect(workout.sets, hasLength(2));
    expect(workout.sets.first.name, 'Set 1');
    expect(workout.sets.first.reps, 6);
    expect(workout.sets.first.timeOn, 10);
    expect(workout.sets.first.timeOff, 20);
    expect(workout.sets.last.name, 'Set 2');
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
    expect(reopened.values.single.sets, hasLength(2));
    expect(reopened.values.single.sets.first.name, 'Set 1');
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
    Hive.registerAdapter(SetCreatorSetAdapter());
    final legacyBox = await Hive.openBox<SetCreatorWorkout>(workoutBox);
    await legacyBox.add(
      SetCreatorWorkout('emil', [
        SetCreatorSet('Warmup', 6, 10, 20),
        SetCreatorSet('Work', 8, 30, 15),
      ]),
    );
    await legacyBox.close();

    // Reopen it with the current adapters, as the app does on startup.
    Hive.resetAdapters();
    registerAdapters();

    final box = await Hive.openBox<Workout>(workoutBox);
    final workout = box.values.single;

    expect(workout.name, 'emil');
    expect(workout.sets, hasLength(2));
    expect(workout.sets.first.name, 'Warmup');
    expect(workout.sets.first.reps, 6);
    expect(workout.sets.first.timeOn, 10);
    expect(workout.sets.first.timeOff, 20);
    expect(workout.sets.last.name, 'Work');
    expect(MigratingWorkoutSetAdapter.migratedLegacyData, isTrue);

    // Persist the converted records, then reopen to check they are in the
    // current format.
    await box.putAll({
      for (final entry in box.toMap().entries) entry.key: entry.value,
    });
    await box.compact();
    await box.close();

    MigratingWorkoutSetAdapter.migratedLegacyData = false;
    final reopened = await Hive.openBox<Workout>(workoutBox);
    expect(reopened.values.single.sets.first.name, 'Warmup');
    expect(reopened.values.single.sets.last.reps, 8);
    expect(MigratingWorkoutSetAdapter.migratedLegacyData, isFalse);

    await reopened.close();
    await Hive.close();
    dir.deleteSync(recursive: true);
  });
}
