// timer_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'dart:async';

import 'package:proj/timer_auth.dart';

class TimerPage extends StatefulWidget {
  const TimerPage({super.key});

  @override
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  final TextEditingController _timerController = TextEditingController();

  Timer? timer;
  int currTime = 0;
  @override
  void initState() {
    super.initState();
    _timerController.addListener(() {
      setState(() {
        currTime = int.tryParse(_timerController.text) ?? 0;
      });
    });
  }

  @override
  Widget build(context) {
    final typography = context.theme.typography;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 32,
      children: [
        TimerAuth(timerController: _timerController),
        Text(
          currTime == 0 ? 'times up' : '$currTime',
          style: typography.xl3.copyWith(fontWeight: FontWeight.bold),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 16,
          children: [
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: startTimer,
              child: Icon(FIcons.play),
            ),
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () {
                setState(() {
                  currTime = int.parse(_timerController.text);
                });
              },
              child: Icon(FIcons.refreshCw),
            ),
          ],
        ),
      ],
    );
  }

  void startTimer() {
    const s = Duration(seconds: 1);
    timer = Timer.periodic(s, (Timer timer) {
      currTime == 0
          ? setState(() {
              timer.cancel();
            })
          : setState(() => currTime--);
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    _timerController.dispose();
    super.dispose();
  }
}
