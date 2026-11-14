// beep_player_io.dart

import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:io' show File;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:path_provider/path_provider.dart';
import 'package:timer_guy/audio/beep_tone.dart';

/// Native implementation: the tones are built as raw PCM WAV bytes at startup,
/// written to temp files and replayed through `audioplayers`
/// ([DeviceFileSource] is required by the GStreamer backend on Linux).
class BeepPlayer {
  BeepPlayer._();

  static AudioPlayer? _normalPlayer;
  static AudioPlayer? _highPlayer;

  static Source? _normalSource;
  static Source? _highSource;

  static final Uint8List _normalBytes = _buildWav(BeepTone.normal);
  static final Uint8List _highBytes = _buildWav(BeepTone.high);

  static bool _initialised = false;

  static Future<void> init() async {
    if (_initialised) return;
    _initialised = true;

    final dir = await getTemporaryDirectory();
    final normalFile = File('${dir.path}/beep_normal.wav');
    final highFile = File('${dir.path}/beep_high.wav');
    await normalFile.writeAsBytes(_normalBytes, flush: true);
    await highFile.writeAsBytes(_highBytes, flush: true);

    _normalSource = DeviceFileSource(normalFile.path);
    _highSource = DeviceFileSource(highFile.path);

    _normalPlayer = AudioPlayer();
    _highPlayer = AudioPlayer();
  }

  // One outstanding call per player. Requests are serialised so that two beeps
  // fired close together (e.g. a zero-length rest triggers the transition beep
  // twice within ~100 ms) don't overwrite each other's source and get dropped.
  static Future<void> _normalQueue = Future.value();
  static Future<void> _highQueue = Future.value();

  static void playNormal() {
    _normalQueue = _play(_normalQueue, _normalPlayer, _normalSource);
  }

  static void playHigh() {
    _highQueue = _play(_highQueue, _highPlayer, _highSource);
  }

  static Future<void> _play(
    Future<void> previous,
    AudioPlayer? player,
    Source? source,
  ) async {
    if (player == null || source == null) return;

    await previous;

    try {
      await player.play(source);
    } catch (error) {
      debugPrint('BeepPlayer: failed to play beep: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // WAV generation
  // ---------------------------------------------------------------------------

  static Uint8List _buildWav(BeepTone tone) {
    const int sampleRate = 8000;
    const double amplitude = 0.7;
    const int fadeSamples = 80;

    final int numSamples = (sampleRate * tone.durationMs / 1000).round();
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
      double s =
          math.sin(2 * math.pi * tone.frequency * i / sampleRate) * amplitude;
      if (i < fadeSamples) {
        s *= i / fadeSamples;
      } else if (i > numSamples - fadeSamples) {
        s *= (numSamples - i) / fadeSamples;
      }
      bd.setInt16(
        44 + i * 2,
        (s * 32767).round().clamp(-32768, 32767),
        Endian.little,
      );
    }

    return bd.buffer.asUint8List();
  }

  static void _ascii(ByteData bd, int offset, String s) {
    for (int i = 0; i < s.length; i++) {
      bd.setUint8(offset + i, s.codeUnitAt(i));
    }
  }
}
