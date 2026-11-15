// services/workout_yaml.dart
import 'dart:convert';

import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:yaml/yaml.dart';

/// Version of the YAML schema written by [workoutToYaml].
///
/// Imports currently accept any version; unknown fields are ignored so files
/// written by newer versions still load when the schema is backwards
/// compatible.
const workoutYamlVersion = 1;

/// Thrown when a workout YAML file cannot be parsed.
class WorkoutYamlException implements Exception {
  const WorkoutYamlException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Serializes a single [workout] to a human-editable YAML document.
String workoutToYaml(Workout workout) {
  final buffer = StringBuffer()
    ..writeln('# Timer Guy workout')
    ..writeln('version: $workoutYamlVersion');
  _writeWorkout(buffer, workout);
  return buffer.toString();
}

/// Serializes [workouts] to a human-editable YAML document.
///
/// A single workout is written using the same format as [workoutToYaml]. Two
/// or more workouts are written under a top-level `workouts` list, which
/// [workoutsFromYaml] can read back.
String workoutsToYaml(List<Workout> workouts) {
  if (workouts.isEmpty) {
    throw const WorkoutYamlException('There are no workouts to export.');
  }
  if (workouts.length == 1) {
    return workoutToYaml(workouts.single);
  }

  final buffer = StringBuffer()
    ..writeln('# Timer Guy workouts')
    ..writeln('version: $workoutYamlVersion')
    ..writeln('workouts:');

  for (var i = 0; i < workouts.length; i++) {
    if (i > 0) buffer.writeln();
    _writeWorkout(buffer, workouts[i], indent: '    ', firstLinePrefix: '  - ');
  }

  return buffer.toString();
}

/// Parses one or more workouts from [source].
///
/// The document can be a single workout mapping, a list of mappings, or a
/// mapping containing a `workouts` list. This makes it possible to import both
/// single-workout files and files exported with [workoutsToYaml].
List<Workout> workoutsFromYaml(String source) {
  final dynamic document;
  try {
    document = loadYaml(source);
  } on YamlException catch (error) {
    throw WorkoutYamlException('Could not read YAML: ${error.message}');
  }

  if (document == null) {
    throw const WorkoutYamlException('The file is empty.');
  }

  final List<dynamic> nodes;
  if (document is Map && document.containsKey('workouts')) {
    final workouts = document['workouts'];
    if (workouts == null) {
      nodes = const [];
    } else if (workouts is! List) {
      throw const WorkoutYamlException('"workouts" must be a list.');
    } else {
      nodes = workouts;
    }
  } else if (document is List) {
    nodes = document;
  } else {
    nodes = [document];
  }

  if (nodes.isEmpty) {
    throw const WorkoutYamlException('The file does not contain any workouts.');
  }

  return [
    for (var i = 0; i < nodes.length; i++)
      _workoutFromNode(nodes[i], nodes.length > 1 ? i + 1 : null),
  ];
}

void _writeWorkout(
  StringBuffer buffer,
  Workout workout, {
  String indent = '',
  String firstLinePrefix = '',
}) {
  buffer.writeln(
    '${firstLinePrefix.isEmpty ? indent : firstLinePrefix}'
    'name: ${_scalar(workout.name)}',
  );

  final description = workout.description;
  if (description != null && description.trim().isNotEmpty) {
    buffer.writeln('${indent}description: ${_scalar(description)}');
  }

  if (workout.exercises.isEmpty) {
    buffer.writeln('${indent}exercises: []');
    return;
  }

  buffer.writeln('${indent}exercises:');
  for (final exercise in workout.exercises) {
    final exerciseIndent = '$indent  ';
    buffer
      ..writeln('$exerciseIndent- name: ${_scalar(exercise.name)}')
      ..writeln('$exerciseIndent  type: ${exercise.type.name}');

    final exerciseDescription = exercise.description;
    if (exerciseDescription != null && exerciseDescription.trim().isNotEmpty) {
      buffer.writeln(
        '$exerciseIndent  description: ${_scalar(exerciseDescription)}',
      );
    }

    if (exercise.isInterval) {
      buffer
        ..writeln('$exerciseIndent  sets: ${exercise.sets}')
        ..writeln('$exerciseIndent  reps: ${exercise.reps}')
        ..writeln('$exerciseIndent  time_on: ${exercise.timeOn}')
        ..writeln('$exerciseIndent  time_off: ${exercise.timeOff}')
        ..writeln(
          '$exerciseIndent  rest_between_sets: ${exercise.restBetweenSets}',
        );
    } else {
      buffer
        ..writeln('$exerciseIndent  sets: ${exercise.sets}')
        ..writeln('$exerciseIndent  reps: ${exercise.reps}')
        ..writeln('$exerciseIndent  time_off: ${exercise.timeOff}');
    }
  }
}

Workout _workoutFromNode(dynamic node, int? number) {
  final label = number == null ? 'Workout' : 'Workout $number';
  if (node is! Map) {
    throw WorkoutYamlException('$label: expected a mapping.');
  }

  final name = _requiredString(node, const ['name'], label);
  final description = _optionalString(node, const ['description'], label);

  final rawExercises = _value(node, const ['exercises']);
  if (rawExercises != null && rawExercises is! List) {
    throw WorkoutYamlException('$label: "exercises" must be a list.');
  }

  final exercises = <Exercise>[];
  if (rawExercises is List) {
    for (var i = 0; i < rawExercises.length; i++) {
      exercises.add(_exerciseFromNode(rawExercises[i], i, label));
    }
  }

  return Workout(
    name: name,
    exercises: exercises,
    description: description == null || description.trim().isEmpty
        ? null
        : description,
  );
}

Exercise _exerciseFromNode(dynamic node, int index, String workoutLabel) {
  final label = '$workoutLabel, exercise ${index + 1}';
  if (node is! Map) {
    throw WorkoutYamlException('$label: expected a mapping.');
  }

  final name = _requiredString(node, const ['name'], label);
  final type = _exerciseType(node, label);
  final rawDescription = _optionalString(node, const ['description'], label);
  final description = rawDescription == null || rawDescription.trim().isEmpty
      ? null
      : rawDescription.trim();
  final reps = _requiredInt(node, const ['reps'], label);
  if (reps < 1) {
    throw WorkoutYamlException('$label: "reps" must be at least 1.');
  }

  final timeOff = _optionalInt(node, const ['time_off', 'timeOff'], label) ?? 0;
  if (timeOff < 0) {
    throw WorkoutYamlException('$label: "time_off" cannot be negative.');
  }

  final sets = _optionalInt(node, const ['sets'], label) ?? 1;
  if (sets < 1) {
    throw WorkoutYamlException('$label: "sets" must be at least 1.');
  }

  if (type == ExerciseType.interval) {
    final timeOn = _optionalInt(node, const ['time_on', 'timeOn'], label) ?? 0;
    if (timeOn < 0) {
      throw WorkoutYamlException('$label: "time_on" cannot be negative.');
    }

    final restBetweenSets =
        _optionalInt(node, const [
          'rest_between_sets',
          'restBetweenSets',
        ], label) ??
        0;
    if (restBetweenSets < 0) {
      throw WorkoutYamlException(
        '$label: "rest_between_sets" cannot be negative.',
      );
    }

    return Exercise(
      name: name,
      reps: reps,
      timeOn: timeOn,
      timeOff: timeOff,
      sets: sets,
      restBetweenSets: restBetweenSets,
      type: type,
      description: description,
    );
  }

  return Exercise(
    name: name,
    reps: reps,
    timeOn: 0,
    timeOff: timeOff,
    sets: sets,
    type: type,
    description: description,
  );
}

ExerciseType _exerciseType(Map<dynamic, dynamic> map, String label) {
  final rawType = _value(map, const ['type']);

  if (rawType == null) {
    // Older files may not have a type. A work interval implies an interval
    // exercise; otherwise treat it as sets & reps.
    return _value(map, const ['time_on', 'timeOn']) != null
        ? ExerciseType.interval
        : ExerciseType.reps;
  }

  if (rawType is! String) {
    throw WorkoutYamlException('$label: "type" must be "interval" or "reps".');
  }

  return switch (rawType.trim().toLowerCase()) {
    'interval' => ExerciseType.interval,
    'reps' || 'sets' || 'sets & reps' => ExerciseType.reps,
    _ => throw WorkoutYamlException(
      '$label: unknown exercise type "$rawType". '
      'Use "interval" or "reps".',
    ),
  };
}

dynamic _value(Map<dynamic, dynamic> map, List<String> keys) {
  for (final key in keys) {
    if (map.containsKey(key)) {
      return map[key];
    }
  }
  return null;
}

String _requiredString(
  Map<dynamic, dynamic> map,
  List<String> keys,
  String label,
) {
  final value = _value(map, keys);
  if (value == null) {
    throw WorkoutYamlException('$label: "${keys.first}" is required.');
  }
  if (value is! String) {
    throw WorkoutYamlException('$label: "${keys.first}" must be text.');
  }

  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    throw WorkoutYamlException('$label: "${keys.first}" cannot be empty.');
  }
  return trimmed;
}

