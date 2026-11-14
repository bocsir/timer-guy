// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/set_auth.dart';

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
  late List<WorkoutSet> sets;
  late final TextEditingController nameController;
  late final TextEditingController descriptionController;
  late WorkoutType _type;
  late final FSelectGroupController<WorkoutType> _typeController;

  final _formKey = GlobalKey<FormState>();
  bool _formSubmitted = false;

  bool get _isReps => _type == WorkoutType.reps;

  @override
  void initState() {
    super.initState();
    final workout = widget.workout;
    sets = workout == null ? [] : List.of(workout.sets);
    nameController = TextEditingController(text: workout?.name ?? '');
    descriptionController = TextEditingController(
      text: workout?.description ?? '',
    );
    _type = workout?.type ?? WorkoutType.interval;
    _typeController = FMultiValueNotifier.radio(_type);
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
                  FSelectGroup<WorkoutType>(
                    label: Text('Workout Type', style: typography.lg),
                    controller: _typeController,
                    children: [
                      FRadio.grouped(
                        value: WorkoutType.interval,
                        label: Text('Interval', style: typography.base),
                        description: Text(
                          'Timed work and rest',
                          style: typography.smGrey,
                        ),
                      ),
                      FRadio.grouped(
                        value: WorkoutType.reps,
                        label: Text('Sets & reps', style: typography.base),
                        description: Text(
                          'Do your reps, then tap Done to start the rest timer',
                          style: typography.smGrey,
                        ),
                      ),
                    ],
                    onChange: (values) {
                      setState(
                        () => _type = values.isEmpty
                            ? WorkoutType.interval
                            : values.first,
                      );
                    },
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
                  if (sets.isNotEmpty)
                    Text(
                      _isReps ? 'Exercises' : 'Sets',
                      style: typography.lgSemibold,
                    ),
                  for (var i = 0; i < sets.length; i++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _isReps
                                    ? '${sets[i].name} - ${sets[i].reps} reps'
                                    : sets[i].name,
                                style: context.theme.typography.sm,
                              ),
                              if (_isReps)
                                Text(
                                  'Rest ${_formatDuration(sets[i].timeOff)}',
                                  style: typography.smGrey,
                                ),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            FButton(
                              onPress: () async {
                                final updatedSet = await showSetAuthSheet(
                                  i,
                                  sets[i],
                                );
                                if (updatedSet != null) {
                                  upsertSet(i, updatedSet);
                                }
                              },
                              style: FButtonStyle.ghost(),
                              child: Icon(FIcons.pencil),
                            ),
                            FButton(
                              onPress: () {
                                setState(() => sets.removeAt(i));
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
                      final index = sets.length;
                      final newSet = await showSetAuthSheet(
                        index,
                        WorkoutSet(name: '', reps: 0, timeOn: 0, timeOff: 0),
                      );
                      if (newSet != null) {
                        upsertSet(index, newSet);
                      }
                    },
                    child: Text(
                      _isReps ? 'Add Exercise' : 'Add Set',
                      style: typography.lg,
                    ),
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
    _typeController.dispose();
    super.dispose();
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '${remainingSeconds}s';
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  void upsertSet(int index, WorkoutSet newSet) {
    setState(() {
      if (index >= sets.length) {
        sets.add(newSet);
      } else {
        sets[index] = newSet;
      }
    });
  }

  Future<WorkoutSet?> showSetAuthSheet(int setIndex, WorkoutSet initialSet) {
    return showModalBottomSheet<WorkoutSet>(
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
        child: SetAuth(
          set: initialSet,
          setNumber: setIndex + 1,
          formSubmitted: _formSubmitted,
          type: _type,
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
        sets: List.of(sets),
        description: description.isEmpty ? null : description,
        type: _type,
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
    final state = _formKey.currentState;
    bool isFormValid = state?.validate() ?? false;
    if (!isFormValid) {
      return false;
    }

    return true;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }
}
