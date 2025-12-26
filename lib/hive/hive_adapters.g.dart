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
      reps: (fields[1] as num).toInt(),
      sets: (fields[2] as num).toInt(),
      timeOn: (fields[3] as num).toInt(),
      timeOff: (fields[4] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Workout obj) {
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

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutAdapter && runtimeType == other.runtimeType && typeId == other.typeId;
}
