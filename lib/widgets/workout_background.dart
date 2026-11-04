// widgets/workout_background.dart
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/settings.dart';
import 'package:timer_guy/workout_status.dart';

/// A group of colors generated for a single workout run.
///
/// Every palette starts from one random hue and adds colors using a random
/// harmony pattern. That keeps the result surprising but still cohesive,
/// instead of looking like a handful of unrelated crayons.
class WorkoutPalette {
  const WorkoutPalette(this.colors);

  final List<Color> colors;

  factory WorkoutPalette.random({required bool isDark, math.Random? random}) {
    final rng = random ?? math.Random();
    final baseHue = rng.nextDouble() * 360;

    // Offsets in degrees from the base hue.
    final offsets = switch (rng.nextInt(4)) {
      0 => const [0.0, 24.0, 48.0, 72.0, 96.0], // analogous
      1 => const [0.0, 150.0, 180.0, 210.0, 330.0], // split complementary
      2 => const [0.0, 120.0, 240.0, 60.0, 300.0], // triadic
      _ => const [0.0, 40.0, 190.0, 220.0, 320.0], // warm + cool clash
    };

    final colors = <Color>[];
    for (final offset in offsets) {
      final hue = (baseHue + offset + rng.nextDouble() * 18 - 9) % 360;
      final saturation = isDark
          ? 0.68 + rng.nextDouble() * 0.27
          : 0.8 + rng.nextDouble() * 0.2;
      final lightness = isDark
          ? 0.48 + rng.nextDouble() * 0.2
          : 0.42 + rng.nextDouble() * 0.14;
      colors.add(HSLColor.fromAHSL(1, hue, saturation, lightness).toColor());
    }

    return WorkoutPalette(List.unmodifiable(colors));
  }
}

/// Places [WorkoutBackground] behind [child] when the user has the animated
/// background enabled. Toggling the setting rebuilds this frame, which removes
/// the background and stops its ticker.
class WorkoutBackgroundFrame extends StatelessWidget {
  const WorkoutBackgroundFrame({
    super.key,
    required this.palette,
    required this.status,
    required this.progress,
    required this.child,
  });

  final WorkoutPalette palette;
  final ValueListenable<WorkoutStatus> status;
  final double progress;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;

    return ValueListenableBuilder<bool>(
      valueListenable: animatedBackgroundEnabled,
      builder: (context, enabled, _) => Stack(
        fit: StackFit.expand,
        children: [
          if (enabled)
            WorkoutBackground(
              palette: palette,
              status: status,
              progress: progress,
              background: colors.background,
              isDark: colors.brightness == Brightness.dark,
            ),
          child,
        ],
      ),
    );
  }
}

/// Soft, blurred color blobs that live behind the workout UI.
///
/// The blobs drift constantly, but their speed, size and brightness are driven
/// by the current [WorkoutStatus]:
///
/// * working blobs get fast, bright and swell with the phase's progress,
/// * resting blobs calm down and slowly shrink back,
/// * pausing nearly freezes them,
/// * finishing fires a short burst.
class WorkoutBackground extends StatefulWidget {
  const WorkoutBackground({
    super.key,
    required this.palette,
    required this.status,
    required this.progress,
    required this.background,
    required this.isDark,
  });

  final WorkoutPalette palette;
  final ValueListenable<WorkoutStatus> status;

  /// Progress of the current phase, 0..1. Used to make the blobs breathe in
  /// sync with the workout instead of just looping on their own.
  final double progress;

  final Color background;
  final bool isDark;

  @override
  State<WorkoutBackground> createState() => _WorkoutBackgroundState();
}

