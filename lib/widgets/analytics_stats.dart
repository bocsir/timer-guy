// widgets/analytics_stats.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/services/analytics_service.dart';
import 'package:timer_guy/theme/theme.dart';

class AnalyticsStats extends StatelessWidget {
  final int workoutKey;

  const AnalyticsStats({super.key, required this.workoutKey});

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService.instance;
    final now = DateTime.now();

    final stats = [
      (
        title: 'Current Streak',
        value: '${analytics.getCurrentStreak(workoutKey)}',
        unit: 'days',
        icon: FIcons.flame,
      ),
      (
        title: 'Longest Streak',
        value: '${analytics.getLongestStreak(workoutKey)}',
        unit: 'days',
        icon: FIcons.trophy,
      ),
      (
        title: 'This Month',
        value:
            '${analytics.getMonthlySessionCount(workoutKey, now.year, now.month)}',
        unit: 'sessions',
        icon: FIcons.calendar,
      ),
      (
        title: 'Total Time',
        value: formatDuration(analytics.getTotalDurationAll(workoutKey)),
        unit: '',
        icon: FIcons.timer,
      ),
      (
        title: 'Avg Duration',
        value: formatDuration(analytics.getAverageDuration(workoutKey).round()),
        unit: '',
        icon: FIcons.clock3,
      ),
      (
        title: 'Weekly Avg',
        value: analytics.getWeeklyFrequency(workoutKey).toStringAsFixed(1),
        unit: 'sessions',
        icon: FIcons.chartBar,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth - 12) / 2;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final stat in stats)
              SizedBox(
                width: cardWidth,
                height: 112,
                child: _StatCard(
                  title: stat.title,
                  value: stat.value,
                  unit: stat.unit,
                  icon: stat.icon,
                ),
              ),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.theme.colors;
    final typography = context.theme.typography;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.secondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: typography.xs.copyWith(
                    color: colors.mutedForeground,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: typography.xl2.copyWith(
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
              ),
              SizedBox(
                height: 14,
                child: unit.isEmpty
                    ? null
                    : Text(
                        unit,
                        style: typography.xs.copyWith(
                          color: colors.mutedForeground,
                          fontSize: 11,
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Formats a number of seconds for the analytics screens.
String formatDuration(int seconds) {
  if (seconds < 60) return '${seconds}s';
  if (seconds < 3600) return '${seconds ~/ 60}m ${seconds % 60}s';
  return '${seconds ~/ 3600}h ${(seconds % 3600) ~/ 60}m';
}
