// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/extensions/extensions.dart';
import 'package:proj/header.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/models/workout_set.dart';
import 'package:proj/theme/theme.dart';

class WorkoutAuth extends StatefulWidget {
  final Box<Workout> workoutBox;

  const WorkoutAuth({super.key, required this.workoutBox});

  @override
  State<WorkoutAuth> createState() => _WorkoutAuthState();
}

class _WorkoutAuthState extends State<WorkoutAuth> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _formSubmitted = false;
  List<WorkoutSet> _sets = [];
  int? _editingSetIndex;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final secs = seconds % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m ${secs}s';
    } else if (minutes > 0) {
      return '${minutes}m ${secs}s';
    } else {
      return '${secs}s';
    }
  }

  void _showSetForm({WorkoutSet? set, int? index}) {
    final isEditing = set != null;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _SetFormModal(
        initialSet: set,
        index: index,
        onSave: (workoutSet) {
          if (isEditing && index != null) {
            setState(() {
              _sets[index] = workoutSet;
            });
          } else {
            setState(() {
              _sets.add(workoutSet);
            });
          }
        },
      ),
    );
  }

  void _deleteSet(int index) {
    setState(() {
      _sets.removeAt(index);
    });
  }

  void _moveSet(int fromIndex, int toIndex) {
    if (fromIndex < toIndex) {
      toIndex -= 1;
    }
    setState(() {
      final set = _sets.removeAt(fromIndex);
      _sets.insert(toIndex, set);
    });
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;

    return FScaffold(
      header: Header(backBtnText: 'Cancel'),
      child: SingleChildScrollView(
        child: Column(
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
                    label: Text('Name', style: typography.lgSemibold),
                    controller: _nameController,
                    validator: _validateRequired,
                  ),
                  const SizedBox(height: 16),
                  FButton(
                    style: FButtonStyle.outline(),
                    onPress: () => _showSetForm(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(FIcons.plus),
                        const SizedBox(width: 8),
                        Text(
                          _sets.isEmpty ? 'Add First Set' : 'Add Set',
                          style: typography.lgSemibold.copyWith(
                            color: context.theme.colors.accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('Sets', style: typography.lgSemibold),
                  if (_sets.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _formSubmitted ? 'Add at least one set' : 'No sets added yet',
                        style: _formSubmitted
                            ? typography.smError
                            : typography.smGrey,
                      ),
                    )
                  else
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _sets.length,
                      onReorder: _moveSet,
                      itemBuilder: (context, index) {
                        final set = _sets[index];
                        return FItem(
                          key: ValueKey('set_$index'),
                          title: Text(
                            '${set.name} - ${set.reps} reps, ${_formatTime(set.timeOn)} on, ${_formatTime(set.timeOff)} off',
                            style: typography.baseSemibold,
                          ),
                          suffix: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FButton.icon(
                                style: FButtonStyle.ghost(),
                                onPress: () => _showSetForm(set: set, index: index),
                                child: Icon(FIcons.settings, size: 20),
                              ),
                              FButton.icon(
                                style: FButtonStyle.ghost(),
                                onPress: () => _deleteSet(index),
                                child: Icon(FIcons.trash, size: 20),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 16),
                  FButton(
                    style: FButtonStyle.outline(),
                    onPress: _onDonePressed,
                    child: Text(
                      'Done',
                      style: typography.lgSemibold.copyWith(
                        color: context.theme.colors.accent,
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

  void _onDonePressed() {
    setState(() {
      _formSubmitted = true;
    });

    if (_validateForm()) {
      final workout = Workout(
        name: _nameController.text.trim(),
        sets: _sets,
      );

      widget.workoutBox.add(workout);
      Navigator.of(context).pop();
    }
  }

  bool _validateForm() {
    final state = _formKey.currentState;
    bool isFormValid = state?.validate() ?? false;
    if (!isFormValid) {
      return false;
    }

    if (_sets.isEmpty) {
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

  bool _isTimeGreaterThanZero(List<int> timeIndexes) {
    final hours = timeIndexes[0] % 12;
    final minutes = timeIndexes[1] % 60;
    final seconds = timeIndexes[2] % 60;
    return hours > 0 || minutes > 0 || seconds > 0;
  }
}

class _SetFormModal extends StatefulWidget {
  final WorkoutSet? initialSet;
  final int? index;
  final Function(WorkoutSet) onSave;

  const _SetFormModal({
    required this.initialSet,
    required this.index,
    required this.onSave,
  });

  @override
  State<_SetFormModal> createState() => _SetFormModalState();
}

class _SetFormModalState extends State<_SetFormModal> {
  late final TextEditingController _nameController;
  late final TextEditingController _repCountController;
  late final FPickerController _repDurationController;
  late final FPickerController _restDurationController;
  final _setFormKey = GlobalKey<FormState>();
  bool _setFormSubmitted = false;
  bool _enableGetReady = false;

  @override
  void initState() {
    super.initState();
    final isEditing = widget.initialSet != null;
    _nameController = TextEditingController(
      text: isEditing ? widget.initialSet!.name : '',
    );
    _repCountController = TextEditingController(
      text: isEditing ? widget.initialSet!.reps.toString() : '',
    );
    _repDurationController = FPickerController(
      initialIndexes: isEditing
          ? [
              (widget.initialSet!.timeOn ~/ 3600) % 12,
              ((widget.initialSet!.timeOn % 3600) ~/ 60) % 60,
              (widget.initialSet!.timeOn % 60) % 60,
            ]
          : [0, 0, 0],
    );
    _restDurationController = FPickerController(
      initialIndexes: isEditing
          ? [
              (widget.initialSet!.timeOff ~/ 3600) % 12,
              ((widget.initialSet!.timeOff % 3600) ~/ 60) % 60,
              (widget.initialSet!.timeOff % 60) % 60,
            ]
          : [0, 0, 0],
    );
    _enableGetReady = isEditing ? widget.initialSet!.enableGetReady : false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _repCountController.dispose();
    _repDurationController.dispose();
    _restDurationController.dispose();
    super.dispose();
  }

  bool _isTimeGreaterThanZero(List<int> timeIndexes) {
    final hours = timeIndexes[0] % 12;
    final minutes = timeIndexes[1] % 60;
    final seconds = timeIndexes[2] % 60;
    return hours > 0 || minutes > 0 || seconds > 0;
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

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.initialSet != null;
    final typography = context.theme.typography;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _setFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isEditing ? 'Edit Set' : 'Add Set',
                  style: typography.xlSemibold,
                ),
                const SizedBox(height: 16),
                FTextFormField(
                  label: Text('Set Name', style: typography.lgSemibold),
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                FTextFormField(
                  label: Text('Reps', style: typography.lgSemibold),
                  controller: _repCountController,
                  keyboardType: TextInputType.numberWithOptions(),
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) => _validatePositiveNumber(value, 'reps'),
                ),
                const SizedBox(height: 16),
                Column(
                  children: [
                    Text('Time On', style: typography.lgSemibold),
                    Text('hh:mm:ss', style: typography.smGrey),
                    SizedBox(
                      height: 150,
                      child: Column(
                        children: [
                          Expanded(
                            child: FPicker(
                              controller: _repDurationController,
                              children: [
                                FPickerWheel.builder(
                                  builder: (context, index) => Text(
                                    (index % 12).toString().padLeft(2, '0'),
                                  ),
                                ),
                                const Text(':'),
                                FPickerWheel.builder(
                                  builder: (context, index) => Text(
                                    (index % 60).toString().padLeft(2, '0'),
                                  ),
                                ),
                                const Text(':'),
                                FPickerWheel.builder(
                                  builder: (context, index) => Text(
                                    (index % 60).toString().padLeft(2, '0'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          _setFormSubmitted &&
                                  !_isTimeGreaterThanZero(_repDurationController.value)
                              ? SizedBox(
                                  height: 20,
                                  child: Text(
                                    'Enter a time > 0 seconds',
                                    style: typography.smError,
                                  ),
                                )
                              : const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ],
                ),
                Column(
                  children: [
                    Text('Time Off', style: typography.lgSemibold),
                    Text('hh:mm:ss', style: typography.smGrey),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: FPicker(
                        controller: _restDurationController,
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
                    _setFormSubmitted &&
                            !_isTimeGreaterThanZero(_restDurationController.value)
                        ? SizedBox(
                            height: 20,
                            child: Text(
                              'Enter a time > 0 seconds',
                              style: typography.smError,
                            ),
                          )
                        : const SizedBox(height: 20),
                  ],
                ),
                const SizedBox(height: 16),
                // Get Ready toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Get Ready Period', style: typography.baseSemibold),
                        Text('5 second countdown before each rep', style: typography.smGrey),
                      ],
                    ),
                    Switch(
                      value: _enableGetReady,
                      onChanged: (value) {
                        setState(() {
                          _enableGetReady = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  spacing: 8,
                  children: [
                    FButton(
                      style: FButtonStyle.outline(),
                      onPress: () => Navigator.of(context).pop(),
                      child: Text('Cancel'),
                    ),
                    FButton(
                      style: FButtonStyle.outline(),
                      onPress: () {
                        setState(() {
                          _setFormSubmitted = true;
                        });

                        if (_setFormKey.currentState?.validate() ?? false) {
                          if (!_isTimeGreaterThanZero(_repDurationController.value) ||
                              !_isTimeGreaterThanZero(_restDurationController.value)) {
                            return;
                          }

                          final workoutSet = WorkoutSet(
                            name: _nameController.text.trim(),
                            reps: int.parse(_repCountController.text.trim()),
                            timeOn: _repDurationController.totalSeconds,
                            timeOff: _restDurationController.totalSeconds,
                            enableGetReady: _enableGetReady,
                          );

                          widget.onSave(workoutSet);
                          Navigator.of(context).pop();
                        }
                      },
                      child: Text(isEditing ? 'Save' : 'Add Set'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
