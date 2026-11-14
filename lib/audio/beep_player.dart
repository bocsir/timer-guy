// beep_player.dart

import 'beep_player_io.dart'
    if (dart.library.js_interop) 'beep_player_web.dart' as impl;

/// Plays short synthesised beep tones for the workout countdown.
///
/// No audio asset files are required; the tones are defined by [BeepTone].
///
/// The two platforms use different backends:
///  * web schedules oscillators on a single Web Audio `AudioContext`,
///  * native (Linux/Android/iOS/macOS/Windows) renders the tones to small WAV
///    files once and plays those through `audioplayers`.
class BeepPlayer {
  BeepPlayer._();

  /// Must be called once before any beep is played. Safe to call multiple times.
  static Future<void> init() => impl.BeepPlayer.init();

  /// Regular beep: played at 3, 2, 1 seconds remaining during rest.
  static void playNormal() => impl.BeepPlayer.playNormal();

  /// High beep: played at 0 s (rest over) and at the end of each working period.
  static void playHigh() => impl.BeepPlayer.playHigh();
}
