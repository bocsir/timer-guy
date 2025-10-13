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
  late double currTime;

  @override
  void initState() {
    super.initState();
    currTime = widget.workout.timeOn + 0.0;
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
                    width: 6,
                    backgroundBorder: Border.all(
                      color: context.theme.colors.border,
                      width: 2,
                    ),
                  ),
                  color: context.theme.colors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      currTime <= 0
                          ? Text(
                              'Time\'s up!',
                              style: typography.xl3.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : Text(
                              currTime.toStringAsFixed(0),
                              style: typography.xl7.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 64,
                        children: [
                          // RESTART
                          FButton.icon(
                            style: FButtonStyle.ghost(),
                            onPress: () {
                              timer?.cancel();
                              setState(() {
                                currTime = widget.workout.timeOn + 0.0;
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
                                  ? // PAUSE
                                    FButton.icon(
                                      style: FButtonStyle.ghost(),
                                      onPress: pause,
                                      child: Icon(
                                        FIcons.pause,
                                        size: 30,
                                        color: context.theme.colors.foreground,
                                      ),
                                    )
                                  : // PLAY
                                    FButton.icon(
                                      style: FButtonStyle.ghost(),
                                      onPress: () {
                                        startTimer();
                                        animate();
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

  void animate() {
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
    const ms = Duration(milliseconds: 100);
    timer = Timer.periodic(ms, (Timer timer) {
      if (currTime <= 0) {
        setState(() {
          timer.cancel();
        });
      } else {
        currTime -= (ms.inMilliseconds / 1000);

        // hack for if user pauses a bunch and creates animation syncing issues
        // animationController listener was initially doing a bunch of setStates.
        // if it gets out of sync, this is needed:
        if (!animationController.isAnimating) {
          setState(() {});
        }
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
