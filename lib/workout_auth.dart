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
                  Text('Create Workout', style: typography.xlSemibold),
                  FTextFormField(
                    label: Text('Workout Name', style: typography.lg),
                    controller: nameController,
                    validator: _validateRequired,
                    autovalidateMode: _formSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  ),
                  for (var i = 1; i <= sets.length; i++)
                    Column(
                      children: [
                        FDivider(),
                        SetAuth(
                          key: ValueKey(i),
                          set: sets[i - 1],
                          setCount: i,
                          upsertSet: (index, newSet) => upsertSet(index, newSet),
                          formSubmitted: _formSubmitted,
                        ),
                      ],
                    ),
                  FButton(
                    style: FButtonStyle.outline(),
                    onPress: () => upsertSet(sets.length, WorkoutSet(name: '', reps: 0, timeOn: 0, timeOff: 0)),
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

  void upsertSet(final index, WorkoutSet newSet) {
    setState(() {
      if (index > sets.length) {
        sets.add(newSet);
      } else {
        sets[index] = newSet;
      }
    });
  }

  void _onDonePressed() {
    setState(() {
      _formSubmitted = true;
    });

    if (_validateForm()) {
      // final workout = Workout(
      //   name: nameController.text.trim(),
      //   reps: int.parse(_controllers['repCount'].text.trim()),
      //   sets: int.parse(_controllers['setCount'].text.trim()),
      //   timeOn: (_controllers['repDuration'] as FPickerController).totalSeconds,
      //   timeOff: (_controllers['restDuration'] as FPickerController).totalSeconds,
      // );

      // widget.workoutBox.add(workout);
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

  // maybe dont need separate method for this. could be useful if more complex time filters are needed
  // but why would they be
  String? _validateTimeSelection(List<int> timeIndexes) {
    if (!_isTimeGreaterThanZero(timeIndexes)) {
      return 'Enter a time > 0 seconds';
    }
    return null;
  }

  bool _isTimeGreaterThanZero(List<int> timeIndexes) {
    final hours = timeIndexes[0] % 12;
    final minutes = timeIndexes[1] % 60;
    final seconds = timeIndexes[2] % 60;
    return hours > 0 || minutes > 0 || seconds > 0;
  }
}
