// workout_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'dart:async';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:progress_border/progress_border.dart';

class WorkoutPage extends StatefulWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage>
    with TickerProviderStateMixin {
  late final AnimationController animationController;
  Timer? timer;
  late int currTime;

  @override
  void initState() {
    super.initState();
    currTime = widget.workout.timeOn;
    animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: widget.workout.timeOn),
    );
    animationController.addListener(() {
      setState(() {});
    });
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
                  border: ProgressBorder.all(
                    color: context.theme.colors.accent,
                    progress: animationController.value,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      currTime == 0
                          ? Text(
                              'Time\'s up!',
                              style: typography.xl3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              '$currTime',
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
                              child: timer?.isActive == true
                                  ? FButton.icon(
                                      style: FButtonStyle.ghost(),
                                      onPress: pause,
                                      child: Icon(
                                        FIcons.pause,
                                        size: 30,
                                        color: context.theme.colors.foreground,
                                      ),
                                    )
                                  : FButton.icon(
                                      style: FButtonStyle.ghost(),
                                      onPress: () {
                                        startTimer();
                                        //start animation
                                        restart();
                                      },
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

  void restart() {
    if (animationController.value >= 1) {
      animationController.reverse();
    } else {
      animationController.forward();
    }
  }

  void pause() {
    animationController.stop();
    timer?.cancel();
    setState(() {});
  }

  void startTimer() {
    const s = Duration(seconds: 1);
    timer = Timer.periodic(s, (Timer timer) {
      if (currTime == 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        // dont need setState here because the animationController listener will update the controller
        // weird

        // setState(() => currTime--);
        currTime--;
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    animationController.dispose();
    super.dispose();
  }
}
