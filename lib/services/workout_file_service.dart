// services/workout_file_service.dart
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/services/workout_yaml.dart';

/// Reads and writes workout YAML files using the platform file picker.
class WorkoutFileService {
  const WorkoutFileService._();

  /// Lets the user save [workouts] as a YAML file.
  ///
  /// Returns true when a file was saved. On the web this triggers a download.
  static Future<bool> exportWorkouts(List<Workout> workouts) async {
    final single = workouts.length == 1 ? workouts.single : null;
    final uri = await FilePicker.saveFile(
      dialogTitle: single == null ? 'Export workouts' : 'Export workout',
      fileName: single == null
          ? 'workouts.yaml'
          : '${_fileStem(single.name)}.yaml',
      bytes: Uint8List.fromList(utf8.encode(workoutsToYaml(workouts))),
      mimeType: 'application/yaml',
    );

    return uri != null;
  }

  /// Lets the user choose a YAML file and returns the workouts it contains.
  ///
  /// Returns null when the user cancels the picker.
  static Future<List<Workout>?> importWorkouts() async {
    final file = await FilePicker.pickFile(
      dialogTitle: 'Import workouts',
      type: FileType.custom,
      allowedExtensions: const ['yaml', 'yml'],
    );
    if (file == null) return null;

    final String source;
    try {
      source = utf8.decode(await file.readAsBytes());
    } on FormatException {
      throw const WorkoutYamlException(
        'The selected file is not valid UTF-8 text.',
      );
    }

    return workoutsFromYaml(source);
  }

  static String _fileStem(String name) {
    final stem = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return stem.isEmpty ? 'workout' : stem;
  }
}
