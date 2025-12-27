// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/header.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:proj/workout_auth_sets.dart';

class WorkoutAuth extends StatefulWidget {
  final Box<Workout> workoutBox;

  const WorkoutAuth({super.key, required this.workoutBox});

  @override
  State<WorkoutAuth> createState() => _WorkoutAuthState();
}

class _WorkoutAuthState extends State<WorkoutAuth> {
  var setCount = 0;

  final Map<String, dynamic> _controllers = {'name': TextEditingController()};

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
          style: FButtonStyle.outline(),
          onPress: _onDonePressed,
          child: Text('Done', style: typography.lg.copyWith(color: context.theme.colors.accent)),
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
                    controller: _controllers['name'],
                    validator: _validateRequired,
                  ),
                  for (var i = 1; i <= setCount; i++) WorkoutAuthSets(key: ValueKey(i), setCount: i),
                  FButton(
                    style: FButtonStyle.outline(),
                    onPress: () {
                      setState(() {
                        setCount++;
                      });
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

  //TODO: clean up below methods

  void _onDonePressed() {
    setState(() {
      _formSubmitted = true;
    });

    if (_validateForm()) {
      // final workout = Workout(
      //   name: _controllers['name'].text.trim(),
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

    // check FPicker fields
    final repController = _controllers['repDuration'] as FPickerController;
    final restController = _controllers['restDuration'] as FPickerController;

    final repDurationError = _validateTimeSelection(repController.value);
    final restDurationError = _validateTimeSelection(restController.value);

    return repDurationError == null && restDurationError == null;
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  String? _validatePositiveNumber(String? value, String fieldName) {
    final requiredError = _validateRequired(value);
    if (requiredError != null) return requiredError;

    final intValue = int.tryParse(value!.trim());
    if (intValue == null) {
      return 'Enter a valid number';
    }
    if (intValue <= 0) {
      return '0 ${fieldName.toLowerCase()}?';
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

  bool _shouldShowRepDurationError() {
    final controller = _controllers['repDuration'] as FPickerController;
    return _formSubmitted && _validateTimeSelection(controller.value) != null;
  }

  bool _shouldShowRestDurationError() {
    final controller = _controllers['restDuration'] as FPickerController;
    return _formSubmitted && _validateTimeSelection(controller.value) != null;
  }
}
