// widgets/analytics_stats.dart
import 'package:flutter/material.dart';
import 'package:proj/services/analytics_service.dart';

class AnalyticsStats extends StatelessWidget {
  final int workoutKey;
  
  const AnalyticsStats({
    super.key,
    required this.workoutKey,
  });

  @override
  Widget build(BuildContext context) {
    final analytics = AnalyticsService.instance;
    
    final currentStreak = analytics.getCurrentStreak(workoutKey);
    final longestStreak = analytics.getLongestStreak(workoutKey);
    final monthlyCount = analytics.getMonthlySessionCount(
      workoutKey,
      DateTime.now().year,
      DateTime.now().month,
    );
    final totalDuration = analytics.getTotalDurationAll(workoutKey);
    final avgDuration = analytics.getAverageDuration(workoutKey);
    final weeklyAvg = analytics.getWeeklyFrequency(workoutKey);
    
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Current Streak',
                value: '$currentStreak',
                unit: 'days',
                icon: Icons.local_fire_department,
                iconColor: currentStreak > 0 ? Colors.orange : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Longest Streak',
                value: '$longestStreak',
                unit: 'days',
                icon: Icons.emoji_events,
                iconColor: longestStreak > 0 ? Colors.amber : Colors.grey,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'This Month',
                value: '$monthlyCount',
                unit: 'sessions',
                icon: Icons.calendar_month,
                iconColor: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                title: 'Total Time',
                value: _formatDuration(totalDuration),
                unit: '',
                icon: Icons.timer,
                iconColor: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Avg Duration',
                value: _formatDuration(avgDuration.round()),
                unit: '',
                icon: Icons.schedule,
                iconColor: Colors.purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                title: 'Weekly Avg',
                value: weeklyAvg.toStringAsFixed(1),
                unit: 'sessions',
                icon: Icons.show_chart,
                iconColor: Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }
  
  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    } else if (seconds < 3600) {
      final mins = seconds ~/ 60;
      final secs = seconds % 60;
      return '${mins}m ${secs}s';
    } else {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return '${hours}h ${mins}m';
    }
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final String unit;
  final IconData icon;
  final Color iconColor;
  
  const _StatCard({
    required this.title,
    required this.value,
    required this.unit,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 16,
                color: iconColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (unit.isNotEmpty)
            Text(
              unit,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
              ),
            ),
        ],
      ),
    );
  }
}

