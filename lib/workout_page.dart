// workout_page.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'dart:async';
import 'package:proj/models/workout.dart';
import 'package:proj/models/workout_set.dart';
import 'package:proj/services/analytics_service.dart';
import 'package:proj/theme/theme.dart';
import 'package:progress_border/progress_border.dart';

enum WorkoutStatus { wasPaused, wasRunning, wasResting, wasGettingReady }

// Timer state class for robust state management
class TimerState {
  final WorkoutStatus status;
  final double timeRemaining;
  final int maxTime;
  final int currentSet;
  final int currentRep;
  final bool isWorkoutComplete;
  
  const TimerState({
    required this.status,
    required this.timeRemaining,
    required this.maxTime,
    required this.currentSet,
    required this.currentRep,
    this.isWorkoutComplete = false,
  });
  
  TimerState copyWith({
    WorkoutStatus? status,
    double? timeRemaining,
    int? maxTime,
    int? currentSet,
    int? currentRep,
    bool? isWorkoutComplete,
  }) {
    return TimerState(
      status: status ?? this.status,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      maxTime: maxTime ?? this.maxTime,
      currentSet: currentSet ?? this.currentSet,
      currentRep: currentRep ?? this.currentRep,
      isWorkoutComplete: isWorkoutComplete ?? this.isWorkoutComplete,
    );
  }
  
  bool get isRunning => status == WorkoutStatus.wasRunning || 
                        status == WorkoutStatus.wasResting || 
                        status == WorkoutStatus.wasGettingReady;
  
  bool get isPaused => status == WorkoutStatus.wasPaused;
}

class WorkoutPage extends StatefulWidget {
  final Workout workout;

  const WorkoutPage({super.key, required this.workout});

  @override
  WorkoutPageState createState() => WorkoutPageState();
}

