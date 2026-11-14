// beep_player_web.dart

import 'dart:async' show unawaited;
import 'dart:js_interop';

import 'package:timer_guy/audio/beep_tone.dart';
import 'package:web/web.dart' as web;

/// Web implementation built directly on the Web Audio API.
///
/// The previous approach pushed WAV blobs through an `<audio>` element via
/// `audioplayers`. On mobile browsers that is unreliable for short one-shot
/// sounds: every play replaced the element source with a freshly created blob
/// URL, and a `play()` racing that load (or routed through an `AudioContext`
/// that the browser had not unlocked) is dropped silently. An oscillator can
/// be scheduled on an already running context at any time, so the transition
/// beep no longer gets lost.
class BeepPlayer {
  BeepPlayer._();

  /// Peak gain of a beep, matching the previous WAV amplitude.
  static const double _volume = 0.7;

  static web.AudioContext? _context;
  static bool _listening = false;

  static Future<void> init() async {
    _ensureContext();
  }

  static void playNormal() => _play(BeepTone.normal);

  static void playHigh() => _play(BeepTone.high);

  static void playDouble() {
    final context = _ensureContext();
    unawaited(_unlock(context));

    final now = context.currentTime;
    _schedule(context, BeepTone.high, now);
    _schedule(context, BeepTone.high, now + 0.35);
  }

  static web.AudioContext _ensureContext() {
    final existing = _context;
    if (existing != null) return existing;

    final context = web.AudioContext();
    _context = context;

    if (!_listening) {
      _listening = true;
      // Browsers keep a context suspended until it has been resumed from a
      // user gesture, so grab the first interaction anywhere in the app.
      web.document.addEventListener('pointerdown', _unlockFromGesture.toJS);
      web.document.addEventListener('keydown', _unlockFromGesture.toJS);
    }

    return context;
  }

  static void _unlockFromGesture(web.Event _) {
    final context = _context;
    if (context != null) unawaited(_unlock(context));
  }

  static Future<void> _unlock(web.AudioContext context) async {
    if (context.state == 'running') return;
    try {
      await context.resume().toDart;
    } catch (_) {
      // Still blocked by the autoplay policy; the next gesture retries.
    }
  }

  static void _play(BeepTone tone) {
    final context = _ensureContext();
    unawaited(_unlock(context));

    _schedule(context, tone, context.currentTime);
  }

  static void _schedule(web.AudioContext context, BeepTone tone, double start) {
    final duration = tone.durationMs / 1000;
    // Short fades so the tone doesn't click when it starts or stops.
    final fade = duration < 0.05 ? duration / 4 : 0.01;

    final oscillator = context.createOscillator();
    oscillator.type = 'sine';
    oscillator.frequency.value = tone.frequency;

    final gain = context.createGain();
    gain.gain
      ..setValueAtTime(0, start)
      ..linearRampToValueAtTime(_volume, start + fade)
      ..setValueAtTime(_volume, start + duration - fade)
      ..linearRampToValueAtTime(0, start + duration);

    oscillator.connect(gain);
    gain.connect(context.destination);

    oscillator.onended = ((web.Event _) {
      oscillator.disconnect();
      gain.disconnect();
    }).toJS;

    oscillator.start(start);
    oscillator.stop(start + duration);
  }
}
