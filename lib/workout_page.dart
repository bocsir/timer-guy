// workout_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'dart:async';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:progress_border/progress_border.dart';

enum WorkoutStatus { notStarted, paused, working, resting, preparing }

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
  late ValueNotifier<bool> workoutOver;

  @override
  void initState() {
    super.initState();
    currTime = widget.workout.sets[0].timeOn + 0.0;
    animationController = AnimationController(
      vsync: this,
      // duration: Duration(seconds: widget.workout.timeOn),
    );
    animationController.addListener(() {
      setState(() {});
    });

    currRep = ValueNotifier(1);
    currSet = ValueNotifier(1);
    status = ValueNotifier(WorkoutStatus.notStarted);
    workoutOver = ValueNotifier(false);
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
            children: [
              Text(widget.workout.name, style: typography.xlSemibold),
              if (!workoutOver.value)
                ListenableBuilder(
                  listenable: Listenable.merge([currSet, currRep, status]),
                  builder: (context, child) {
                    return Text(
                      'Set ${currSet.value} / ${widget.workout.sets.length} - Rep ${currRep.value} / ${widget.workout.sets[currSet.value].reps}',

                      style: typography.lgSemibold,
                    );
                  },
                ),
            ],
          ),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: ProgressBorder.all(
                    color: context.theme.colors.accent,
                    progress: animationController.value,
                    width: 6,
                    backgroundBorder: Border.all(color: context.theme.colors.border, width: 1),
                  ),
                  color: context.theme.colors.secondary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(64),
                  child: ValueListenableBuilder(
                    valueListenable: workoutOver,
                    builder: (context, value, child) {
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          workoutOver.value
                              ? Text('All done!', style: typography.xl3.copyWith(fontWeight: FontWeight.bold))
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.values.first,
                                  spacing: 4,
                                  children: [
                                    Text(currTime.toStringAsFixed(1).split('.')[0], style: typography.xl7),
                                    Text(currTime.toStringAsFixed(1).split('.')[1][0], style: typography.xl5),
                                  ],
                                ),
                          switch (status.value) {
                            WorkoutStatus.resting => Text('Rest', style: context.theme.typography.lgSemibold),
                            WorkoutStatus.working => Text('Go', style: context.theme.typography.lgSemibold),
                            WorkoutStatus.paused => Text('Paused', style: context.theme.typography.lgSemibold),
                            WorkoutStatus.preparing => Text('Get Ready', style: context.theme.typography.lgSemibold),
                            _ => SizedBox.shrink(),
                          },
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            spacing: 64,
                            children: [
                              FButton.icon(
                                style: FButtonStyle.ghost(),
                                onPress: () {}, //restartWorkout,
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
                                            if (status.value == WorkoutStatus.notStarted) {
                                              // Start 5 second preparation countdown
                                              status.value = WorkoutStatus.preparing;
                                              currTime = 5.0;
                                              animationController.duration = Duration(seconds: 5);
                                              // animationController.reset();
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
        if (!workoutOver.value) {
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
      animate(newStatus);
      // go to next rep / set
      if (currRep.value < set.reps) {
        currRep.value++;
        startTimer();
      } else if (currSet.value < widget.workout.sets.length) {
        // pause at end of each set
        animationController.reset();
        pause();
        currSet.value++;
        currRep.value = 1;
      } else {
        workoutOver.value = true;
        animationController.reset();
        pause();
      }
    }
  }

  void restartWorkout() {
    timer?.cancel();
    animationController.reset();
    animationController.duration = Duration(seconds: widget.workout.sets[currSet.value].timeOn);
    currSet.value = 1;
    currRep.value = 1;
    currTime = widget.workout.sets[currSet.value].timeOn + 0.0;
    status.value = WorkoutStatus.paused;
    workoutOver.value = false;
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
