// services/workout_file_drop.dart
import 'package:timer_guy/services/workout_file_drop_stub.dart'
    if (dart.library.js_interop) 'package:timer_guy/services/workout_file_drop_web.dart'
    as impl;
import 'package:timer_guy/services/workout_file_drop_types.dart';

export 'package:timer_guy/services/workout_file_drop_types.dart';

/// Whether files can be dropped from the operating system into the browser.
bool get workoutFileDropSupported => impl.workoutFileDropSupported;

/// Listens for files dropped anywhere in the browser window.
///
/// [onFile] is called with each dropped file. The returned subscription must be
/// cancelled when drops should no longer be accepted.
WorkoutFileDropSubscription listenForDroppedWorkoutFiles(
  void Function(DroppedWorkoutFile file) onFile,
) => impl.listenForDroppedWorkoutFiles(onFile);
