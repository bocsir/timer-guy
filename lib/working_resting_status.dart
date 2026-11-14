// working_resting_status.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/models/exercise.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/workout_status.dart';

class WorkingRestingStatus extends StatelessWidget {
  final WorkoutStatus status;
  final Exercise exercise;

  const WorkingRestingStatus({
    super.key,
    required this.status,
    required this.exercise,
  });

  @override
  Widget build(BuildContext context) {
    final workingDetail = exercise.isReps
        ? '${exercise.reps} reps'
        : _formatDuration(exercise.timeOn);

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatus(
            context,
            label: 'Working',
            detail: workingDetail,
            active: status == WorkoutStatus.working,
          ),
          _buildStatus(
            context,
            label: 'Resting',
            detail: _formatDuration(exercise.timeOff),
            active: status == WorkoutStatus.resting,
          ),
        ],
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    if (minutes == 0) return '${remainingSeconds}s';
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildStatus(
    BuildContext context, {
    required String label,
    required String detail,
    required bool active,
  }) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final color = active ? colors.accent : colors.mutedForeground;

    // The style (and therefore the space the text occupies) stays the same for
    // both states. Only the visual scale changes, so activating a status can't
    // shift the surrounding layout.
    final labelStyle = typography.lgSemibold.copyWith(color: color);

    return Column(
      children: [
        AnimatedScale(
          scale: active ? 1.2 : 1.0,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          child: AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 150),
            style: labelStyle,
            child: Text(label),
          ),
        ),
        Text('($detail)', style: typography.base.copyWith(color: color)),
      ],
    );
  }
}
