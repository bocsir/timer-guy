// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:proj/theme/theme.dart';

class WorkoutAuth extends StatefulWidget {
  const WorkoutAuth({super.key});

  @override
  State<WorkoutAuth> createState() => _WorkoutAuthState();
}

class _WorkoutAuthState extends State<WorkoutAuth> {
  final Map<String, dynamic> _controllers = {
    'repCount': TextEditingController(),
    'repDuration': FPickerController(initialIndexes: [0, 0, 0]),
    'restDuration': FPickerController(initialIndexes: [0, 0, 0]),
    'setCount': TextEditingController(),
  };

  final _formKey = GlobalKey<FormState>();
  bool _formSubmitted = false;

  bool _validateForm() {
    final state = _formKey.currentState;
    if (state != null && state.validate()) {
      return false;
    }

    final repCount = _controllers['repCount'].text.trim();
    final setCount = _controllers['setCount'].text.trim();

    if (repCount.isEmpty || setCount.isEmpty) {
      return false;
    }

    final repController = _controllers['repDuration'] as FPickerController;
    final restController = _controllers['restDuration'] as FPickerController;

    final repDuration = repController.value;
    final restDuration = restController.value;

    if (!_isTimeGreaterThanZero(repDuration) ||
        !_isTimeGreaterThanZero(restDuration)) {
      return false;
    }

    return true;
  }

  bool _isTimeGreaterThanZero(List<int> timeIndexes) {
    final hours = timeIndexes[0] % 12;
    final minutes = timeIndexes[1] % 60;
    final seconds = timeIndexes[2] % 60;
    return hours > 0 || minutes > 0 || seconds > 0;
  }

  bool _shouldShowRepDurationError() {
    final controller = _controllers['repDuration'] as FPickerController;
    return _formSubmitted && !_isTimeGreaterThanZero(controller.value);
  }

  bool _shouldShowRestDurationError() {
    final controller = _controllers['restDuration'] as FPickerController;
    return _formSubmitted && !_isTimeGreaterThanZero(controller.value);
  }

  void _onDonePressed() {
    setState(() {
      _formSubmitted = true;
    });

    if (_validateForm()) {
      // do stuff
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 32,
      children: [
        Text(
          'Create Workout',
          style: FTheme.of(context).typography.xl.copyWith(
            fontWeight: FontWeight.w700,
            fontFamily: 'IBMPlexMono',
            height: 0,
          ),
        ),
        Form(
          key: _formKey,
          child: Column(
            spacing: 32,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 90,
                      child: FTextFormField(
                        label: Text(
                          'Reps',
                          style: FTheme.of(context).typography.lgSemibold,
                        ),
                        controller: _controllers['repCount'],
                        keyboardType: TextInputType.numberWithOptions(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final intValue = int.tryParse(value);
                          if (intValue == 0) {
                            return '0 reps?';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                  SizedBox(width: 64),
                  Expanded(
                    child: SizedBox(
                      height: 90,
                      child: FTextFormField(
                        label: Text(
                          'Sets',
                          style: FTheme.of(context).typography.lgSemibold,
                        ),
                        controller: _controllers['setCount'],
                        keyboardType: TextInputType.numberWithOptions(),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Required';
                          }
                          final intValue = int.tryParse(value);
                          if (intValue == 0) {
                            return '0 sets?';
                          }
                          return null;
                        },
                      ),
                    ),
                  ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Time On',
                    style: FTheme.of(context).typography.lgSemibold,
                  ),
                  Text('hh:mm:ss', style: FTheme.of(context).typography.smGrey),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 150),
                    child: FPicker(
                      controller: _controllers['repDuration'],
                      children: [
                        FPickerWheel.builder(
                          builder: (context, index) =>
                              Text((index % 12).toString().padLeft(2, '0')),
                        ),
                        const Text(':'),
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
                  if (_shouldShowRepDurationError())
                    Text(
                      'Enter a time > 0 seconds',
                      style: FTheme.of(context).typography.smError,
                    ),
                ],
              ),
              Column(
                children: [
                  Text(
                    'Time Off',
                    style: FTheme.of(context).typography.lgSemibold,
                  ),
                  Text('hh:mm:ss', style: FTheme.of(context).typography.smGrey),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 150),
                    child: FPicker(
                      controller: _controllers['restDuration'],
                      children: [
                        FPickerWheel.builder(
                          builder: (context, index) =>
                              Text((index % 12).toString().padLeft(2, '0')),
                        ),
                        const Text(':'),
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
                  if (_shouldShowRestDurationError())
                    Text(
                      'Enter a time > 0 seconds',
                      style: FTheme.of(context).typography.smError,
                    ),
                ],
              ),
              // Done button
              FButton(onPress: _onDonePressed, child: const Text('Done')),
            ],
          ),
        ),
      ],
    );
  }
}