class WorkoutPageState extends State<WorkoutPage>
    with TickerProviderStateMixin {
  // Core state
  late AnimationController _animationController;
  Timer? _timer;
  late TimerState _state;
  
  // Session tracking for analytics
  DateTime? _sessionStartTime;
  int _accumulatedSeconds = 0;
  bool _sessionRecorded = false;
  
  // Notifiers for UI reactivity
  late ValueNotifier<WorkoutStatus> status;
  late ValueNotifier<int> currRep;
  late ValueNotifier<int> currSet;
  late ValueNotifier<bool> workoutOver;
  
  // Computed properties
  WorkoutSet get _currentSet {
    if (_state.currentSet < 1 || _state.currentSet > widget.workout.sets.length) {
      return widget.workout.sets[0]; // Fallback
    }
    return widget.workout.sets[_state.currentSet - 1];
  }
  
  double get currTime => _state.timeRemaining;
  int get currentMaxTime => _state.maxTime;

  @override
  void initState() {
    super.initState();
    
    // Initialize state
    final firstSet = widget.workout.sets[0];
    _state = TimerState(
      status: WorkoutStatus.wasPaused,
      timeRemaining: firstSet.timeOn.toDouble(),
      maxTime: firstSet.timeOn,
      currentSet: 1,
      currentRep: 1,
      isWorkoutComplete: false,
    );
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: firstSet.timeOn),
    );
    _animationController.addListener(_onAnimationTick);

    // Initialize UI notifiers
    currRep = ValueNotifier(1);
    currSet = ValueNotifier(1);
    status = ValueNotifier(WorkoutStatus.wasPaused);
    workoutOver = ValueNotifier(false);
  }
  
  // Animation tick callback for UI updates
  void _onAnimationTick() {
    if (mounted) {
      setState(() {});
    }
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
                      final currentSet = _currentSet;
                      final isRunning = status.value == WorkoutStatus.wasRunning ||
                                       status.value == WorkoutStatus.wasResting ||
                                       status.value == WorkoutStatus.wasGettingReady;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentSet.name,
                            style: typography.lgSemibold,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isRunning
                                ? 'Set ${currSet.value} / ${widget.workout.sets.length} - Rep ${currRep.value} / ${currentSet.reps}'
                                : status.value == WorkoutStatus.wasResting
                                    ? 'Rest - Set ${currSet.value} / ${widget.workout.sets.length}'
                                    : status.value == WorkoutStatus.wasGettingReady
                                        ? 'Get Ready - Set ${currSet.value} / ${widget.workout.sets.length}'
                                        : 'Set ${currSet.value} / ${widget.workout.sets.length} - Rep ${currRep.value} / ${currentSet.reps}',
                            style: typography.base,
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          Expanded(
            child: SizedBox(
              width: double.infinity,
              child: ListenableBuilder(
                listenable: status,
                builder: (context, _) {
                  final progressColor = status.value == WorkoutStatus.wasPaused
                      ? Colors.grey
                      : status.value == WorkoutStatus.wasResting
                          ? Colors.blue
                          : status.value == WorkoutStatus.wasGettingReady
                              ? Colors.yellow
                              : Colors.green;
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            border: ProgressBorder.all(
                              color: progressColor,
                              progress: _animationController.value,
                              width: 6,
                              backgroundBorder: Border.all(
                                color: context.theme.colors.border,
                                width: 1,
                              ),
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
                              ? Text(
                                  'All done!',
                                  style: typography.xl3.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment:
                                      CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.values.first,
                                  spacing: 4,
                                  children: [
                                    Text(
                                      currTime.toString().split('.')[0],
                                      style: typography.xl7,
                                    ),
                                    Text(
                                      currTime.toString().split('.')[1][0],
                                      style: typography.xl5,
                                    ),
                                  ],
                                ),
                          Column(
                            children: [
                              // Rep navigation controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 16,
                                children: [
                                  FButton.icon(
                                    style: FButtonStyle.ghost(),
                                    onPress: _canGoPreviousPeriod() ? _previousPeriod : null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FIcons.chevronLeft, size: 20),
                                        Text('Period', style: typography.sm),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    status.value == WorkoutStatus.wasResting
                                        ? 'Rest'
                                        : status.value == WorkoutStatus.wasGettingReady
                                            ? 'Get Ready'
                                            : 'Work',
                                    style: typography.baseSemibold.copyWith(
                                      color: status.value == WorkoutStatus.wasPaused
                                          ? Colors.grey
                                          : null,
                                    ),
                                  ),
                                  FButton.icon(
                                    style: FButtonStyle.ghost(),
                                    onPress: _canGoNextPeriod() ? _nextPeriod : null,
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Period', style: typography.sm),
                                        Icon(FIcons.chevronRight, size: 20),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              // Time skip controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 16,
                                children: [
                                  FButton.icon(
                                    style: FButtonStyle.ghost(),
                                    onPress: () => _skipTime(5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(FIcons.chevronLeft, size: 16),
                                        Text('5s', style: typography.xs),
                                      ],
                                    ),
                                  ),
                                  FButton.icon(
                                    style: FButtonStyle.ghost(),
                                    onPress: () => _skipTime(-5),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('5s', style: typography.xs),
                                        Icon(FIcons.chevronRight, size: 16),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              // Main controls
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                spacing: 64,
                                children: [
                                  // RESTART
                                  FButton.icon(
                                    style: FButtonStyle.ghost(),
                                    onPress: restartWorkout,
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
                                      child: (status.value == WorkoutStatus.wasRunning ||
                                              status.value == WorkoutStatus.wasResting ||
                                              status.value == WorkoutStatus.wasGettingReady)
                                          ? // show pause
                                            FButton.icon(
                                              style: FButtonStyle.ghost(),
                                              onPress: pause,
                                              child: Icon(
                                                FIcons.pause,
                                                size: 30,
                                                color:
                                                    context.theme.colors.foreground,
                                              ),
                                            )
                                          : // show play
                                            FButton.icon(
                                              style: FButtonStyle.ghost(),
                                              onPress: _startTimerAndAnimation,
                                              child: Icon(
                                                FIcons.play,
                                                size: 30,
                                                color:
                                                    context.theme.colors.foreground,
                                              ),
                                            ),
                                    ),
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
                  );
                },
              ),
            ),
          ),
          //TODO: temporary
          SizedBox(height: 16),
        ],
      ),
    );
  }

  // ============================================================================
  // CORE TIMER & ANIMATION MANAGEMENT
  // ============================================================================
  
  /// Completely stops timer and animation, clears all running state
  void _stopAll() {
    _timer?.cancel();
    _timer = null;
    _animationController.stop();
  }
  
  /// Updates the internal state and syncs UI notifiers
  void _updateState(TimerState newState) {
    _state = newState;
    
    // Sync UI notifiers - ensure all are updated even if values appear the same
    // This forces listeners to rebuild
    status.value = newState.status;
    currRep.value = newState.currentRep;
    currSet.value = newState.currentSet;
    workoutOver.value = newState.isWorkoutComplete;
    
    // Force rebuild if mounted to ensure UI reflects state changes
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Sets up a new period with given parameters
  void _configurePeriod({
    required WorkoutStatus targetStatus,
    required int duration,
  }) {
    _stopAll();
    
    // Update state - preserve current set/rep counters
    _updateState(_state.copyWith(
      status: targetStatus,
      timeRemaining: duration.toDouble(),
      maxTime: duration,
      // Preserve currentSet and currentRep - don't reset them
    ));
    
    // Configure animation
    _animationController.reset();
    _animationController.duration = Duration(seconds: duration);
    _animationController.value = 0.0;
    
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Starts timer and animation from current state
  void _startTimerAndAnimation() {
    _stopAll(); // Ensure clean slate
    
    // Track session start time
    _sessionStartTime ??= DateTime.now();
    
    // Determine active status from paused state
    WorkoutStatus activeStatus = _state.status;
    if (_state.isPaused) {
      final currentSet = _currentSet;
      if (_state.maxTime == currentSet.timeOff) {
        activeStatus = WorkoutStatus.wasResting;
      } else if (_state.maxTime == 5 && currentSet.enableGetReady) {
        activeStatus = WorkoutStatus.wasGettingReady;
      } else {
        activeStatus = WorkoutStatus.wasRunning;
      }
      _updateState(_state.copyWith(status: activeStatus));
    }
    
    // Start animation
    final progress = 1.0 - (_state.timeRemaining / _state.maxTime);
    _animationController.value = progress.clamp(0.0, 1.0);
    _animationController.forward();
    
    // Start timer
    const tickInterval = Duration(milliseconds: 100);
    _timer = Timer.periodic(tickInterval, (Timer t) {
      // Defensive check
      if (!mounted || _timer == null || !_timer!.isActive) {
        return;
      }
      
      final newTime = _state.timeRemaining - (tickInterval.inMilliseconds / 1000);
      
      // Accumulate time
      _accumulatedSeconds += tickInterval.inMilliseconds ~/ 1000;
      
      if (newTime <= 0) {
        // Period complete
        _handlePeriodComplete();
      } else {
        // Update time
        _updateState(_state.copyWith(timeRemaining: newTime));
        
        // Ensure UI updates if animation stopped
        if (!_animationController.isAnimating && mounted) {
          setState(() {});
        }
      }
    });
  }
  
  /// Pauses the timer and animation
  void pause() {
    _stopAll();
    _updateState(_state.copyWith(status: WorkoutStatus.wasPaused));
    if (mounted) {
      setState(() {});
    }
  }

  // ============================================================================
  // PERIOD TRANSITION LOGIC
  // ============================================================================
  
  /// Handles period completion (auto-advance to next period)
  void _handlePeriodComplete() {
    _stopAll();
    
    final currentSet = _currentSet;
    final currentStatus = _state.status;
    
    if (currentStatus == WorkoutStatus.wasGettingReady) {
      // Get Ready -> Work (auto-start)
      _configurePeriod(
        targetStatus: WorkoutStatus.wasPaused,
        duration: currentSet.timeOn,
      );
      _startTimerAndAnimation();
    } else if (currentStatus == WorkoutStatus.wasResting) {
      // Rest -> Get Ready or Work (auto-start)
      if (currentSet.enableGetReady) {
        _configurePeriod(
          targetStatus: WorkoutStatus.wasPaused,
          duration: 5,
        );
        _startTimerAndAnimation();
      } else {
        _configurePeriod(
          targetStatus: WorkoutStatus.wasPaused,
          duration: currentSet.timeOn,
        );
        _startTimerAndAnimation();
      }
    } else {
      // Work -> Rest, advance rep/set
      if (_state.currentRep < currentSet.reps) {
        // Next rep in same set
        _updateState(_state.copyWith(currentRep: _state.currentRep + 1));
        _configurePeriod(
          targetStatus: WorkoutStatus.wasPaused,
          duration: currentSet.timeOff,
        );
        _startTimerAndAnimation();
      } else if (_state.currentSet < widget.workout.sets.length) {
        // Next set - pause at boundary
        _updateState(_state.copyWith(
          currentSet: _state.currentSet + 1,
          currentRep: 1,
        ));
        final nextSet = _currentSet;
        _configurePeriod(
          targetStatus: WorkoutStatus.wasPaused,
          duration: nextSet.timeOff,
        );
      } else {
        // Workout complete
        _updateState(_state.copyWith(
          status: WorkoutStatus.wasPaused,
          isWorkoutComplete: true,
        ));
        _recordSession(completed: true);
        if (mounted) {
          setState(() {});
        }
      }
    }
  }
  
  /// Record the workout session to analytics
  void _recordSession({required bool completed}) {
    if (_sessionRecorded) return;
    if (_sessionStartTime == null) return;
    
    // Calculate total duration
    final totalSeconds = _accumulatedSeconds > 0 
        ? _accumulatedSeconds 
        : DateTime.now().difference(_sessionStartTime!).inSeconds;
    
    if (totalSeconds > 0) {
      AnalyticsService.instance.recordSession(
        workoutKey: widget.workout.key as int,
        durationSeconds: totalSeconds,
        completed: completed,
      );
      _sessionRecorded = true;
    }
  }
  
  /// Handles skip-to-end of period (pause after transition)
  void _skipToNextPeriod() {
    _stopAll();
    
    final currentSet = _currentSet;
    final currentStatus = _state.status;
    
    if (currentStatus == WorkoutStatus.wasGettingReady) {
      _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: currentSet.timeOn);
    } else if (currentStatus == WorkoutStatus.wasResting) {
      if (currentSet.enableGetReady) {
        _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: 5);
      } else {
        _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: currentSet.timeOn);
      }
    } else {
      // Work complete, advance counters atomically
      int newRep = _state.currentRep;
      int newSet = _state.currentSet;
      bool isComplete = false;
      
      if (_state.currentRep < currentSet.reps) {
        newRep = _state.currentRep + 1;
      } else if (_state.currentSet < widget.workout.sets.length) {
        newSet = _state.currentSet + 1;
        newRep = 1;
      } else {
        isComplete = true;
      }
      
      // Update state before getting next set
      if (isComplete) {
        _updateState(_state.copyWith(isWorkoutComplete: true));
      } else {
        _updateState(_state.copyWith(
          currentSet: newSet,
          currentRep: newRep,
        ));
        final nextSet = _currentSet;
        _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: nextSet.timeOff);
      }
    }
  }
  
  // ============================================================================
  // NAVIGATION HELPERS
  // ============================================================================
  
  bool _canGoPreviousPeriod() {
    if (_state.isWorkoutComplete) return false;
    
    // Determine current period type
    WorkoutStatus currentPeriod = _state.status;
    if (_state.isPaused) {
      final set = _currentSet;
      if (_state.maxTime == set.timeOff) {
        currentPeriod = WorkoutStatus.wasResting;
      } else if (_state.maxTime == 5 && set.enableGetReady) {
        currentPeriod = WorkoutStatus.wasGettingReady;
      } else {
        currentPeriod = WorkoutStatus.wasRunning;
      }
    }
    
    // Can't go back from first work period
    return !(currentPeriod == WorkoutStatus.wasRunning && 
             _state.currentSet == 1 && _state.currentRep == 1);
  }

  bool _canGoNextPeriod() {
    if (_state.isWorkoutComplete) return false;
    
    // Determine current period type
    WorkoutStatus currentPeriod = _state.status;
    if (_state.isPaused) {
      final set = _currentSet;
      if (_state.maxTime == set.timeOff) {
        currentPeriod = WorkoutStatus.wasResting;
      } else if (_state.maxTime == 5 && set.enableGetReady) {
        currentPeriod = WorkoutStatus.wasGettingReady;
      } else {
        currentPeriod = WorkoutStatus.wasRunning;
      }
    }
    
    final currentSet = _currentSet;
    // Can't go forward from last rest of last set
    return !(currentPeriod == WorkoutStatus.wasResting && 
             _state.currentSet == widget.workout.sets.length && 
             _state.currentRep >= currentSet.reps);
  }

  // ============================================================================
  // USER ACTIONS (Skip, Navigate)
  // ============================================================================
  
  /// Skip time within current period (5 seconds forward/backward)
  void _skipTime(int secondsDelta) {
    if (_state.isWorkoutComplete) return;
    
    final newTime = (_state.timeRemaining + secondsDelta).clamp(0.0, _state.maxTime.toDouble());
    
    // If skipping forward to 0, jump to next period (paused)
    if (secondsDelta < 0 && newTime <= 0.0) {
      _skipToNextPeriod();
      return;
    }
    
    // Update time and pause
    _stopAll();
    _updateState(_state.copyWith(
      timeRemaining: newTime,
      status: WorkoutStatus.wasPaused,
    ));
    
    // Update animation
    final progress = 1.0 - (newTime / _state.maxTime);
    _animationController.value = progress.clamp(0.0, 1.0);
    
    if (mounted) {
      setState(() {});
    }
  }
  
  /// Navigate to previous period
  void _previousPeriod() {
    if (!_canGoPreviousPeriod()) return;
    
    _stopAll();
    final currentSet = _currentSet;
    
    // Determine current period type
    WorkoutStatus currentPeriod = _state.status;
    if (_state.isPaused) {
      if (_state.maxTime == currentSet.timeOff) {
        currentPeriod = WorkoutStatus.wasResting;
      } else if (_state.maxTime == 5 && currentSet.enableGetReady) {
        currentPeriod = WorkoutStatus.wasGettingReady;
      } else {
        currentPeriod = WorkoutStatus.wasRunning;
      }
    }
    
    // Navigate backward
    if (currentPeriod == WorkoutStatus.wasRunning) {
      // Work -> previous rep's rest
      int newRep = _state.currentRep;
      int newSet = _state.currentSet;
      
      if (_state.currentRep > 1) {
        newRep = _state.currentRep - 1;
      } else if (_state.currentSet > 1) {
        newSet = _state.currentSet - 1;
        final prevSet = widget.workout.sets[newSet - 1];
        newRep = prevSet.reps;
      } else {
        return;
      }
      
      // Update state atomically - update set/rep first
      _updateState(_state.copyWith(
        currentSet: newSet,
        currentRep: newRep,
        status: WorkoutStatus.wasPaused,
        timeRemaining: _currentSet.timeOff.toDouble(),
        maxTime: _currentSet.timeOff,
      ));
      // Configure animation after state update
      _animationController.reset();
      _animationController.duration = Duration(seconds: _currentSet.timeOff);
      _animationController.value = 0.0;
      if (mounted) {
        setState(() {});
      }
    } else if (currentPeriod == WorkoutStatus.wasGettingReady) {
      // Get Ready -> rest
      _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: currentSet.timeOff);
    } else {
      // Rest -> work (same rep)
      _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: currentSet.timeOn);
    }
  }

  /// Navigate to next period
  void _nextPeriod() {
    if (!_canGoNextPeriod()) return;
    
    _stopAll();
    final currentSet = _currentSet;
    
    // Determine current period type
    WorkoutStatus currentPeriod = _state.status;
    if (_state.isPaused) {
      if (_state.maxTime == currentSet.timeOff) {
        currentPeriod = WorkoutStatus.wasResting;
      } else if (_state.maxTime == 5 && currentSet.enableGetReady) {
        currentPeriod = WorkoutStatus.wasGettingReady;
      } else {
        currentPeriod = WorkoutStatus.wasRunning;
      }
    }
    
    // Navigate forward
    if (currentPeriod == WorkoutStatus.wasRunning) {
      // Work -> rest
      _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: currentSet.timeOff);
    } else if (currentPeriod == WorkoutStatus.wasResting) {
      // Rest -> get ready or next work
      if (currentSet.enableGetReady) {
        _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: 5);
      } else {
        // Advance counters atomically
        int newRep = _state.currentRep;
        int newSet = _state.currentSet;
        
        if (_state.currentRep < currentSet.reps) {
          newRep = _state.currentRep + 1;
        } else if (_state.currentSet < widget.workout.sets.length) {
          newSet = _state.currentSet + 1;
          newRep = 1;
        } else {
          return;
        }
        
        // Update state atomically - update set/rep first, then configure period
        _updateState(_state.copyWith(
          currentSet: newSet,
          currentRep: newRep,
          status: WorkoutStatus.wasPaused,
          timeRemaining: _currentSet.timeOn.toDouble(),
          maxTime: _currentSet.timeOn,
        ));
        // Configure animation after state update
        _animationController.reset();
        _animationController.duration = Duration(seconds: _currentSet.timeOn);
        _animationController.value = 0.0;
        if (mounted) {
          setState(() {});
        }
      }
    } else {
      // Get Ready -> work
      _configurePeriod(targetStatus: WorkoutStatus.wasPaused, duration: currentSet.timeOn);
    }
  }
  
  /// Restart the entire workout
  void restartWorkout() {
    final firstSet = widget.workout.sets[0];
    _stopAll();
    _updateState(TimerState(
      status: WorkoutStatus.wasPaused,
      timeRemaining: firstSet.timeOn.toDouble(),
      maxTime: firstSet.timeOn,
      currentSet: 1,
      currentRep: 1,
      isWorkoutComplete: false,
    ));
    _animationController.reset();
    _animationController.duration = Duration(seconds: firstSet.timeOn);
    _animationController.value = 0.0;
    if (mounted) {
      setState(() {});
    }
  }


  // ============================================================================
  // LIFECYCLE
  // ============================================================================
  
  @override
  void dispose() {
    // Record partial session if user exits early
    if (!_sessionRecorded && _sessionStartTime != null && _accumulatedSeconds > 0) {
      _recordSession(completed: false);
    }
    
    _stopAll();
    _animationController.removeListener(_onAnimationTick);
    _animationController.dispose();
    currRep.dispose();
    currSet.dispose();
    status.dispose();
    workoutOver.dispose();
    super.dispose();
  }
}
