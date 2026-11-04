// widgets/workout_analytics.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/models/workout_session.dart';
import 'package:timer_guy/services/analytics_service.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/widgets/analytics_stats.dart';
import 'package:timer_guy/widgets/calendar_heatmap.dart';

class WorkoutAnalyticsPage extends StatefulWidget {
  final Workout workout;

  const WorkoutAnalyticsPage({super.key, required this.workout});

  @override
  State<WorkoutAnalyticsPage> createState() => _WorkoutAnalyticsPageState();
}

class _WorkoutAnalyticsPageState extends State<WorkoutAnalyticsPage> {
  late int _selectedYear;

  int get _workoutKey => widget.workout.key as int;

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final sessionsBox = Hive.box<WorkoutSession>(workoutSessionBox);

    return FScaffold(
      header: const Header(titleText: 'Analytics'),
      child: ValueListenableBuilder(
        valueListenable: sessionsBox.listenable(),
        builder: (context, _, __) {
          final analytics = AnalyticsService.instance;
          final heatmapData = analytics.getYearHeatmapData(
            _workoutKey,
            _selectedYear,
          );

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.workout.name, style: typography.xl3Semibold),
                Text(
                  'Past workouts and activity',
                  style: typography.sm.copyWith(color: colors.mutedForeground),
                ),
                const SizedBox(height: 24),

                Text('Overview', style: typography.lgSemibold),
                const SizedBox(height: 12),
                AnalyticsStats(workoutKey: _workoutKey),
                const SizedBox(height: 32),

                Text('Activity', style: typography.lgSemibold),
                const SizedBox(height: 12),
                _Panel(
                  child: CalendarHeatmap(
                    heatmapData: heatmapData,
                    year: _selectedYear,
                    onYearChanged: (year) =>
                        setState(() => _selectedYear = year),
                  ),
                ),
                const SizedBox(height: 32),

                Text('Recent Sessions', style: typography.lgSemibold),
                const SizedBox(height: 12),
                _buildSessionHistory(context),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSessionHistory(BuildContext context) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final sessions = AnalyticsService.instance.getSessionsForWorkout(
      _workoutKey,
    );

    if (sessions.isEmpty) {
      return _Panel(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No sessions recorded yet.\nComplete a workout to see your history.',
              textAlign: TextAlign.center,
              style: typography.sm.copyWith(color: colors.mutedForeground),
            ),
          ),
        ),
      );
    }

    final recent = sessions.take(10).toList();

    return _Panel(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < recent.length; i++) ...[
            if (i > 0) Divider(color: colors.border, height: 1),
            _sessionRow(context, recent[i]),
          ],
        ],
      ),
    );
  }

  Widget _sessionRow(BuildContext context, WorkoutSession session) {
    final typography = context.theme.typography;
    final colors = context.theme.colors;
    final date = session.date;
    final dateStr =
        '${_dayName(date.weekday)}, ${date.day}/${date.month}/${date.year}';
    final timeStr =
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            session.completed ? FIcons.check : FIcons.circleX,
            color: session.completed ? colors.accent : colors.mutedForeground,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dateStr,
                  style: typography.sm.copyWith(fontWeight: FontWeight.w500),
                ),
                Text(
                  timeStr,
                  style: typography.xs.copyWith(color: colors.mutedForeground),
                ),
              ],
            ),
          ),
          Text(
            formatDuration(session.durationSeconds),
            style: typography.sm.copyWith(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }
}

class _Panel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _Panel({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }
}
