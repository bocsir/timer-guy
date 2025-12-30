// set_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/hive/hive_adapters.dart';
import 'package:proj/theme/theme.dart';

class SetAuth extends StatefulWidget {
  final WorkoutSet set;
  final void Function(int, WorkoutSet) upsertSet;
  final bool formSubmitted;
  final int setCount;
  const SetAuth({
    super.key,
    required this.set,
    required this.upsertSet,
    this.formSubmitted = false,
    required this.setCount,
  });

  @override
  State<SetAuth> createState() => _SetAuthState();
}

class _SetAuthState extends State<SetAuth> {
  int repCount = 0;
  final nameController = TextEditingController();
  final repDurationController = FPickerController(initialIndexes: [0, 0]);
  final restDurationController = FPickerController(initialIndexes: [0, 0]);

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Set ${widget.setCount}', style: typography.lgSemibold),
        FTextFormField(
          label: Text('Set Name', style: typography.lg.copyWith(fontWeight: FontWeight.normal)),
          onChange: (value) {
            setState(() {});
            _updateSetProperty();
          },
          controller: nameController,
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
                          controller: repDurationController,
                          onChange: (value) {
                            setState(() {});
                            _updateSetProperty();
                          },
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
                          controller: restDurationController,
                          onChange: (value) {
                            setState(() {});
                            _updateSetProperty();
                          },
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

  void _updateSetProperty() {
    final repDuration = repDurationController.value;
    final restDuration = restDurationController.value;

    widget.upsertSet(
      widget.setCount - 1,
      WorkoutSet(
        name: nameController.text,
        reps: repCount,
        timeOn: (repDuration[0] % 60) * 60 + (repDuration[1] % 60),
        timeOff: (restDuration[0] % 60) * 60 + (restDuration[1] % 60),
      ),
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
    _updateSetProperty();
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
    return widget.formSubmitted && _validateTimeSelection(repDurationController.value) != null;
  }

  bool _shouldShowRestDurationError() {
    return widget.formSubmitted && _validateTimeSelection(restDurationController.value) != null;
  }

  bool _shouldShowRepCountError() {
    return widget.formSubmitted && repCount <= 0;
  }
}
