// beep_tone.dart

/// Acoustic definition of a countdown beep.
///
/// The tones themselves are synthesised at runtime, so both platform
/// implementations (native and web) only need these numbers to stay in sync.
class BeepTone {
  const BeepTone({required this.frequency, required this.durationMs});

  /// Pitch in Hz.
  final double frequency;

  /// Total length of the tone in milliseconds.
  final int durationMs;

  /// Regular countdown tick, played at 3, 2 and 1 seconds remaining.
  static const BeepTone normal = BeepTone(frequency: 660, durationMs: 120);

  /// Transition beep, played when a phase ends (rest over / work over).
  static const BeepTone high = BeepTone(frequency: 880, durationMs: 200);
}
