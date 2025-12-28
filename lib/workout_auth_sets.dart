// workout_auth_sets.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:proj/theme/theme.dart';

class WorkoutAuthSets extends StatefulWidget {
  final bool formSubmitted;
  final int setCount;
  const WorkoutAuthSets({super.key, this.formSubmitted = false, required this.setCount});

  @override
  State<WorkoutAuthSets> createState() => _WorkoutAuthSetsState();
}

class _WorkoutAuthSetsState extends State<WorkoutAuthSets> {
  int repCount = 0;
  Map<String, dynamic> get _controllers => {
    'name': TextEditingController(text: 'Set ${widget.setCount}'),
    'repCount': TextEditingController(),
    'repDuration': FPickerController(initialIndexes: [0, 0, 0]),
    'restDuration': FPickerController(initialIndexes: [0, 0, 0]),
  };

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set ${widget.setCount}', style: typography.lgSemibold),
        FTextFormField(
          label: Text('Set Name', style: typography.lg.copyWith(fontWeight: FontWeight.normal)),
          controller: _controllers['name'],
          validator: (value) => _validateRequired(value),
        ),
        Text('Rep Count', style: typography.lg),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              FButton(
                onPress: () {
                  setState(() {
                    repCount--;
                  });
                },
                style: FButtonStyle.outline(),
                child: Icon(FIcons.minus, color: context.theme.colors.foreground),
              ),
              SizedBox(
                width: 40,
                child: Center(child: Text(repCount.toString(), style: typography.lgSemibold)),
              ),

              FButton(
                onPress: () {
                  setState(() {
                    repCount++;
                  });
                },
                style: FButtonStyle.outline(),
                child: Icon(FIcons.plus, color: context.theme.colors.foreground),
              ),
            ],
          ),
        ),
        // FTextFormField(
        //   label: Text('Reps', style: typography.lgSemibold),
        //   controller: _controllers['repCount'],
        //   keyboardType: TextInputType.numberWithOptions(),
        //   inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        //   validator: (value) => _validatePositiveNumber(value, 'reps'),
        // ),
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 400),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time On', style: typography.lg),
                  Text('mm:ss', style: typography.smGrey),
                  SizedBox(
                    height: 100,
                    width: 150,
                    child: FPicker(
                      controller: _controllers['repDuration'],
                      children: [
                        FPickerWheel.builder(
                          builder: (context, index) => Text((index % 60).toString().padLeft(2, '0')),
                        ),
                        const Text(':'),
                        FPickerWheel.builder(
                          builder: (context, index) => Text((index % 60).toString().padLeft(2, '0')),
                        ),
                      ],
                    ),
                  ),
                  (_shouldShowRepDurationError())
                      ? SizedBox(height: 20, child: Text('Enter a time > 0 seconds', style: typography.smError))
                      : SizedBox(height: 20),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Time Off', style: typography.lg),
                  Text('mm:ss', style: typography.smGrey),
                  SizedBox(
                    height: 100,
                    width: 150,
                    child: FPicker(
                      controller: _controllers['restDuration'],
                      children: [
                        FPickerWheel.builder(
                          builder: (context, index) => Text((index % 60).toString().padLeft(2, '0')),
                        ),
                        const Text(':'),
                        FPickerWheel.builder(
                          builder: (context, index) => Text((index % 60).toString().padLeft(2, '0')),
                        ),
                      ],
                    ),
                  ),
                  (_shouldShowRestDurationError())
                      ? SizedBox(height: 20, child: Text('Enter a time > 0 seconds', style: typography.smError))
                      : SizedBox(height: 20),
                ],
              ),
            ],
          ),
        ),
      ],
    );
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

  bool _shouldShowRepDurationError() {
    final controller = _controllers['repDuration'] as FPickerController;
    return widget.formSubmitted && _validateTimeSelection(controller.value) != null;
  }

  bool _shouldShowRestDurationError() {
    final controller = _controllers['restDuration'] as FPickerController;
    return widget.formSubmitted && _validateTimeSelection(controller.value) != null;
  }
}
