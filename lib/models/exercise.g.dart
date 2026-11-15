// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ExerciseAdapter extends TypeAdapter<Exercise> {
  @override
  final typeId = 1;

  @override
  Exercise read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Exercise(
      name: fields[0] as String,
      reps: (fields[1] as num).toInt(),
      timeOn: (fields[2] as num).toInt(),
      timeOff: (fields[3] as num).toInt(),
      type: fields[5] as ExerciseType,
      sets: fields[4] == null ? 1 : (fields[4] as num).toInt(),
      description: fields[6] as String?,
      restBetweenSets: fields[7] == null ? 0 : (fields[7] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Exercise obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.reps)
      ..writeByte(2)
      ..write(obj.timeOn)
      ..writeByte(3)
      ..write(obj.timeOff)
      ..writeByte(4)
      ..write(obj.sets)
      ..writeByte(5)
      ..write(obj.type)
      ..writeByte(6)
      ..write(obj.description)
      ..writeByte(7)
      ..write(obj.restBetweenSets);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ExerciseTypeAdapter extends TypeAdapter<ExerciseType> {
  @override
  final typeId = 3;

  @override
  ExerciseType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ExerciseType.interval;
      case 1:
        return ExerciseType.reps;
      default:
        return ExerciseType.interval;
    }
  }

  @override
  void write(BinaryWriter writer, ExerciseType obj) {
    switch (obj) {
      case ExerciseType.interval:
        writer.writeByte(0);
      case ExerciseType.reps:
        writer.writeByte(1);
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
