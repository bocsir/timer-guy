// workout_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'dart:async';

import 'package:proj/models/workout.dart';

class WorkoutPage extends StatefulWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage> {
  Timer? timer;
  late int currTime;

  @override
  void initState() {
    super.initState();
    currTime = widget.workout.timeOn;
  }

  @override
  Widget build(context) {
    final typography = context.theme.typography;

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 32,
        children: [
          Text(
            currTime == 0 ? 'Time\'s up!' : '$currTime',
            style: typography.xl3.copyWith(fontWeight: FontWeight.bold),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: 16,
            children: [
              FButton.icon(
                style: FButtonStyle.ghost(),
                onPress: timer?.isActive == true ? null : startTimer,
                child: Icon(FIcons.play),
              ),
              FButton.icon(
                style: FButtonStyle.ghost(),
                onPress: () {
                  timer?.cancel();
                  setState(() {
                    currTime = widget.workout.timeOn;
                  });
                },
                child: Icon(FIcons.refreshCw),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void startTimer() {
    const s = Duration(seconds: 1);
    timer = Timer.periodic(s, (Timer timer) {
      if (currTime == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        setState(() => currTime--);
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
