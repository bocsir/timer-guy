// beep_player.dart
import 'dart:async' show unawaited;
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Generates and plays short synthesised beep tones for the workout countdown.
/// No audio asset files required — tones are built as raw PCM WAV bytes at
/// startup and reused for every play call.
///
/// On web: plays via [BytesSource] (in-memory).
/// On native (Linux/Android/iOS/macOS/Windows): writes the WAV to a temp file
/// once and plays via [DeviceFileSource] (required by the GStreamer backend).
class BeepPlayer {
  BeepPlayer._();

  static AudioPlayer? _normalPlayer;
  static AudioPlayer? _highPlayer;

  static Source? _normalSource;
  static Source? _highSource;

  // 660 Hz, 120 ms  — regular countdown tick
  static final Uint8List _normalBytes = _buildWav(frequency: 660, durationMs: 120);
  // 880 Hz, 200 ms  — transition beep (end of work / end of rest)
  static final Uint8List _highBytes = _buildWav(frequency: 880, durationMs: 200);

  static bool _initialised = false;

  /// Must be called once before any beep is played. Safe to call multiple times.
  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    if (kIsWeb) {
      _normalSource = BytesSource(_normalBytes);
      _highSource = BytesSource(_highBytes);
    } else {
      final dir = await getTemporaryDirectory();
      final normalFile = File('${dir.path}/beep_normal.wav');
      final highFile = File('${dir.path}/beep_high.wav');
      await normalFile.writeAsBytes(_normalBytes, flush: true);
      await highFile.writeAsBytes(_highBytes, flush: true);
      _normalSource = DeviceFileSource(normalFile.path);
      _highSource = DeviceFileSource(highFile.path);
    }

    _normalPlayer = AudioPlayer();
    _highPlayer = AudioPlayer();
  }

  /// Regular beep: played at 3, 2, 1 seconds remaining during rest.
  static void playNormal() {
    final src = _normalSource;
    final player = _normalPlayer;
    if (src == null || player == null) return;
    unawaited(player.play(src));
  }

  /// High beep: played at 0 s (rest over) and at the end of each working period.
  static void playHigh() {
    final src = _highSource;
    final player = _highPlayer;
    if (src == null || player == null) return;
    unawaited(player.play(src));
  }

  // ---------------------------------------------------------------------------
  // WAV generation
  // ---------------------------------------------------------------------------

  static Uint8List _buildWav({required double frequency, required int durationMs}) {
    const int sampleRate = 8000;
    const double amplitude = 0.7;
    const int fadeSamples = 80;

    final int numSamples = (sampleRate * durationMs / 1000).round();
    final int dataSize = numSamples * 2;
    final bd = ByteData(44 + dataSize);

    _ascii(bd, 0, 'RIFF');
    bd.setUint32(4, 36 + dataSize, Endian.little);
    _ascii(bd, 8, 'WAVE');
    _ascii(bd, 12, 'fmt ');
    bd.setUint32(16, 16, Endian.little);
    bd.setUint16(20, 1, Endian.little);
    bd.setUint16(22, 1, Endian.little);
    bd.setUint32(24, sampleRate, Endian.little);
    bd.setUint32(28, sampleRate * 2, Endian.little);
    bd.setUint16(32, 2, Endian.little);
    bd.setUint16(34, 16, Endian.little);
    _ascii(bd, 36, 'data');
    bd.setUint32(40, dataSize, Endian.little);

    for (int i = 0; i < numSamples; i++) {
      double s = math.sin(2 * math.pi * frequency * i / sampleRate) * amplitude;
      if (i < fadeSamples) {
        s *= i / fadeSamples;
      } else if (i > numSamples - fadeSamples) {
        s *= (numSamples - i) / fadeSamples;
      }
      bd.setInt16(44 + i * 2, (s * 32767).round().clamp(-32768, 32767), Endian.little);
    }

    return bd.buffer.asUint8List();
  }

  static void _ascii(ByteData bd, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      bd.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
