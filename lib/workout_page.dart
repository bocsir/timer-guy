// workout_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/dance.dart';
import 'package:timer_guy/header.dart';
import 'dart:async';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:progress_border/progress_border.dart';
import 'package:timer_guy/audio/beep_player.dart';
import 'package:timer_guy/services/analytics_service.dart';
import 'package:timer_guy/working_resting_status.dart';

enum WorkoutStatus { notStarted, preparing, working, resting, paused, complete }

class WorkoutPage extends StatefulWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  late double currTime;

  /// Drives 60fps rebuilds of the progress border. Purely visual; the timer
  /// remains the source of truth for the workout's logic.
  late final Ticker _ticker;

  /// Wall-clock time elapsed in the current phase, used to interpolate the
  /// border between the timer's 100ms ticks.
  final Stopwatch _phaseWatch = Stopwatch();
  double _phaseDuration = 0;

  late ValueNotifier<int> currRep;
  late ValueNotifier<int> currSet;
  late ValueNotifier<WorkoutStatus> status;

  /// The status that was active before [pause] was called, so it can be
  /// restored when the workout resumes.
  WorkoutStatus? _statusBeforePause;

  /// Tracks time spent actively working out (pauses are excluded) for
  /// analytics.
  final Stopwatch _sessionWatch = Stopwatch();
  bool _sessionStarted = false;

  /// Whether the current run has already been stored in analytics.
  bool _sessionRecorded = false;

  final initialDelay = 5.0;

  @override
  void initState() {
    super.initState();
    currTime = initialDelay;
    _ticker = createTicker((_) => setState(() {}));

    currRep = ValueNotifier(0);
    currSet = ValueNotifier(0);
    status = ValueNotifier(WorkoutStatus.notStarted);
  }

  /// Progress of the current phase (0..1).
  ///
  /// Derived from the phase's wall-clock elapsed time so the border moves
  /// smoothly at 60fps while staying in lockstep with the countdown.
  double get progress {
    if (widget.workout.sets.isEmpty || _phaseDuration <= 0) return 0;

    final remaining =
        (_phaseDuration -
                _phaseWatch.elapsedMicroseconds /
                    Duration.microsecondsPerSecond)
            .clamp(0.0, _phaseDuration);

    final phase = status.value == WorkoutStatus.paused
        ? (_statusBeforePause ?? WorkoutStatus.working)
        : status.value;

    switch (phase) {
      case WorkoutStatus.working:
        return (1 - remaining / _phaseDuration).clamp(0.0, 1.0);
      case WorkoutStatus.resting:
        return (remaining / _phaseDuration).clamp(0.0, 1.0);
      case WorkoutStatus.paused:
      case WorkoutStatus.preparing:
      case WorkoutStatus.notStarted:
      case WorkoutStatus.complete:
        return 0;
    }
  }

  void _startPhase(double duration, {bool animate = true}) {
    _phaseDuration = duration;
    _phaseWatch
      ..reset()
      ..start();

    if (animate) {
      if (!_ticker.isActive) _ticker.start();
    } else {
      _ticker.stop();
    }
  }

  void _stopPhase() {
    _phaseWatch.stop();
    _ticker.stop();
  }

  @override
  Widget build(context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    return FScaffold(
      childPad: false,
      header: Header(hideSettingsBtn: true),
      child: widget.workout.sets.isEmpty
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 64,
              children: [
                Text(
                  "This page gets much more interesting if you add sets to the workout.",
                  style: typography.xlSemibold,
                ),
                Dance(),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Row(
                    spacing: 8,
                    children: [
                      Text(widget.workout.name, style: typography.xl3Semibold),
                      if (widget.workout.description case final description?
                          when description.isNotEmpty)
                        FPopover(
                          popoverAnchor: Alignment.topCenter,
                          childAnchor: Alignment.bottomCenter,
                          popoverBuilder: (context, _) => ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 300),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 16,
                              ),
                              child: Text(description),
                            ),
                          ),
                          builder: (_, controller, _) => FButton(
                            onPress: controller.toggle,
                            style: FButtonStyle.ghost(),
                            child: Icon(
                              FIcons.info,
                              color: colors.mutedForeground,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: SizedBox(
                    width: double.infinity,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        border: ProgressBorder.all(
                          color:
                              status.value == WorkoutStatus.paused ||
                                  status.value == WorkoutStatus.notStarted
                              ? colors.border
                              : colors.accent,
                          progress: progress,
                          width: 6,
                          backgroundBorder: Border.symmetric(
                            horizontal: BorderSide(
                              color: colors.border,
                              width: 1,
                            ),
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 64,
                          vertical: 32,
                        ),
                        child: ListenableBuilder(
                          listenable: status,
                          builder: (context, child) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                WorkingRestingStatus(
                                  status: status.value,
                                  workout: widget.workout,
                                  currSet: currSet.value,
                                ),
                                switch (status.value) {
                                  WorkoutStatus.complete => Text(
                                    'All done!',
                                    style: typography.xl3.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  _ => Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.baseline,
                                        textBaseline: TextBaseline.values.first,
                                        spacing: 4,
                                        children: [
                                          Text(
                                            currTime
                                                .toStringAsFixed(1)
                                                .split('.')[0],
                                            style: typography.xl8,
                                          ),
                                          Text(
                                            currTime
                                                .toStringAsFixed(1)
                                                .split('.')[1][0],
                                            style: typography.xl6,
                                          ),
                                        ],
                                      ),
                                      if (status.value ==
                                          WorkoutStatus.preparing)
                                        Text(
                                          'Get ready...',
                                          style: typography.xl.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      if (status.value == WorkoutStatus.working)
                                        Text(
                                          'Go!',
                                          style: typography.xl.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: colors.accent,
                                          ),
                                        ),
                                    ],
                                  ),
                                },
                                Column(
                                  spacing: 8,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              'Current Set: ',
                                              style: typography.sm.copyWith(
                                                height: 20 / 14,
                                              ),
                                            ),
                                            Text(
                                              widget
                                                  .workout
                                                  .sets[currSet.value]
                                                  .name,
                                              style: typography.xlSemibold
                                                  .copyWith(height: 1),
                                            ),
                                          ],
                                        ),
                                        //if (widget.workout.sets[currSet.value].description != null)
                                        // FPopover(
                                        //   popoverAnchor: Alignment.topCenter,
                                        //   childAnchor: Alignment.bottomCenter,
                                        //   popoverBuilder: (context, _) => Padding(
                                        //     padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                        //     child: Text('[description placeholder text]'),
                                        //   ),
                                        //   builder: (_, controller, _) => FButton(
                                        //     onPress: controller.toggle,
                                        //     style: FButtonStyle.ghost(),
                                        //     child: Icon(FIcons.info, color: colors.mutedForeground),
                                        //   ),
                                        // ),
                                      ],
                                    ),

                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        FButton.icon(
                                          style: FButtonStyle.ghost(),
                                          child: Icon(FIcons.chevronLeft),
                                          onPress: () {
                                            pause();
                                            if (currSet.value > 0) {
                                              setState(() => currSet.value--);
                                            }
                                          },
                                        ),
                                        Text(
                                          'Set',
                                          style: typography.lgSemibold,
                                        ),
                                        Text(
                                          '${currSet.value + 1} | ${widget.workout.sets.length}',
                                          style: typography.lgSemibold,
                                        ),
                                        FButton.icon(
                                          style: FButtonStyle.ghost(),
                                          child: Icon(FIcons.chevronRight),
                                          onPress: () {
                                            pause();
                                            if (widget.workout.sets.length - 1 >
                                                currSet.value) {
                                              setState(() => currSet.value++);
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        FButton.icon(
                                          style: FButtonStyle.ghost(),
                                          child: Icon(FIcons.chevronLeft),
                                          onPress: () {
                                            pause();
                                            if (currRep.value > 0) {
                                              setState(() => currRep.value--);
                                            }
                                          },
                                        ),
                                        Text(
                                          'Rep',
                                          style: typography.lgSemibold,
                                        ),
                                        Text(
                                          '${currRep.value + 1} | ${widget.workout.sets[currSet.value].reps}',
                                          style: typography.lgSemibold,
                                        ),
                                        FButton.icon(
                                          style: FButtonStyle.ghost(),
                                          child: Icon(FIcons.chevronRight),
                                          onPress: () {
                                            pause();
                                            if (widget
                                                        .workout
                                                        .sets[currSet.value]
                                                        .reps -
                                                    1 >
                                                currRep.value) {
                                              setState(() => currRep.value++);
                                            }
                                          },
                                        ),
                                      ],
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
                Padding(
                  padding: const EdgeInsets.only(top: 8, bottom: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
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
                          color: colors.accent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child:
                              status.value == WorkoutStatus.working ||
                                  status.value == WorkoutStatus.resting
                              ? // show pause
                                FButton.icon(
                                  style: FButtonStyle.ghost(),
                                  onPress: pause,
                                  child: Icon(
                                    FIcons.pause,
                                    size: 30,
                                    color: colors.foreground,
                                  ),
                                )
                              : // show play
                                FButton.icon(
                                  style: FButtonStyle.ghost(),
                                  onPress: () {
                                    if (status.value ==
                                        WorkoutStatus.preparing) {
                                      return;
                                    }
                                    setState(() {
                                      if (status.value ==
                                          WorkoutStatus.complete) {
                                        _sessionStarted = false;
                                        _sessionRecorded = false;
                                        _sessionWatch
                                          ..stop()
                                          ..reset();
                                        restartSet(0);
                                      } else if (status.value ==
                                          WorkoutStatus.notStarted) {
                                        _sessionStarted = true;
                                        _sessionWatch
                                          ..reset()
                                          ..start();
                                        status.value = WorkoutStatus.preparing;
                                        _startPhase(
                                          initialDelay,
                                          animate: false,
                                        );
                                        startTimer();
                                      } else {
                                        // Resume from paused state with the
                                        // same countdown as a fresh start.
                                        _sessionWatch.start();
                                        status.value = WorkoutStatus.preparing;
                                        currTime = initialDelay;
                                        _startPhase(
                                          initialDelay,
                                          animate: false,
                                        );
                                        startTimer();
                                      }
                                    });
                                  },
                                  child: Icon(
                                    FIcons.play,
                                    size: 30,
                                    color: colors.foreground,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 4),
              ],
            ),
    );
  }

  void pause() {
    if (status.value == WorkoutStatus.notStarted) return;
    if (status.value == WorkoutStatus.working ||
        status.value == WorkoutStatus.resting) {
      _statusBeforePause = status.value;
    }
    status.value = WorkoutStatus.paused;
    _sessionWatch.stop();
    _stopPhase();
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

        // beep beep beep
        if (status.value == WorkoutStatus.resting ||
            status.value == WorkoutStatus.preparing) {
          final t = (currTime * 10).round() / 10;
          if (t == 3.0 || t == 2.0 || t == 1.0) {
            BeepPlayer.playNormal();
          }
        }

        setState(() {});
      }
    });
  }

  // called after an iteration completes
  void workOrRestComplete() {
    final set = widget.workout.sets[currSet.value];
    if (status.value == WorkoutStatus.preparing ||
        status.value == WorkoutStatus.resting) {
      // preparation/rest complete, start working
      status.value = WorkoutStatus.working;
      currTime = set.timeOn + 0.0;
      _startPhase(set.timeOn + 0.0);
      BeepPlayer.playHigh();
      startTimer();
    } else {
      // set up resting stuff
      status.value = WorkoutStatus.resting;
      currTime = set.timeOff + 0.0;
      _startPhase(set.timeOff + 0.0);
      if (currRep.value + 1 < set.reps) {
        // go to next rep
        BeepPlayer.playHigh();
        currRep.value++;
        startTimer();
      } else if (currSet.value + 1 < widget.workout.sets.length) {
        // go to next set
        restartSet(currSet.value + 1);
      } else {
        status.value = WorkoutStatus.complete;
        _sessionWatch.stop();
        _recordSession(completed: true);
        _stopPhase();
        _phaseDuration = 0;
        timer?.cancel();
        setState(() {});
      }
    }
  }

  /// Stores the run in analytics once, either when it completes or when the
  /// user leaves early.
  void _recordSession({required bool completed}) {
    if (_sessionRecorded || !_sessionStarted) return;

    final workoutKey = widget.workout.key;
    if (workoutKey is! int) return;

    final duration = _sessionWatch.elapsed.inSeconds;
    if (duration <= 0) return;

    AnalyticsService.instance.recordSession(
      workoutKey: workoutKey,
      durationSeconds: duration,
      completed: completed,
    );
    _sessionRecorded = true;
  }

  // go to beginning of provided set (0 indexed)
  void restartSet(int setIndex) {
    timer?.cancel();
    _stopPhase();
    _phaseDuration = 0;
    currSet.value = setIndex;
    currRep.value = 0;
    currTime = initialDelay;
    status.value = WorkoutStatus.notStarted;
    setState(() {});
  }

  @override
  void dispose() {
    _recordSession(completed: false);
    timer?.cancel();
    _ticker.dispose();
    currRep.dispose();
    currSet.dispose();
    status.dispose();
    super.dispose();
  }
}
