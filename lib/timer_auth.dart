// timer_auth.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:forui/widgets/text_field.dart';

class TimerAuth extends StatefulWidget {
  TextEditingController timerController = TextEditingController(text: '0');

  TimerAuth({super.key, required this.timerController});

  @override
  State<TimerAuth> createState() => _TimerAuthState();
}

class _TimerAuthState extends State<TimerAuth> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 60),
          child: FTextField(
            label: Text('Time (s):'),
            controller: widget.timerController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ),
      ],
    );
  }
}
