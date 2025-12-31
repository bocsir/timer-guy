// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/header.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:proj/set_auth.dart';

class WorkoutAuth extends StatefulWidget {
  final Box<Workout> workoutBox;

  const WorkoutAuth({super.key, required this.workoutBox});

  @override
  State<WorkoutAuth> createState() => _WorkoutAuthState();
}

class _WorkoutAuthState extends State<WorkoutAuth> {
  List<WorkoutSet> sets = [];
  final nameController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _formSubmitted = false;

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
          child: Text('Done!', style: typography.lg.copyWith(color: context.theme.colors.accent)),
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
                  Text('Create Workout', style: typography.xl3Semibold),
                  FTextFormField(
                    label: Text('Workout Name', style: typography.lg),
                    controller: nameController,
                    validator: _validateRequired,
                    autovalidateMode: _formSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  ),
                  if (sets.isNotEmpty) Text('Sets', style: typography.lgSemibold),
                  for (var i = 0; i < sets.length; i++)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(sets[i].name, style: context.theme.typography.sm),
                        Row(
                          children: [
                            FButton(
                              onPress: () async {
                                final updatedSet = await showSetAuthSheet(i, sets[i]);
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
                    child: Text('Add Set', style: typography.lg),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.6,
        child: SetAuth(set: initialSet, setNumber: setIndex + 1, formSubmitted: _formSubmitted),
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
      final workout = Workout(name: nameController.text.trim(), sets: sets);
      widget.workoutBox.add(workout);
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