String? _optionalString(
  Map<dynamic, dynamic> map,
  List<String> keys,
  String label,
) {
  final value = _value(map, keys);
  if (value == null || value is String) {
    return value as String?;
  }
  throw WorkoutYamlException('$label: "${keys.first}" must be text.');
}

int _requiredInt(Map<dynamic, dynamic> map, List<String> keys, String label) {
  final value = _value(map, keys);
  if (value == null) {
    throw WorkoutYamlException('$label: "${keys.first}" is required.');
  }
  return _asInt(value, keys.first, label);
}

int? _optionalInt(Map<dynamic, dynamic> map, List<String> keys, String label) {
  final value = _value(map, keys);
  return value == null ? null : _asInt(value, keys.first, label);
}

int _asInt(dynamic value, String field, String label) {
  if (value is int) return value;
  if (value is double && value.isFinite && value == value.truncateToDouble()) {
    return value.toInt();
  }
  if (value is String) {
    final parsed = int.tryParse(value.trim());
    if (parsed != null) return parsed;
  }

  throw WorkoutYamlException('$label: "$field" must be a whole number.');
}

final _plainScalar = RegExp(r"^[A-Za-z][A-Za-z0-9 _.,'()&+/@-]*$");
const _reservedScalars = {
  'true',
  'false',
  'yes',
  'no',
  'on',
  'off',
  'null',
  '~',
};

/// Emits [value] as a plain scalar when that is unambiguous, or as a
/// double-quoted scalar otherwise.
String _scalar(String value) {
  final isPlain =
      value.isNotEmpty &&
      value == value.trim() &&
      _plainScalar.hasMatch(value) &&
      !_reservedScalars.contains(value.toLowerCase());

  return isPlain ? value : jsonEncode(value);
}
