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

      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: 16,
          children: [
            Form(
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
                  for (var i = 0; i < exercises.length; i++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                exercises[i].name,
                                style: context.theme.typography.sm,
                              ),
                              Text(
                                _exerciseSummary(exercises[i]),
                                style: typography.smGrey,
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            FButton(
                              onPress: () async {
                                final updated = await showExerciseAuthSheet(
                                  i,
                                  exercises[i],
                                );
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
                  FButton(
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
                ],
              ),
            ),
          ],
        ),
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
