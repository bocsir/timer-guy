// widgets/workout_yaml_actions.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/services/workout_file_drop.dart';
import 'package:timer_guy/services/workout_file_service.dart';
import 'package:timer_guy/services/workout_yaml.dart';
import 'package:timer_guy/widgets/import_workouts_dialog.dart';

/// Exports [workouts] to a YAML file chosen by the user.
Future<void> exportWorkoutsAsYaml(
  BuildContext context,
  List<Workout> workouts,
) async {
  if (workouts.isEmpty) return;

  try {
    final saved = await WorkoutFileService.exportWorkouts(workouts);
    if (!context.mounted || !saved) return;

    showFToast(
      context: context,
      title: Text(
        workouts.length == 1
            ? 'Exported "${workouts.single.name}"'
            : 'Exported ${workouts.length} workouts',
      ),
      description: const Text('Saved as a YAML file.'),
      icon: const Icon(FIcons.download),
    );
  } catch (error) {
    if (!context.mounted) return;
    await _showError(context, 'Could not export workouts', '$error');
  }
}

/// Lets the user import one or more workouts from a YAML file into [box].
Future<void> importWorkoutsFromYaml(
  BuildContext context,
  Box<Workout> box,
) async {
  try {
    final workouts = workoutFileDropSupported
        ? await showImportWorkoutsDialog(context)
        : await WorkoutFileService.importWorkouts();
    if (workouts == null) return;
    if (workouts.isEmpty) {
      throw const WorkoutYamlException(
        'The file does not contain any workouts.',
      );
    }

    await box.addAll(workouts);
    if (!context.mounted) return;

    showFToast(
      context: context,
      title: Text(
        workouts.length == 1
            ? 'Imported 1 workout'
            : 'Imported ${workouts.length} workouts',
      ),
      description: Text(workouts.map((workout) => workout.name).join(', ')),
      icon: const Icon(FIcons.upload),
    );
  } on WorkoutYamlException catch (error) {
    if (!context.mounted) return;
    await _showError(context, 'Could not import workout', error.message);
  } catch (error) {
    if (!context.mounted) return;
    await _showError(context, 'Could not import workout', '$error');
  }
}

Future<void> _showError(BuildContext context, String title, String message) {
  return showFDialog<void>(
    context: context,
    builder: (context, _, animation) => FDialog(
      animation: animation,
      title: Text(title),
      body: Text(message),
      actions: [
        FButton(
          onPress: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}
