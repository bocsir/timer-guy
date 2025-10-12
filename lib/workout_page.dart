// workout_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'dart:async';

import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';

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

    return FScaffold(
      header: Header(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 32,
        children: [
          Text(widget.workout.name, style: typography.xlSemibold),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: BoxBorder.all(
                    color: context.theme.colors.accent,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currTime == 0 ? 'Time\'s up!' : '$currTime',
                        style: typography.xl6.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 64,
                        children: [
                          FButton.icon(
                            style: FButtonStyle.ghost(),
                            onPress: () {
                              timer?.cancel();
                              setState(() {
                                currTime = widget.workout.timeOn;
                              });
                            },
                            child: Icon(FIcons.refreshCw, size: 30),
                          ),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              border: BoxBorder.all(),
                              borderRadius: BorderRadius.circular(16),
                              color: context.theme.colors.accent,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: FButton.icon(
                                style: FButtonStyle.ghost(),
                                onPress: timer?.isActive == true
                                    ? null
                                    : startTimer,
                                child: Icon(
                                  FIcons.play,
                                  size: 30,
                                  color: context.theme.colors.foreground,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          //TODO: temporary
          SizedBox(height: 16),
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
