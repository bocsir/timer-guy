// workout_auth.dart
import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Form(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('On'),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 150, maxWidth: 150),
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
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Off'),
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: 150, maxWidth: 150),
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
            ],
          ),
        ],
      ),
    );
  }
}
