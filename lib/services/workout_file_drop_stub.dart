// services/workout_file_drop_stub.dart
import 'package:timer_guy/services/workout_file_drop_types.dart';

/// Native platforms cannot receive files dropped into a browser window.
bool get workoutFileDropSupported => false;

/// No-op implementation for native platforms.
WorkoutFileDropSubscription listenForDroppedWorkoutFiles(
  void Function(DroppedWorkoutFile file) onFile,
) => _NoopDropSubscription();

class _NoopDropSubscription implements WorkoutFileDropSubscription {
  @override
  void cancel() {}
}