class _WorkoutBackgroundState extends State<WorkoutBackground>
    with SingleTickerProviderStateMixin {
  late final Ticker _ticker;

  Duration _lastElapsed = Duration.zero;
  double _time = 0;
  double _speed = 0.25;
  double _energy = 0.4;
  double _burst = 0;

  @override
  void initState() {
    super.initState();
    widget.status.addListener(_handleStatusChange);
    _ticker = createTicker(_tick)..start();
  }

  @override
  void didUpdateWidget(covariant WorkoutBackground oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) {
      oldWidget.status.removeListener(_handleStatusChange);
      widget.status.addListener(_handleStatusChange);
    }
  }

  void _handleStatusChange() {
    switch (widget.status.value) {
      case WorkoutStatus.working:
        _burst = math.max(_burst, 0.6);
      case WorkoutStatus.resting:
        _burst = math.max(_burst, 0.25);
      case WorkoutStatus.complete:
        _burst = 1;
      case WorkoutStatus.notStarted:
      case WorkoutStatus.preparing:
      case WorkoutStatus.paused:
        break;
    }
  }

  void _tick(Duration elapsed) {
    final dt =
        (elapsed - _lastElapsed).inMicroseconds /
        Duration.microsecondsPerSecond;
    _lastElapsed = elapsed;
    if (dt <= 0) return;

    // Clamp so returning from a paused route doesn't teleport the blobs.
    final step = math.min(dt, 0.05);

    final (targetSpeed, targetEnergy) = switch (widget.status.value) {
      WorkoutStatus.working => (1.9, 1.0),
      WorkoutStatus.resting => (0.42, 0.42),
      WorkoutStatus.preparing => (0.7, 0.6),
      WorkoutStatus.paused => (0.05, 0.3),
      WorkoutStatus.complete => (1.2, 0.9),
      WorkoutStatus.notStarted => (0.22, 0.42),
    };

    // Ease towards the target so phase changes glide instead of snapping.
    final ease = 1 - math.exp(-step * 3.2);
    _speed += (targetSpeed - _speed) * ease;
    _energy += (targetEnergy - _energy) * ease;
    _burst *= math.exp(-step * 2.2);
    _time += step * _speed;

    setState(() {});
  }

  @override
  void dispose() {
    widget.status.removeListener(_handleStatusChange);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        painter: _BlobPainter(
          colors: widget.palette.colors,
          background: widget.background,
          isDark: widget.isDark,
          time: _time,
          energy: _energy,
          burst: _burst,
          progress: widget.progress,
          phase: widget.status.value,
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  _BlobPainter({
    required this.colors,
    required this.background,
    required this.isDark,
    required this.time,
    required this.energy,
    required this.burst,
    required this.progress,
    required this.phase,
  });

  final List<Color> colors;
  final Color background;
  final bool isDark;
  final double time;
  final double energy;
  final double burst;
  final double progress;
  final WorkoutStatus phase;

  /// Anchors are kept near the edges (plus one soft glow in the middle) so the
  /// timer and controls stay readable.
  static const _anchors = <Offset>[
    Offset(0.1, 0.16),
    Offset(0.9, 0.1),
    Offset(0.06, 0.82),
    Offset(0.94, 0.78),
    Offset(0.5, 0.5),
  ];

  /// The middle blob is intentionally dimmer; it acts as a halo behind the
  /// timer rather than competing with the text.
  static const _alphaScales = <double>[1.0, 0.9, 0.85, 0.95, 0.55];

  @override
  void paint(Canvas canvas, Size size) {
    final shortest = size.shortestSide;

    // The blobs use a screen blend in dark mode, so they need a base to blend
    // against. In light mode normal alpha keeps the pastel colors soft.
    canvas.drawRect(Offset.zero & size, Paint()..color = background);

    final blend = isDark ? BlendMode.screen : BlendMode.srcOver;
    final baseAlpha = isDark ? 0.46 : 0.55;

    final phaseGrow = switch (phase) {
      // Working progress runs 0 -> 1, so the colors swell as the set goes on.
      WorkoutStatus.working => 1 + 0.38 * progress,
      // Resting progress runs 1 -> 0, so the colors settle as rest finishes.
      WorkoutStatus.resting => 1.05 - 0.25 * progress,
      WorkoutStatus.preparing => 0.9 + 0.12 * progress,
      WorkoutStatus.complete => 1.15,
      WorkoutStatus.paused => 0.9,
      WorkoutStatus.notStarted => 1,
    };

    for (var i = 0; i < _anchors.length; i++) {
      final anchor = _anchors[i];
      final color = _animatedColor(i);

      final wobble = shortest * (0.055 + 0.075 * energy);
      final center = Offset(
        anchor.dx * size.width +
            math.sin(time * (0.42 + i * 0.09) + i * 1.7) * wobble,
        anchor.dy * size.height +
            math.cos(time * (0.37 + i * 0.07) + i * 2.1) * wobble,
      );

      final radius =
          shortest *
          (0.22 + 0.055 * (i % 3)) *
          (0.75 + 0.5 * energy) *
          phaseGrow *
          (1 + 0.18 * math.sin(time * (0.7 + i * 0.11) + i)) *
          (1 + 0.45 * burst);

      final alpha =
          (baseAlpha *
                  _alphaScales[i] *
                  (0.5 + 0.5 * energy) *
                  (0.88 + 0.12 * math.sin(time * 0.9 + i * 1.3)) *
                  (1 + 0.5 * burst))
              .clamp(0.0, 1.0);

      final sigma = math.max(
        8.0,
        math.min(120.0, shortest * 0.07 * (0.8 + 0.4 * energy)),
      );

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..blendMode = blend
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma);

      canvas.drawCircle(center, radius, paint);
    }

    // A quick wash of the first palette color when a phase starts or the
    // workout finishes.
    if (burst > 0.01) {
      final flash = Paint()
        ..color = colors.first.withValues(alpha: 0.09 * burst)
        ..blendMode = blend;
      canvas.drawRect(Offset.zero & size, flash);
    }
  }

  Color _animatedColor(int index) {
    final a = colors[index % colors.length];
    final b = colors[(index + 1) % colors.length];

    // Slowly cross-fade between neighboring palette colors...
    final t = 0.5 + 0.5 * math.sin(time * 0.3 + index * 1.9);
    final blended = Color.lerp(a, b, t)!;

    // ...and rotate the hue a little with the phase so the whole scene shifts
    // as the workout moves from work to rest and back.
    final hsl = HSLColor.fromColor(blended);
    final hue = (hsl.hue + progress * 18 + time * 2) % 360;
    return hsl.withHue(hue).toColor();
  }

  @override
  bool shouldRepaint(covariant _BlobPainter oldDelegate) {
    return oldDelegate.time != time ||
        oldDelegate.energy != energy ||
        oldDelegate.burst != burst ||
        oldDelegate.progress != progress ||
        oldDelegate.phase != phase ||
        oldDelegate.background != background ||
        oldDelegate.isDark != isDark ||
        oldDelegate.colors != colors;
  }
}
