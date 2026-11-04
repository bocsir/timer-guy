// settings.dart
import 'package:flutter/foundation.dart';

/// Whether the randomly colored, animated workout background is shown.
///
/// Persisted in the Hive settings box (see [animatedBackgroundKey]).
final ValueNotifier<bool> animatedBackgroundEnabled = ValueNotifier(true);
