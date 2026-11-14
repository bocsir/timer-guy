// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout.dart';

// **************************************************************************
// TypeAdapterGenerator
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
      sets: (fields[1] as List).cast<WorkoutSet>(),
      description: fields[2] as String?,
      type: fields[3] == null ? WorkoutType.interval : fields[3] as WorkoutType,
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.sets)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.type);
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
      name: fields[0] as String,
      reps: (fields[1] as num).toInt(),
      timeOn: (fields[2] as num).toInt(),
      timeOff: (fields[3] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, WorkoutSet obj) {
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutSetAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class WorkoutTypeAdapter extends TypeAdapter<WorkoutType> {
  @override
  final typeId = 3;

  @override
  WorkoutType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return WorkoutType.interval;
      case 1:
        return WorkoutType.reps;
      default:
        return WorkoutType.interval;
    }
  }

  @override
  void write(BinaryWriter writer, WorkoutType obj) {
    switch (obj) {
      case WorkoutType.interval:
        writer.writeByte(0);
      case WorkoutType.reps:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
