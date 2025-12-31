// set_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/hive/hive_adapters.dart';
import 'package:proj/theme/button_style.dart';
import 'package:proj/theme/theme.dart';

class SetAuth extends StatefulWidget {
  final WorkoutSet set;
  final bool formSubmitted;
  final int setNumber;
  const SetAuth({super.key, required this.set, this.formSubmitted = false, required this.setNumber});

  @override
  State<SetAuth> createState() => _SetAuthState();
}

class _SetAuthState extends State<SetAuth> {
  late int repCount;
  final nameController = TextEditingController();
  late final FPickerController repDurationController;
  late final FPickerController restDurationController;
  final _formKey = GlobalKey<FormState>();
  bool _localFormSubmitted = false;

  @override
  void initState() {
    super.initState();
    nameController.text = widget.set.name;
    repCount = widget.set.reps;

    final timeOnMinutes = widget.set.timeOn ~/ 60;
    final timeOnSeconds = widget.set.timeOn % 60;
    repDurationController = FPickerController(initialIndexes: [timeOnMinutes, timeOnSeconds]);

    final timeOffMinutes = widget.set.timeOff ~/ 60;
    final timeOffSeconds = widget.set.timeOff % 60;
    restDurationController = FPickerController(initialIndexes: [timeOffMinutes, timeOffSeconds]);

    repDurationController.addListener(() => setState(() {}));
    restDurationController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    repDurationController.dispose();
    restDurationController.dispose();
    nameController.dispose();
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
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Set ${widget.setNumber}', style: typography.xlSemibold),
                    FTextFormField(
                      label: Text('Set Name', style: typography.lg.copyWith(fontWeight: FontWeight.normal)),
                      controller: nameController,
                      validator: (value) => _validateRequired(value),
                      autovalidateMode: _localFormSubmitted
                          ? AutovalidateMode.onUserInteraction
                          : AutovalidateMode.disabled,
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
                    child: Text('Cancel', style: TextStyle(color: context.theme.colors.primary)),
                  ),
                  FButton(
                    onPress: () {
                      setState(() {
                        _localFormSubmitted = true;
                      });

                      if (_validateAll()) {
                        final newSet = _createSet();
                        Navigator.of(context).pop(newSet);
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

  WorkoutSet _createSet() {
    final repDuration = repDurationController.value;
    final restDuration = restDurationController.value;

    return WorkoutSet(
      name: nameController.text,
      reps: repCount,
      timeOn: (repDuration[0] % 60) * 60 + (repDuration[1] % 60),
      timeOff: (restDuration[0] % 60) * 60 + (restDuration[1] % 60),
    );
  }

  bool _validateAll() {
    final isFormValid = _formKey.currentState?.validate() ?? false;
    if (!isFormValid) {
      return false;
    }

    if (repCount <= 0) {
      return false;
    }

    if (_validateTimeSelection(repDurationController.value) != null) {
      return false;
    }

    if (_validateTimeSelection(restDurationController.value) != null) {
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
    return _localFormSubmitted && _validateTimeSelection(repDurationController.value) != null;
  }

  bool _shouldShowRestDurationError() {
    return _localFormSubmitted && _validateTimeSelection(restDurationController.value) != null;
  }

  bool _shouldShowRepCountError() {
    return _localFormSubmitted && repCount <= 0;
  }
}
