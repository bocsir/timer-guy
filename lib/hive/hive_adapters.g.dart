// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class WorkoutAdapter extends TypeAdapter<Workout> {
  @override
  final typeId = 0;

  @override
  Workout read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Workout(
      name: fields[0] as String,
      sets: (fields[2] as List).cast<WorkoutSet>(),
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.sets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSetAdapter extends TypeAdapter<WorkoutSet> {
  @override
  final typeId = 1;

  @override
  WorkoutSet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSet(
      name: fields[4] as String,
      reps: (fields[0] as num).toInt(),
      timeOn: (fields[1] as num).toInt(),
      timeOff: (fields[2] as num).toInt(),
      enableGetReady: fields[3] == null ? false : fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.reps)
      ..writeByte(1)
      ..write(obj.timeOn)
      ..writeByte(2)
      ..write(obj.timeOff)
      ..writeByte(3)
      ..write(obj.enableGetReady)
      ..writeByte(4)
      ..write(obj.name);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutSessionAdapter extends TypeAdapter<WorkoutSession> {
  @override
  final typeId = 2;

  @override
  WorkoutSession read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return WorkoutSession(
      workoutKey: (fields[0] as num).toInt(),
      date: fields[1] as DateTime,
      durationSeconds: (fields[2] as num).toInt(),
      completed: fields[3] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSession obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.workoutKey)
      ..writeByte(1)
      ..write(obj.date)
      ..writeByte(2)
      ..write(obj.durationSeconds)
      ..writeByte(3)
      ..write(obj.completed);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
