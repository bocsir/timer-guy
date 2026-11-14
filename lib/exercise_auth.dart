// exercise_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/theme/button_style.dart';
import 'package:timer_guy/theme/theme.dart';

/// Bottom sheet used to create or edit a single exercise.
class ExerciseAuth extends StatefulWidget {
  final Exercise exercise;
  final int exerciseNumber;

  const ExerciseAuth({
    super.key,
    required this.exercise,
    required this.exerciseNumber,
  });

  @override
  State<ExerciseAuth> createState() => _ExerciseAuthState();
}

class _ExerciseAuthState extends State<ExerciseAuth> {
  late ExerciseType type;
  late final FSelectGroupController<ExerciseType> _typeController;
  late int repCount;
  late int setCount;
  final nameController = TextEditingController();
  final descriptionController = TextEditingController();
  late final FPickerController workDurationController;
  late final FPickerController restDurationController;
  final _formKey = GlobalKey<FormState>();
  bool _localFormSubmitted = false;

  bool get _isInterval => type == ExerciseType.interval;

  @override
  void initState() {
    super.initState();
    type = widget.exercise.type;
    _typeController = FMultiValueNotifier.radio(type);
    nameController.text = widget.exercise.name;
    descriptionController.text = widget.exercise.description ?? '';
    repCount = widget.exercise.reps < 1 ? 1 : widget.exercise.reps;
    setCount = widget.exercise.sets < 1 ? 1 : widget.exercise.sets;

    final workMinutes = widget.exercise.timeOn ~/ 60;
    final workSeconds = widget.exercise.timeOn % 60;
    workDurationController = FPickerController(
      initialIndexes: [workMinutes, workSeconds],
    );

    final restMinutes = widget.exercise.timeOff ~/ 60;
    final restSeconds = widget.exercise.timeOff % 60;
    restDurationController = FPickerController(
      initialIndexes: [restMinutes, restSeconds],
    );

    workDurationController.addListener(() => setState(() {}));
    restDurationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    workDurationController.dispose();
    restDurationController.dispose();
    nameController.dispose();
    descriptionController.dispose();
    _typeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Exercise ${widget.exerciseNumber}',
                      style: typography.xlSemibold,
                    ),
                    FTextFormField(
                      label: Text(
                        'Exercise Name',
                        style: typography.lg.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      controller: nameController,
                      validator: (value) => _validateRequired(value),
                      autovalidateMode: _localFormSubmitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
                    ),
                    FTextFormField(
                      label: Text(
                        'Description',
                        style: typography.lg.copyWith(
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                      hint: 'Optional',
                      controller: descriptionController,
                      maxLines: 3,
                      minLines: 2,
                      textInputAction: TextInputAction.newline,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: FSelectGroup<ExerciseType>(
                        label: Text('Exercise Type', style: typography.lg),
                        controller: _typeController,
                        children: [
                          FRadio.grouped(
                            value: ExerciseType.interval,
                            label: Text('Interval', style: typography.base),
                            description: Text(
                              'Timed work and rest',
                              style: typography.smGrey,
                            ),
                          ),
                          FRadio.grouped(
                            value: ExerciseType.reps,
                            label: Text('Sets & reps', style: typography.base),
                            description: Text(
                              'Do your reps, then tap Done to start the rest timer',
                              style: typography.smGrey,
                            ),
                          ),
                        ],
                        onChange: (values) {
                          setState(
                            () => type = values.isEmpty
                                ? ExerciseType.interval
                                : values.first,
                          );
                        },
                      ),
                    ),
                    if (_isInterval) ...[
                      _buildCountStepper(
                        label: 'Reps',
                        value: repCount,
                        onDecrement: () => _updateRepCount(false),
                        onIncrement: () => _updateRepCount(true),
                        error: _shouldShowRepCountError() ? '0 Reps?' : null,
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Expanded(
                            child: _buildDurationPicker(
                              label: 'Time On',
                              controller: workDurationController,
                              width: double.infinity,
                            ),
                          ),
                          Expanded(
                            child: _buildDurationPicker(
                              label: 'Time Off',
                              controller: restDurationController,
                              width: double.infinity,
                            ),
                          ),
                        ],
                      ),
                      if (_shouldShowWorkDurationError())
                        Text(
                          'Enter rep time > 0 seconds',
                          style: typography.smError,
                        ),
                      if (_shouldShowRestDurationError())
                        Text(
                          'Enter rest time > 0 seconds',
                          style: typography.smError,
                        ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 16,
                        children: [
                          Expanded(
                            child: _buildCountStepper(
                              label: 'Sets',
                              value: setCount,
                              onDecrement: () => _updateSetCount(false),
                              onIncrement: () => _updateSetCount(true),
                              error: _shouldShowSetCountError()
                                  ? 'At least 1 set'
                                  : null,
                            ),
                          ),
                          Expanded(
                            child: _buildCountStepper(
                              label: 'Reps per set',
                              value: repCount,
                              onDecrement: () => _updateRepCount(false),
                              onIncrement: () => _updateRepCount(true),
                              error: _shouldShowRepCountError()
                                  ? '0 Reps?'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      _buildDurationPicker(
                        label: 'Rest',
                        controller: restDurationController,
                      ),
                      if (_shouldShowRestDurationError())
                        Text(
                          'Enter rest time > 0 seconds',
                          style: typography.smError,
                        ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                spacing: 32,
                children: [
                  FButton(
                    onPress: () => Navigator.of(context).pop(),
                    style: transparentButtonStyle,
                    child: Text(
                      'Cancel',
                      style: TextStyle(color: context.theme.colors.primary),
                    ),
                  ),
                  FButton(
                    onPress: () {
                      setState(() {
                        _localFormSubmitted = true;
                      });

                      if (_validateAll()) {
                        Navigator.of(context).pop(_createExercise());
                      }
                    },
                    style: accentButtonStyle(context).call,
                    child: Text(
                      'Save',
                      style: context.theme.typography.baseSemibold.copyWith(
                        color: context.theme.colors.primary,
                        height: 1,
                      ),
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

  Widget _buildCountStepper({
    required String label,
    required int value,
    required VoidCallback onDecrement,
    required VoidCallback onIncrement,
    String? error,
  }) {
    final typography = context.theme.typography;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: typography.lg),
          Row(
            children: [
              FButton(
                onPress: onDecrement,
                style: FButtonStyle.outline(),
                child: Icon(
                  FIcons.minus,
                  color: context.theme.colors.foreground,
                ),
              ),
              SizedBox(
                width: 40,
                child: Center(
                  child: Text(value.toString(), style: typography.lgSemibold),
                ),
              ),
              FButton(
                onPress: onIncrement,
                style: FButtonStyle.outline(),
                child: Icon(
                  FIcons.plus,
                  color: context.theme.colors.foreground,
                ),
              ),
            ],
          ),
          SizedBox(
            height: 20,
            child: error == null
                ? null
                : Text(error, style: typography.smError),
          ),
        ],
      ),
    );
  }

  Widget _buildDurationPicker({
    required String label,
    required FPickerController controller,
    double width = 150,
  }) {
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: typography.lg),
        Text('mm:ss', style: typography.smGrey),
        SizedBox(
          height: 100,
          width: width,
          child: FPicker(
            controller: controller,
            children: [
              FPickerWheel.builder(
                builder: (context, index) =>
                    Text((index % 60).toString().padLeft(2, '0')),
              ),
              const Text(':'),
              FPickerWheel.builder(
                builder: (context, index) =>
                    Text((index % 60).toString().padLeft(2, '0')),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Exercise _createExercise() {
    final workDuration = workDurationController.value;
    final restDuration = restDurationController.value;
    final description = descriptionController.text.trim();

    return Exercise(
      name: nameController.text.trim(),
      reps: repCount,
      sets: _isInterval ? 1 : setCount,
      timeOn: _isInterval
          ? (workDuration[0] % 60) * 60 + (workDuration[1] % 60)
          : 0,
      timeOff: (restDuration[0] % 60) * 60 + (restDuration[1] % 60),
      type: type,
      description: description.isEmpty ? null : description,
    );
  }

  bool _validateAll() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return false;
    }

    if (repCount <= 0) return false;
    if (!_isInterval && setCount <= 0) return false;

    if (_isInterval &&
        _validateTimeSelection(workDurationController.value) != null) {
      return false;
    }

    if (_needsRestTime &&
        _validateTimeSelection(restDurationController.value) != null) {
      return false;
    }

    return true;
  }

  /// Rest is only used between reps for interval exercises, so a single-rep
  /// interval has no rest phase and does not need a rest time.
  bool get _needsRestTime => !_isInterval || repCount > 1;

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _updateRepCount(bool increment) {
    setState(() {
      if (increment) {
        repCount++;
      } else if (repCount > 1) {
        repCount--;
      }
    });
  }

  void _updateSetCount(bool increment) {
    setState(() {
      if (increment) {
        setCount++;
      } else if (setCount > 1) {
        setCount--;
      }
    });
  }

  String? _validateTimeSelection(List<int> timeIndexes) {
    if (!_isTimeGreaterThanZero(timeIndexes)) {
      return 'Enter a time > 0 seconds';
    }
    return null;
  }

  bool _isTimeGreaterThanZero(List<int> timeIndexes) {
    final minutes = timeIndexes[0] % 60;
    final seconds = timeIndexes[1] % 60;
    return minutes > 0 || seconds > 0;
  }

  bool _shouldShowWorkDurationError() {
    return _localFormSubmitted &&
        _validateTimeSelection(workDurationController.value) != null;
  }

  bool _shouldShowRestDurationError() {
    return _needsRestTime &&
        _localFormSubmitted &&
        _validateTimeSelection(restDurationController.value) != null;
  }

  bool _shouldShowRepCountError() {
    return _localFormSubmitted && repCount <= 0;
  }

  bool _shouldShowSetCountError() {
    return _localFormSubmitted && setCount <= 0;
  }
}
