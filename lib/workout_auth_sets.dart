// workout_auth_sets.dart
import 'package:flutter/material.dart';
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
  final Map<String, dynamic> _controllers = {
    'name': TextEditingController(),
    'repDuration': FPickerController(initialIndexes: [0, 0]),
    'restDuration': FPickerController(initialIndexes: [0, 0]),
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
          onChange: (value) => setState(() {}),
          controller: _controllers['name'],
          validator: (value) => _validateRequired(value),
          autovalidateMode: widget.formSubmitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
        ),
        Text('Rep Count', style: typography.lg),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  FButton(
                    onPress: () {
                      _updateRepCount(false);
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
                      _updateRepCount(true);
                    },
                    style: FButtonStyle.outline(),
                    child: Icon(FIcons.plus, color: context.theme.colors.foreground),
                  ),
                ],
              ),
              (_shouldShowRepCountError())
                  ? SizedBox(height: 20, child: Text('0 Reps?', style: typography.smError))
                  : SizedBox(height: 20),
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
          child: Column(
            children: [
              Row(
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
                          onChange: (value) => setState(() {}),
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
                          onChange: (value) => setState(() {}),
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
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
        (_shouldShowRepDurationError())
            ? SizedBox(height: 20, child: Text('Enter rep time > 0 seconds', style: typography.smError))
            : SizedBox(height: 20),
        (_shouldShowRestDurationError())
            ? SizedBox(height: 20, child: Text('Enter rest time > 0 seconds', style: typography.smError))
            : SizedBox(height: 20),
      ],
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }
    return null;
  }

  void _updateRepCount(bool increment) {
    setState(() {
      increment ? repCount++ : repCount--;
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

  bool _shouldShowRepDurationError() {
    final controller = _controllers['repDuration'] as FPickerController;
    return widget.formSubmitted && _validateTimeSelection(controller.value) != null;
  }

  bool _shouldShowRestDurationError() {
    final controller = _controllers['restDuration'] as FPickerController;
    return widget.formSubmitted && _validateTimeSelection(controller.value) != null;
  }

  bool _shouldShowRepCountError() {
    return widget.formSubmitted && repCount <= 0;
  }
}
