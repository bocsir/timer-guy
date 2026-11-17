// services/workout_file_drop_web.dart
import 'dart:async';
import 'dart:js_interop';

import 'package:timer_guy/services/workout_file_drop_types.dart';
import 'package:web/web.dart' as web;

/// Browsers can receive files dragged from the operating system.
bool get workoutFileDropSupported => true;

/// Listens for files dropped anywhere in the browser window.
WorkoutFileDropSubscription listenForDroppedWorkoutFiles(
  void Function(DroppedWorkoutFile file) onFile,
) {
  final subscription = _WebDropSubscription(onFile);
  subscription.start();
  return subscription;
}

class _WebDropSubscription implements WorkoutFileDropSubscription {
  _WebDropSubscription(this._onFile);

  final void Function(DroppedWorkoutFile file) _onFile;

  late final JSFunction _dragOver = _preventDefault.toJS;
  late final JSFunction _drop = _handleDrop.toJS;

  bool _cancelled = false;

  void start() {
    web.document.addEventListener('dragover', _dragOver);
    web.document.addEventListener('drop', _drop);
  }

  void _preventDefault(web.Event event) => event.preventDefault();

  void _handleDrop(web.Event event) {
    event.preventDefault();

    final data = (event as web.DragEvent).dataTransfer;
    final files = data?.files;
    if (files == null || files.length == 0) return;

    final file = files.item(0);
    if (file == null) return;

    unawaited(_readFile(file));
  }

  Future<void> _readFile(web.File file) async {
    final buffer = await file.arrayBuffer().toDart;
    if (_cancelled) return;

    _onFile(
      DroppedWorkoutFile(name: file.name, bytes: buffer.toDart.asUint8List()),
    );
  }

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    web.document.removeEventListener('dragover', _dragOver);
    web.document.removeEventListener('drop', _drop);
  }
}
