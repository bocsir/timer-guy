// widgets/import_workouts_dialog.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/services/workout_file_drop.dart';
import 'package:timer_guy/services/workout_file_service.dart';
import 'package:timer_guy/services/workout_yaml.dart';

/// Shows a dialog that lets the user choose a YAML file to import.
///
/// On the web, files can also be dragged from the operating system and dropped
/// anywhere in the browser window. Returns the parsed workouts, or null when
/// the dialog is dismissed.
Future<List<Workout>?> showImportWorkoutsDialog(BuildContext context) {
  return showFDialog<List<Workout>>(
    context: context,
    builder: (context, _, animation) =>
        ImportWorkoutsDialog(animation: animation),
  );
}

class ImportWorkoutsDialog extends StatefulWidget {
  const ImportWorkoutsDialog({super.key, this.animation});

  final Animation<double>? animation;

  @override
  State<ImportWorkoutsDialog> createState() => _ImportWorkoutsDialogState();
}

class _ImportWorkoutsDialogState extends State<ImportWorkoutsDialog> {
  WorkoutFileDropSubscription? _dropSubscription;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (workoutFileDropSupported) {
      _dropSubscription = listenForDroppedWorkoutFiles(_importDroppedFile);
    }
  }

  @override
  void dispose() {
    _dropSubscription?.cancel();
    super.dispose();
  }

  Future<void> _importDroppedFile(DroppedWorkoutFile file) {
    return _import(
      () async => WorkoutFileService.workoutsFromBytes(file.bytes),
    );
  }

  Future<void> _browse() {
    return _import(WorkoutFileService.importWorkouts);
  }

  Future<void> _import(Future<List<Workout>?> Function() load) async {
    if (_busy) return;

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final workouts = await load();
      if (!mounted) return;
      if (workouts == null) {
        setState(() => _busy = false);
        return;
      }

      Navigator.of(context).pop(workouts);
    } on WorkoutYamlException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return FDialog(
      animation: widget.animation,
      title: const Text('Import workouts'),
      body: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 12,
        children: [
          GestureDetector(
            onTap: _busy ? null : _browse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors.border, width: 1.5),
                color: colors.secondary,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(
                      FIcons.upload,
                      size: 32,
                      color: colors.mutedForeground,
                    ),
                  Text(
                    _busy ? 'Reading file…' : 'Drag & drop a YAML file here',
                    textAlign: TextAlign.center,
                    style: typography.base,
                  ),
                  Text(
                    workoutFileDropSupported
                        ? 'or click to choose a file'
                        : 'Tap to choose a file',
                    textAlign: TextAlign.center,
                    style: typography.sm.copyWith(
                      color: colors.mutedForeground,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_error case final error?)
            Text(error, style: typography.sm.copyWith(color: colors.error)),
        ],
      ),
      actions: [
        FButton(
          style: FButtonStyle.outline(),
          onPress: _busy ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}
