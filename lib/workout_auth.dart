// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

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

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Rep Duration Picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('On Duration'),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 150, maxWidth: 120),
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
                  ],
                ),
              ),
            ],
          ),
          // Rest Duration Picker
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Off Duration'),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 150, maxWidth: 120),
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
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
