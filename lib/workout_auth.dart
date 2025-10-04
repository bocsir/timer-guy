// workout_auth.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/widgets/text_field.dart';

class WorkoutAuth extends StatefulWidget {
  const WorkoutAuth({super.key});

  @override
  State<WorkoutAuth> createState() => _WorkoutAuthState();
}

class _WorkoutAuthState extends State<WorkoutAuth> {
  final Map<String, TextEditingController> _controllers = {
    'repCount': TextEditingController(),
    'repDuration': TextEditingController(),
    'restDuration': TextEditingController(),
    'setCount': TextEditingController(),
  };

  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 60),
        child: FTextField(
          label: Text('Time (s):'),
          controller: _controllers['repDuration'],
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
      ),
    );
  }
}
