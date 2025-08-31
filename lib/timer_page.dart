// timer_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'dart:async';

class TimerPage extends StatefulWidget {
  final int time;

  const TimerPage({required this.time, super.key});

  @override
  TimerPageState createState() => TimerPageState();
}

class TimerPageState extends State<TimerPage> {
  Timer? timer;
  int currTime = 0;
  bool timeUp = false;

  @override
  void initState() {
    super.initState();
    currTime = widget.time;
  }

  void startTimer() {
    timeUp = false;
    const s = Duration(seconds: 1);
    timer = Timer.periodic(s, (Timer timer) {
      currTime == 0
          ? setState(() {
              timer.cancel();
              print('time up');
              timeUp = true;
            })
          : setState(() => currTime--);
    });
  }

  @override
  Widget build(context) {
    final typography = context.theme.typography;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 32,
      children: [
        Text(
          timeUp ? 'times up' : '$currTime',
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
                  currTime = widget.time;
                  timeUp = false;
                });
              },
              child: Icon(FIcons.refreshCw),
            ),
          ],
        ),
      ],
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
