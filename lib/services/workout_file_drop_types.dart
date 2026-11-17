// services/workout_file_drop_types.dart
import 'dart:typed_data';

/// A file dropped from the operating system into the browser window.
class DroppedWorkoutFile {
  const DroppedWorkoutFile({required this.name, required this.bytes});

  /// The original file name, including its extension.
  final String name;

  /// The file's contents.
  final Uint8List bytes;
}

/// A listener for files dropped into the browser window.
///
/// Cancel it to stop accepting drops, for example when a dialog closes.
abstract interface class WorkoutFileDropSubscription {
  void cancel();
}
