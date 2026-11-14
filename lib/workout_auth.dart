// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/exercise_auth.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/theme/theme.dart';

class WorkoutAuth extends StatefulWidget {
  final Box<Workout> workoutBox;

  /// The workout being edited. When null, a new workout is created.
  final Workout? workout;

  const WorkoutAuth({super.key, required this.workoutBox, this.workout});

  bool get isEditing => workout != null;

  @override
  State<WorkoutAuth> createState() => _WorkoutAuthState();
}

class _WorkoutAuthState extends State<WorkoutAuth> {
  late List<Exercise> exercises;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;

  final _formKey = GlobalKey<FormState>();
  bool _formSubmitted = false;

  @override
  void initState() {
    super.initState();
    final workout = widget.workout;
    exercises = workout == null ? [] : List.of(workout.exercises);
    nameController = TextEditingController(text: workout?.name ?? '');
    descriptionController = TextEditingController(
      text: workout?.description ?? '',
    );
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;

    return FScaffold(
      header: Header(backBtnText: 'Cancel'),
      footer: Padding(
        padding: const EdgeInsets.all(16),
        child: FButton(
          style: FButtonStyle.ghost(),
          onPress: _onDonePressed,
          child: Text(
            'Done!',
            style: typography.lg.copyWith(color: context.theme.colors.accent),
          ),
        ),
      ),

      child: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        onReorder: _reorderExercises,
        header: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 8,
            children: [
              Text(
                widget.isEditing ? 'Edit Workout' : 'Create Workout',
                style: typography.xl3Semibold,
              ),
              FTextFormField(
                label: Text('Workout Name', style: typography.lg),
                controller: nameController,
                validator: _validateRequired,
                autovalidateMode: _formSubmitted
                    ? AutovalidateMode.onUserInteraction
                    : AutovalidateMode.disabled,
              ),
              FTextFormField(
                label: Text('Description', style: typography.lg),
                hint: 'Optional',
                controller: descriptionController,
                maxLines: 3,
                minLines: 2,
                textInputAction: TextInputAction.newline,
              ),
              if (exercises.isNotEmpty)
                Text('Exercises', style: typography.lgSemibold),
            ],
          ),
        ),
        itemCount: exercises.length,
        itemBuilder: (context, i) => _buildExerciseRow(context, i),
        footer: Padding(
          padding: const EdgeInsets.only(top: 16),
          child: FButton(
            style: FButtonStyle.outline(),
            onPress: () async {
              final index = exercises.length;
              final newExercise = await showExerciseAuthSheet(
                index,
                Exercise(
                  name: '',
                  reps: 1,
                  timeOn: 0,
                  timeOff: 0,
                  sets: 3,
                  type: ExerciseType.interval,
                ),
              );
              if (newExercise != null) {
                upsertExercise(index, newExercise);
              }
            },
            child: Text('Add Exercise', style: typography.lg),
          ),
        ),
      ),
    );
  }

  Widget _buildExerciseRow(BuildContext context, int i) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final exercise = exercises[i];

    return Padding(
      key: ObjectKey(exercise),
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ReorderableDragStartListener(
            index: i,
            child: Tooltip(
              message: 'Drag to reorder',
              child: Padding(
                padding: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
                child: Icon(FIcons.gripVertical, color: colors.mutedForeground),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(exercise.name, style: typography.sm),
                Text(_exerciseSummary(exercise), style: typography.smGrey),
                if (exercise.description case final description?
                    when description.isNotEmpty)
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: typography.smGrey,
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Tooltip(
                message: 'Duplicate exercise',
                child: FButton(
                  onPress: () => duplicateExercise(i),
                  style: FButtonStyle.ghost(),
                  child: Icon(FIcons.copy),
                ),
              ),
              FButton(
                onPress: () async {
                  final updated = await showExerciseAuthSheet(i, exercise);
                  if (updated != null) {
                    upsertExercise(i, updated);
                  }
                },
                style: FButtonStyle.ghost(),
                child: Icon(FIcons.pencil),
              ),
              FButton(
                onPress: () {
                  setState(() => exercises.removeAt(i));
                },
                style: FButtonStyle.ghost(),
                child: Icon(FIcons.x),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  String _exerciseSummary(Exercise exercise) {
    if (exercise.isInterval) {
      return 'Interval · ${_formatDuration(exercise.timeOn)} work · '
          '${_formatDuration(exercise.timeOff)} rest · '
          '${exercise.reps} ${exercise.reps == 1 ? 'rep' : 'reps'}';
    }

    return '${exercise.sets} ${exercise.sets == 1 ? 'set' : 'sets'} × '
        '${exercise.reps} reps · ${_formatDuration(exercise.timeOff)} rest';
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '${remainingSeconds}s';
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void upsertExercise(int index, Exercise newExercise) {
    setState(() {
      if (index >= exercises.length) {
        exercises.add(newExercise);
      } else {
        exercises[index] = newExercise;
      }
    });
  }

  /// Inserts a copy of [index] directly after the original so it can be tweaked
  /// without rebuilding it from scratch.
  void duplicateExercise(int index) {
    setState(() {
      exercises.insert(index + 1, exercises[index].copyWith());
    });
  }

  void _reorderExercises(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final exercise = exercises.removeAt(oldIndex);
      exercises.insert(newIndex, exercise);
    });
  }

  Future<Exercise?> showExerciseAuthSheet(
    int exerciseIndex,
    Exercise initialExercise,
  ) {
    return showModalBottomSheet<Exercise>(
      backgroundColor: context.theme.colors.secondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      context: context,
      isScrollControlled: true,
      builder: (context) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: ExerciseAuth(
          exercise: initialExercise,
          exerciseNumber: exerciseIndex + 1,
        ),
      ),
      showDragHandle: true,
      useSafeArea: true,
    );
  }

  void _onDonePressed() {
    setState(() {
      _formSubmitted = true;
    });

    if (_validateForm()) {
      final description = descriptionController.text.trim();
      final workout = Workout(
        name: nameController.text.trim(),
        exercises: List.of(exercises),
        description: description.isEmpty ? null : description,
      );
      final existing = widget.workout;
      if (existing == null) {
        widget.workoutBox.add(workout);
      } else {
        widget.workoutBox.put(existing.key, workout);
      }
      Navigator.of(context).pop();
    }
  }

  bool _validateForm() {
    // trigger validator functions on built in form fields (non FPicker fields)
    return _formKey.currentState?.validate() ?? false;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
