// working_resting_status.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:proj/workout_page.dart';

class WorkingRestingStatus extends StatefulWidget {
  final WorkoutStatus status;
  final Workout workout;
  final int currSet;

  const WorkingRestingStatus({super.key, required this.status, required this.workout, required this.currSet});

  @override
  State<WorkingRestingStatus> createState() => _WorkingRestingStatusState();
}

class _WorkingRestingStatusState extends State<WorkingRestingStatus> {
  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: 400),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              Text(
                'Working',
                style: context.theme.typography.xlSemibold.copyWith(
                  color: widget.status == WorkoutStatus.working
                      ? context.theme.colors.accent
                      : context.theme.colors.mutedForeground,
                ),
              ),
              Text(
                '(${widget.workout.sets[widget.currSet].timeOn}s)',
                style: context.theme.typography.base.copyWith(
                  color: widget.status == WorkoutStatus.working
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
                  color: widget.status == WorkoutStatus.resting
                      ? context.theme.colors.accent
                      : context.theme.colors.mutedForeground,
                ),
              ),
              Text(
                '(${widget.workout.sets[widget.currSet].timeOff}s)',
                style: context.theme.typography.base.copyWith(
                  color: widget.status == WorkoutStatus.resting
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
