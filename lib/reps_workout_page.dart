// reps_workout_page.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forui/forui.dart';
import 'package:progress_border/progress_border.dart';
import 'package:timer_guy/audio/beep_player.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/services/analytics_service.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/widgets/settings_menu_button.dart';
import 'package:timer_guy/widgets/workout_background.dart';
import 'package:timer_guy/workout_status.dart';

/// A workout where the user performs each set's reps at their own pace.
///
/// Tapping "Done" starts the authored rest timer for the current set. When the
/// rest ends, the next set is shown and two beeps signal that it is time to
/// start it.
class RepsWorkoutPage extends StatefulWidget {
  final Workout workout;

  const RepsWorkoutPage({super.key, required this.workout});

  @override
  State<RepsWorkoutPage> createState() => _RepsWorkoutPageState();
}

class _RepsWorkoutPageState extends State<RepsWorkoutPage>
    with SingleTickerProviderStateMixin {
  Timer? _restTimer;
  late final Ticker _ticker;

  int _currSet = 0;
  double _currTime = 0;
  double _restDuration = 0;
  bool _resting = false;
  bool _paused = false;
  bool _complete = false;

  final Stopwatch _restWatch = Stopwatch();
  final Stopwatch _sessionWatch = Stopwatch();
  bool _sessionStarted = false;
  bool _sessionRecorded = false;

  late final ValueNotifier<WorkoutStatus> _status;

  late WorkoutPalette _palette;
  bool _paletteInitialized = false;

  List<WorkoutSet> get _sets => widget.workout.sets;

  @override
  void initState() {
    super.initState();
    _status = ValueNotifier(WorkoutStatus.working);
    _ticker = createTicker((_) => setState(() {}));
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

  /// Progress of the rest timer, 0..1. Uses the stopwatch so the progress
  /// border keeps moving smoothly between the timer's 100 ms ticks.
  double get _progress {
    if (!_resting || _restDuration <= 0) return 0;

    final remaining =
        (_restDuration -
                _restWatch.elapsedMicroseconds / Duration.microsecondsPerSecond)
            .clamp(0.0, _restDuration);

    return (remaining / _restDuration).clamp(0.0, 1.0);
  }

  String _formatRestTime(double seconds) {
    final total = seconds.ceil().clamp(0, 99 * 60);
    final minutes = total ~/ 60;
    final remainingSeconds = total % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;

    if (_sets.isEmpty) {
      return FScaffold(
        header: Header(
          hideSettingsBtn: true,
          trailing: const SettingsMenuButton(),
        ),
        child: Center(
          child: Text(
            'This workout has no sets yet.',
            style: typography.xlSemibold,
          ),
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
        status: _status,
        progress: _progress,
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
                      color: _paused || _complete
                          ? colors.border
                          : colors.accent,
                      progress: _progress,
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
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _resting
                              ? 'Rest'
                              : 'Set ${_currSet + 1} of ${_sets.length}',
                          style: typography.lgSemibold.copyWith(
                            color: _resting
                                ? colors.accent
                                : colors.mutedForeground,
                          ),
                        ),
                        Expanded(child: Center(child: _buildCenter(context))),
                        _buildSetNavigation(context),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8),
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
            onPress: _restart,
            child: Text('Start again', style: typography.lg),
          ),
        ],
      );
    }

    if (_resting) {
      final next = _currSet + 1 < _sets.length ? _sets[_currSet + 1] : null;

      return Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 12,
        children: [
          Text(_formatRestTime(_currTime), style: typography.xl8),
          if (next != null)
            Text(
              'Next: ${next.name} - ${next.reps} reps',
              textAlign: TextAlign.center,
              style: typography.lg.copyWith(color: colors.mutedForeground),
            ),
          FButton.icon(
            style: FButtonStyle.ghost(),
            onPress: _togglePause,
            child: Icon(_paused ? FIcons.play : FIcons.pause, size: 28),
          ),
        ],
      );
    }

    final set = _sets[_currSet];

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        Text(
          set.name,
          textAlign: TextAlign.center,
          style: typography.xl3Semibold,
        ),
        Text(
          '${set.reps} reps',
          style: typography.xl2.copyWith(color: colors.mutedForeground),
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

  Widget _buildSetNavigation(BuildContext context) {
    final typography = context.theme.typography;

    return Column(
      spacing: 8,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () => _goToSet(_currSet - 1),
              child: Icon(FIcons.chevronLeft),
            ),
            Text(
              'Set ${_currSet + 1} | ${_sets.length}',
              style: typography.lgSemibold,
            ),
            FButton.icon(
              style: FButtonStyle.ghost(),
              onPress: () => _goToSet(_currSet + 1),
              child: Icon(FIcons.chevronRight),
            ),
          ],
        ),
        FButton.icon(
          style: FButtonStyle.ghost(),
          onPress: _restart,
          child: Icon(FIcons.refreshCw, size: 26),
        ),
      ],
    );
  }

  void _onDonePressed() {
    if (_complete || _resting) return;

    if (!_sessionStarted) {
      _sessionStarted = true;
      _sessionWatch
        ..reset()
        ..start();
    } else if (!_sessionWatch.isRunning) {
      _sessionWatch.start();
    }

    if (_currSet + 1 >= _sets.length) {
      _completeWorkout();
      return;
    }

    final rest = _sets[_currSet].timeOff.toDouble();
    if (rest <= 0) {
      _finishRest();
      return;
    }

    setState(() {
      _resting = true;
      _paused = false;
      _currTime = rest;
      _restDuration = rest;
      _status.value = WorkoutStatus.resting;
    });

    _restWatch
      ..reset()
      ..start();
    _ticker.start();
    _startRestTimer();
  }

  void _startRestTimer() {
    _restTimer?.cancel();
    _restTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      if (_paused) return;

      if (_currTime <= 0.1) {
        _finishRest();
      } else {
        setState(() {
          _currTime = (_currTime - 0.1).clamp(0.0, _restDuration);
        });
      }
    });
  }

  void _finishRest() {
    _stopRest();

    // Two beeps signal that the next set is ready.
    BeepPlayer.playDouble();

    if (_currSet + 1 < _sets.length) {
      setState(() {
        _currSet++;
        _currTime = 0;
        _restDuration = 0;
        _status.value = WorkoutStatus.working;
      });
    } else {
      _completeWorkout();
    }
  }

  void _completeWorkout() {
    _stopRest();
    _sessionWatch.stop();
    _recordSession(completed: true);

    setState(() {
      _complete = true;
      _status.value = WorkoutStatus.complete;
    });
  }

  void _togglePause() {
    if (!_resting) return;

    if (_paused) {
      setState(() {
        _paused = false;
        _status.value = WorkoutStatus.resting;
      });
      _restWatch.start();
      _ticker.start();
      _startRestTimer();
    } else {
      _restTimer?.cancel();
      _restTimer = null;
      _restWatch.stop();
      _ticker.stop();
      setState(() {
        _paused = true;
        _status.value = WorkoutStatus.paused;
      });
    }
  }

  void _stopRest() {
    _restTimer?.cancel();
    _restTimer = null;
    _restWatch.stop();
    _ticker.stop();
    _resting = false;
    _paused = false;
    _currTime = 0;
    _restDuration = 0;
  }

  void _goToSet(int index) {
    if (index < 0 || index >= _sets.length) return;

    _stopRest();
    setState(() {
      _currSet = index;
      _complete = false;
      _status.value = WorkoutStatus.working;
    });
  }

  void _restart() {
    _stopRest();
    setState(() {
      _currSet = 0;
      _complete = false;
      _status.value = WorkoutStatus.working;
      _sessionStarted = false;
      _sessionRecorded = false;
      _sessionWatch
        ..stop()
        ..reset();
      _palette = _newPalette();
    });
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
    _restTimer?.cancel();
    _restWatch.stop();
    _sessionWatch.stop();
    _ticker.dispose();
    _status.dispose();
    super.dispose();
  }
}
