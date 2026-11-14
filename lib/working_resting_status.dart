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
    final workingLabel = 'Working';
    final workingDetail = exercise.isReps
        ? '${exercise.reps} reps'
        : '${exercise.timeOn}s';

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                workingLabel,
                style: context.theme.typography.xlSemibold.copyWith(
                  color: status == WorkoutStatus.working
                      ? context.theme.colors.accent
                      : context.theme.colors.mutedForeground,
                ),
              ),
              Text(
                '($workingDetail)',
                style: context.theme.typography.base.copyWith(
                  color: status == WorkoutStatus.working
                      ? context.theme.colors.accent
                      : context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
          Column(
            children: [
              Text(
                'Resting',
                style: context.theme.typography.xlSemibold.copyWith(
                  color: status == WorkoutStatus.resting
                      ? context.theme.colors.accent
                      : context.theme.colors.mutedForeground,
                ),
              ),
              Text(
                '(${exercise.timeOff}s)',
                style: context.theme.typography.base.copyWith(
                  color: status == WorkoutStatus.resting
                      ? context.theme.colors.accent
                      : context.theme.colors.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
