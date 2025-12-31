// workout_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'dart:async';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:progress_border/progress_border.dart';

enum WorkoutStatus { notStarted, preparing, working, resting, paused, complete }

class WorkoutPage extends StatefulWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage> with TickerProviderStateMixin {
  late final AnimationController animationController;
  Timer? timer;
  late double currTime;

  late ValueNotifier<int> currRep;
  late ValueNotifier<int> currSet;
  late ValueNotifier<WorkoutStatus> status;

  final initialDelay = 5.0;

  @override
  void initState() {
    super.initState();
    currTime = initialDelay;
    animationController = AnimationController(vsync: this)
      ..addListener(() {
        setState(() {});
      });

    currRep = ValueNotifier(0);
    currSet = ValueNotifier(0);
    status = ValueNotifier(WorkoutStatus.notStarted);
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [Text(widget.workout.name, style: typography.xl3Semibold)],
          ),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: ProgressBorder.all(
                    color: status.value == WorkoutStatus.paused || status.value == WorkoutStatus.notStarted
                        ? context.theme.colors.border
                        : context.theme.colors.accent,
                    progress: animationController.value,
                    width: 6,
                    backgroundBorder: Border.all(color: context.theme.colors.border, width: 1),
                  ),
                  color: context.theme.colors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: ListenableBuilder(
                    listenable: status,
                    builder: (context, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          switch (status.value) {
                            WorkoutStatus.complete => Text(
                              'All done!',
                              style: typography.xl3.copyWith(fontWeight: FontWeight.bold),
                            ),
                            _ => Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.values.first,
                              spacing: 4,
                              children: [
                                Text(currTime.toStringAsFixed(1).split('.')[0], style: typography.xl7),
                                Text(currTime.toStringAsFixed(1).split('.')[1][0], style: typography.xl5),
                              ],
                            ),
                          },
                          Column(
                            spacing: 16,
                            children: [
                              ConstrainedBox(
                                constraints: BoxConstraints(maxWidth: 140),
                                child: Column(
                                  spacing: 8,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Set', style: typography.lgSemibold),
                                        Text(
                                          '${currSet.value + 1} | ${widget.workout.sets.length}',
                                          style: typography.lgSemibold,
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Rep', style: typography.lgSemibold),
                                        Text(
                                          '${currRep.value + 1} | ${widget.workout.sets[currSet.value].reps}',
                                          style: typography.lgSemibold,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              DefaultTextStyle(
                                style: context.theme.typography.xl3Semibold,
                                child: switch (status.value) {
                                  WorkoutStatus.resting => Text('Rest'),
                                  WorkoutStatus.working => Text(
                                    'Go!',
                                    style: TextStyle(color: context.theme.colors.accent),
                                  ),
                                  WorkoutStatus.preparing => Text(
                                    'Get Ready...',
                                    style: context.theme.typography.lgSemibold,
                                  ),
                                  _ => SizedBox(height: 39),
                                },
                              ),
                            ],
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 64,
                            children: [
                              FButton.icon(
                                style: FButtonStyle.ghost(),
                                onPress: () => restartSet(0),
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
                                  child: status.value == WorkoutStatus.working || status.value == WorkoutStatus.resting
                                      ? // show pause
                                        FButton.icon(
                                          style: FButtonStyle.ghost(),
                                          onPress: pause,
                                          child: Icon(FIcons.pause, size: 30, color: context.theme.colors.foreground),
                                        )
                                      : // show play
                                        FButton.icon(
                                          style: FButtonStyle.ghost(),
                                          onPress: () {
                                            if (status.value == WorkoutStatus.preparing) return;
                                            if (status.value == WorkoutStatus.notStarted) {
                                              status.value = WorkoutStatus.preparing;
                                              animationController.duration = Duration(seconds: initialDelay.toInt());
                                              animationController.reset();
                                              animate(WorkoutStatus.preparing);
                                              startTimer();
                                            } else {
                                              // Resume from paused state
                                              if (animationController.status == AnimationStatus.reverse) {
                                                status.value = WorkoutStatus.resting;
                                              } else {
                                                status.value = WorkoutStatus.working;
                                              }
                                              animate(status.value);
                                              startTimer();
                                            }
                                          },
                                          child: Icon(FIcons.play, size: 30, color: context.theme.colors.foreground),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
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

  void animate(WorkoutStatus status) {
    switch (status) {
      case WorkoutStatus.working:
        animationController.forward();
      case WorkoutStatus.paused:
        animationController.status == AnimationStatus.reverse
            ? animationController.reverse()
            : animationController.forward();
      case WorkoutStatus.notStarted:
        animationController.forward();
      case WorkoutStatus.resting:
        animationController.reverse();
      case WorkoutStatus.preparing:
        animationController.reverse();
      case WorkoutStatus.complete:
        animationController.stop();
    }
  }

  void pause() {
    status.value = WorkoutStatus.paused;
    animationController.stop();
    timer?.cancel();
    setState(() {});
  }

  void startTimer() {
    const ms = Duration(milliseconds: 100);
    timer = Timer.periodic(ms, (Timer timer) {
      // if current time <= 1/10 second. this is to avoid showing negative time
      if (currTime <= ms.inMilliseconds / 1000) {
        if (status.value != WorkoutStatus.complete) {
          workOrRestComplete();
        }
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

  // called after an iteration completes
  void workOrRestComplete() {
    final set = widget.workout.sets[currSet.value];
    if (status.value == WorkoutStatus.preparing) {
      // preparation complete, start working
      final newStatus = WorkoutStatus.working;
      status.value = newStatus;
      final tOn = set.timeOn;
      currTime = tOn + 0.0;
      animationController.duration = Duration(seconds: tOn);
      animationController.reset();
      animate(newStatus);
      startTimer();
    } else if (status.value == WorkoutStatus.resting) {
      // set up working stuff
      final newStatus = WorkoutStatus.working;
      status.value = newStatus;
      final tOn = set.timeOn;
      currTime = tOn + 0.0;
      animationController.duration = Duration(seconds: tOn);
      animate(newStatus);
      startTimer();
    } else {
      // set up resting stuff
      final newStatus = WorkoutStatus.resting;
      status.value = newStatus;
      final tOff = set.timeOff;
      currTime = tOff + 0.0;
      animationController.duration = Duration(seconds: tOff);
      if (currRep.value + 1 < set.reps) {
        // go to next rep
        currRep.value++;
        startTimer();
        animate(newStatus);
      } else if (currSet.value + 1 < widget.workout.sets.length) {
        // go to next set
        restartSet(currSet.value + 1);
      } else {
        status.value = WorkoutStatus.complete;
        animationController.reset();
        pause();
      }
    }
  }

  // go to beginning of provided set (0 indexed)
  void restartSet(int setIndex) {
    timer?.cancel();
    animationController.reset();
    animationController.duration = Duration(seconds: widget.workout.sets[setIndex].timeOn);
    currSet.value = setIndex;
    currRep.value = 0;
    currTime = initialDelay;
    status.value = WorkoutStatus.notStarted;
    setState(() {});
  }

  @override
  void dispose() {
    timer?.cancel();
    animationController.dispose();
    currRep.dispose();
    currSet.dispose();
    status.dispose();
    super.dispose();
  }
}
