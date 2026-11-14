// workout_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forui/forui.dart';
import 'package:progress_border/progress_border.dart';
import 'package:timer_guy/audio/beep_player.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/services/analytics_service.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/widgets/settings_menu_button.dart';
import 'package:timer_guy/widgets/workout_background.dart';
import 'package:timer_guy/working_resting_status.dart';
import 'package:timer_guy/workout_status.dart';

class WorkoutPage extends StatefulWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage>
    with SingleTickerProviderStateMixin {
  Timer? timer;
  late final Ticker _ticker;

  /// Wall-clock time elapsed in the current phase, used to interpolate the
  /// border between the timer's 100ms ticks.
  final Stopwatch _phaseWatch = Stopwatch();

  /// Tracks time spent actively working out (pauses are excluded).
  final Stopwatch _sessionWatch = Stopwatch();

  late double currTime;
  double _phaseDuration = 0;

  late List<_Phase> _phases;
  int _phaseIndex = 0;

  late final ValueNotifier<WorkoutStatus> status;
  WorkoutStatus? _statusBeforePause;

  bool _complete = false;
  bool _paused = false;
  bool _sessionStarted = false;
  bool _sessionRecorded = false;

  late WorkoutPalette _palette;
  bool _paletteInitialized = false;

  final initialDelay = 5.0;

  _Phase get _phase => _phases[_phaseIndex];
  Exercise get _exercise => _phase.exercise;
  bool get _isTimedPhase => _phase.kind != _PhaseKind.manual;

  @override
  void initState() {
    super.initState();
    status = ValueNotifier(WorkoutStatus.notStarted);
    _ticker = createTicker((_) => setState(() {}));
    _initializeWorkout();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_paletteInitialized) return;

    _palette = _newPalette();
    _paletteInitialized = true;
  }

  WorkoutPalette _newPalette() {
    final isDark = context.theme.colors.brightness == Brightness.dark;
    return WorkoutPalette.random(isDark: isDark);
  }

  /// Progress of the current phase (0..1).
  double get progress {
    if (_complete || _phaseDuration <= 0) return 0;

    final remaining =
        (_phaseDuration -
                _phaseWatch.elapsedMicroseconds /
                    Duration.microsecondsPerSecond)
            .clamp(0.0, _phaseDuration);

    return switch (_phase.kind) {
      _PhaseKind.work => (1 - remaining / _phaseDuration).clamp(0.0, 1.0),
      _PhaseKind.rest => (remaining / _phaseDuration).clamp(0.0, 1.0),
      _PhaseKind.prepare => 0,
      _PhaseKind.manual => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    if (widget.workout.exercises.isEmpty) {
      return FScaffold(
        header: Header(
          hideSettingsBtn: true,
          trailing: const SettingsMenuButton(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 64,
          children: [
            Text(
              'This workout has no exercises yet.',
              style: typography.xlSemibold,
            ),
          ],
        ),
      );
    }

    return FScaffold(
      childPad: false,
      header: Header(
        hideSettingsBtn: true,
        trailing: const SettingsMenuButton(),
      ),
      child: WorkoutBackgroundFrame(
        palette: _palette,
        status: status,
        progress: progress,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
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
                        child: Icon(FIcons.info, color: colors.mutedForeground),
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
                        horizontal: BorderSide(color: colors.border, width: 1),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 24,
                    ),
                    child: ListenableBuilder(
                      listenable: status,
                      builder: (context, child) {
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (!_complete)
                              WorkingRestingStatus(
                                status: status.value,
                                exercise: _exercise,
                              ),
                            Expanded(
                              child: Center(child: _buildCenter(context)),
                            ),
                            _buildExerciseNavigation(context),
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
                    onPress: _restartWorkout,
                    child: Icon(FIcons.refreshCw, size: 30),
                  ),
                  _buildMainControl(context),
                ],
              ),
            ),
            SizedBox(height: 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCenter(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    if (_complete) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          Text(
            'All done!',
            style: typography.xl3.copyWith(fontWeight: FontWeight.bold),
          ),
          FButton(
            style: FButtonStyle.outline(),
            onPress: _restartWorkout,
            child: Text('Start again', style: typography.lg),
          ),
        ],
      );
    }

    final phase = _phase;
    final exercise = _exercise;

    if (phase.kind == _PhaseKind.manual) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(
            exercise.name,
            textAlign: TextAlign.center,
            style: typography.xl3Semibold,
          ),
          Text(
            '${exercise.reps} reps',
            style: typography.xl2.copyWith(color: colors.mutedForeground),
          ),
          Text(
            'Set ${phase.setIndex + 1} of ${exercise.sets}',
            style: typography.lgSemibold.copyWith(color: colors.accent),
          ),
          const SizedBox(height: 8),
          DecoratedBox(
            decoration: BoxDecoration(
              border: BoxBorder.all(),
              borderRadius: BorderRadius.circular(16),
              color: colors.accent,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: FButton(
                style: FButtonStyle.ghost(),
                onPress: _onDonePressed,
                child: Text(
                  'Done',
                  style: typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colors.background,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    final subtitle = switch (phase.kind) {
      _PhaseKind.prepare => 'Rep 1 of ${exercise.reps}',
      _PhaseKind.work => 'Rep ${phase.repIndex + 1} of ${exercise.reps}',
      _PhaseKind.rest when exercise.isReps =>
        'After set ${phase.setIndex + 1} of ${exercise.sets}',
      _PhaseKind.rest => 'After rep ${phase.repIndex + 1} of ${exercise.reps}',
      _PhaseKind.manual => '',
    };

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 8,
      children: [
        Text(
          exercise.name,
          textAlign: TextAlign.center,
          style: typography.xl2.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          subtitle,
          style: typography.sm.copyWith(color: colors.mutedForeground),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.values.first,
          spacing: 4,
          children: [
            Text(
              currTime.toStringAsFixed(1).split('.')[0],
              style: typography.xl8,
            ),
            Text(
              currTime.toStringAsFixed(1).split('.')[1][0],
              style: typography.xl6,
            ),
          ],
        ),
        if (status.value == WorkoutStatus.notStarted)
          Text(
            'Press play to start',
            style: typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.mutedForeground,
            ),
          )
        else if (status.value == WorkoutStatus.preparing)
          Text(
            'Get ready...',
            style: typography.lg.copyWith(fontWeight: FontWeight.bold),
          )
        else if (status.value == WorkoutStatus.working)
          Text(
            'Go!',
            style: typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.accent,
            ),
          )
        else if (status.value == WorkoutStatus.resting)
          Text(
            'Rest',
            style: typography.lg.copyWith(
              fontWeight: FontWeight.bold,
              color: colors.accent,
            ),
          )
        else if (status.value == WorkoutStatus.paused)
          Text(
            'Paused',
            style: typography.lg.copyWith(fontWeight: FontWeight.bold),
          ),
      ],
    );
  }

  Widget _buildExerciseNavigation(BuildContext context) {
    final typography = context.theme.typography;
    final exerciseCount = widget.workout.exercises.length;

    return Column(
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () => _goToExercise(_exerciseIndex - 1),
              child: Icon(FIcons.chevronLeft),
            ),
            Text(
              'Exercise ${_exerciseIndex + 1} | $exerciseCount',
              style: typography.lgSemibold,
            ),
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () => _goToExercise(_exerciseIndex + 1),
              child: Icon(FIcons.chevronRight),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainControl(BuildContext context) {
    final colors = context.theme.colors;

    if (_complete) {
      return _accentControl(
        icon: FIcons.play,
        onPress: _restartWorkout,
        colors: colors,
      );
    }

    if (!_isTimedPhase) {
      return const SizedBox(width: 46, height: 46);
    }

    if (status.value == WorkoutStatus.notStarted ||
        status.value == WorkoutStatus.paused) {
      return _accentControl(
        icon: FIcons.play,
        onPress: status.value == WorkoutStatus.notStarted
            ? _startWorkout
            : pause,
        colors: colors,
      );
    }

    return _accentControl(icon: FIcons.pause, onPress: pause, colors: colors);
  }

  Widget _accentControl({
    required IconData icon,
    required VoidCallback onPress,
    required FColors colors,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: BoxBorder.all(),
        borderRadius: BorderRadius.circular(16),
        color: colors.accent,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: FButton.icon(
          style: FButtonStyle.ghost(),
          onPress: onPress,
          child: Icon(icon, size: 30, color: colors.foreground),
        ),
      ),
    );
  }

  int get _exerciseIndex => _phase.exerciseIndex;

  void _initializeWorkout({bool newPalette = false}) {
    timer?.cancel();
    _phaseWatch.stop();
    _ticker.stop();

    _phases = _buildPhases();
    _phaseIndex = 0;
    _complete = false;
    _paused = false;
    _statusBeforePause = null;
    _sessionStarted = false;
    _sessionRecorded = false;
    _sessionWatch
      ..stop()
      ..reset();

    if (_phases.isEmpty) {
      _complete = true;
      currTime = 0;
      _phaseDuration = 0;
      status.value = WorkoutStatus.complete;
    } else {
      final phase = _phases.first;
      currTime = phase.duration.toDouble();
      _phaseDuration = phase.duration.toDouble();
      status.value = phase.kind == _PhaseKind.manual
          ? WorkoutStatus.working
          : WorkoutStatus.notStarted;
    }

    if (newPalette) _palette = _newPalette();
  }

  List<_Phase> _buildPhases() {
    final phases = <_Phase>[];
    final exercises = widget.workout.exercises;

    for (
      var exerciseIndex = 0;
      exerciseIndex < exercises.length;
      exerciseIndex++
    ) {
      final exercise = exercises[exerciseIndex];

      if (exercise.isInterval) {
        final reps = exercise.reps < 1 ? 1 : exercise.reps;
        phases.add(
          _Phase(
            kind: _PhaseKind.prepare,
            exerciseIndex: exerciseIndex,
            exercise: exercise,
            duration: initialDelay.round(),
          ),
        );

        for (var rep = 0; rep < reps; rep++) {
          phases.add(
            _Phase(
              kind: _PhaseKind.work,
              exerciseIndex: exerciseIndex,
              exercise: exercise,
              duration: exercise.timeOn,
              repIndex: rep,
            ),
          );

          if (rep < reps - 1) {
            phases.add(
              _Phase(
                kind: _PhaseKind.rest,
                exerciseIndex: exerciseIndex,
                exercise: exercise,
                duration: exercise.timeOff,
                repIndex: rep,
              ),
            );
          }
        }
      } else {
        final sets = exercise.sets < 1 ? 1 : exercise.sets;

        for (var set = 0; set < sets; set++) {
          phases.add(
            _Phase(
              kind: _PhaseKind.manual,
              exerciseIndex: exerciseIndex,
              exercise: exercise,
              duration: 0,
              setIndex: set,
            ),
          );

          final isLastSetOfExercise = set == sets - 1;
          final isLastExercise = exerciseIndex == exercises.length - 1;

          if (!(isLastSetOfExercise && isLastExercise)) {
            phases.add(
              _Phase(
                kind: _PhaseKind.rest,
                exerciseIndex: exerciseIndex,
                exercise: exercise,
                duration: exercise.timeOff,
                setIndex: set,
              ),
            );
          }
        }
      }
    }

    return phases;
  }

  void _startWorkout() {
    if (_complete || _phases.isEmpty) return;

    _startSession();
    _paused = false;
    _statusBeforePause = null;

    if (_phase.kind == _PhaseKind.manual) {
      status.value = WorkoutStatus.working;
      setState(() {});
    } else {
      _startTimedPhase(_phase);
    }
  }

  void _startSession() {
    if (_sessionStarted) {
      if (!_sessionWatch.isRunning) _sessionWatch.start();
      return;
    }

    _sessionStarted = true;
    _sessionWatch
      ..reset()
      ..start();
  }

  void _startTimedPhase(_Phase phase) {
    timer?.cancel();
    _phaseWatch.stop();
    _ticker.stop();

    currTime = phase.duration.toDouble();
    _phaseDuration = phase.duration.toDouble();
    status.value = switch (phase.kind) {
      _PhaseKind.prepare => WorkoutStatus.preparing,
      _PhaseKind.work => WorkoutStatus.working,
      _PhaseKind.rest => WorkoutStatus.resting,
      _PhaseKind.manual => WorkoutStatus.working,
    };

    if (phase.duration <= 0) {
      _advancePhase();
      return;
    }

    _phaseWatch
      ..reset()
      ..start();
    _ticker.start();
    _startTimer();
    setState(() {});
  }

  void _startTimer() {
    const ms = Duration(milliseconds: 100);
    timer?.cancel();
    timer = Timer.periodic(ms, (Timer timer) {
      if (_paused) return;

      if (currTime <= ms.inMilliseconds / 1000) {
        timer.cancel();
        _phaseComplete();
      } else {
        setState(() {
          currTime -= ms.inMilliseconds / 1000;
        });

        // Countdown beeps only for interval work/rest phases.
        if (_exercise.isInterval &&
            (status.value == WorkoutStatus.resting ||
                status.value == WorkoutStatus.preparing)) {
          final t = (currTime * 10).round() / 10;
          if (t == 3.0 || t == 2.0 || t == 1.0) {
            BeepPlayer.playNormal();
          }
        }
      }
    });
  }

  void _phaseComplete() {
    final phase = _phase;

    timer?.cancel();
    _phaseWatch.stop();
    _ticker.stop();

    switch (phase.kind) {
      case _PhaseKind.prepare:
      case _PhaseKind.work:
        BeepPlayer.playHigh();
      case _PhaseKind.rest:
        if (phase.exercise.isReps) {
          BeepPlayer.playDouble();
        } else {
          BeepPlayer.playHigh();
        }
      case _PhaseKind.manual:
        break;
    }

    _advancePhase();
  }

  void _advancePhase() {
    if (_phaseIndex + 1 >= _phases.length) {
      _completeWorkout();
      return;
    }

    _phaseIndex++;
    final next = _phase;

    if (next.kind == _PhaseKind.manual) {
      timer?.cancel();
      _phaseWatch.stop();
      _ticker.stop();
      currTime = 0;
      _phaseDuration = 0;
      _paused = false;
      status.value = WorkoutStatus.working;
      setState(() {});
    } else {
      _startTimedPhase(next);
    }
  }

  void _onDonePressed() {
    if (_complete || _phase.kind != _PhaseKind.manual) return;

    _startSession();
    _advancePhase();
  }

  void _completeWorkout() {
    timer?.cancel();
    _phaseWatch.stop();
    _ticker.stop();
    _sessionWatch.stop();
    _recordSession(completed: true);

    setState(() {
      _complete = true;
      status.value = WorkoutStatus.complete;
    });
  }

  void pause() {
    if (_complete || !_isTimedPhase) return;
    if (status.value == WorkoutStatus.notStarted) return;

    if (status.value == WorkoutStatus.paused) {
      _paused = false;
      status.value = _statusBeforePause ?? WorkoutStatus.working;
      _sessionWatch.start();
      _phaseWatch.start();
      _ticker.start();
      _startTimer();
    } else {
      _statusBeforePause = status.value;
      _paused = true;
      status.value = WorkoutStatus.paused;
      _sessionWatch.stop();
      _phaseWatch.stop();
      _ticker.stop();
      timer?.cancel();
    }

    setState(() {});
  }

  void _goToExercise(int index) {
    if (index < 0 || index >= widget.workout.exercises.length) return;

    timer?.cancel();
    _phaseWatch.stop();
    _ticker.stop();

    final target = _phases.indexWhere((phase) => phase.exerciseIndex == index);
    if (target < 0) return;

    _phaseIndex = target;
    _complete = false;
    _paused = false;
    _statusBeforePause = null;

    final phase = _phase;
    currTime = phase.duration.toDouble();
    _phaseDuration = phase.duration.toDouble();
    status.value = phase.kind == _PhaseKind.manual
        ? WorkoutStatus.working
        : WorkoutStatus.notStarted;

    setState(() {});
  }

  void _restartWorkout() {
    _initializeWorkout(newPalette: true);
    setState(() {});
  }

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

  @override
  void dispose() {
    _recordSession(completed: false);
    timer?.cancel();
    _phaseWatch.stop();
    _sessionWatch.stop();
    _ticker.dispose();
    status.dispose();
    super.dispose();
  }
}

enum _PhaseKind { prepare, work, rest, manual }

class _Phase {
  const _Phase({
    required this.kind,
    required this.exerciseIndex,
    required this.exercise,
    required this.duration,
    this.repIndex = 0,
    this.setIndex = 0,
  });

  final _PhaseKind kind;
  final int exerciseIndex;
  final Exercise exercise;
  final int duration;
  final int repIndex;
  final int setIndex;
}
