// widgets/workout_analytics.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/services/analytics_service.dart';
import 'package:proj/theme/theme.dart';
import 'package:proj/widgets/analytics_stats.dart';
import 'package:proj/widgets/calendar_heatmap.dart';

class WorkoutAnalyticsPage extends StatefulWidget {
  final Workout workout;
  
  const WorkoutAnalyticsPage({
    super.key,
    required this.workout,
  });

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
    final analytics = AnalyticsService.instance;
    final heatmapData = analytics.getYearHeatmapData(_workoutKey, _selectedYear);
    
    return FScaffold(
      header: Header(
        titleText: '${widget.workout.name} - Analytics',
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Stats cards
            Text(
              'Overview',
              style: typography.lgSemibold,
            ),
            const SizedBox(height: 16),
            AnalyticsStats(workoutKey: _workoutKey),
            const SizedBox(height: 32),
            
            // Activity heatmap
            Text(
              'Activity',
              style: typography.lgSemibold,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey[800]!,
                  width: 1,
                ),
              ),
              child: CalendarHeatmap(
                workoutKey: _workoutKey,
                heatmapData: heatmapData,
                year: _selectedYear,
                onYearChanged: (year) {
                  setState(() {
                    _selectedYear = year;
                  });
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Session history (last 10)
            Text(
              'Recent Sessions',
              style: typography.lgSemibold,
            ),
            const SizedBox(height: 16),
            _buildSessionHistory(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSessionHistory() {
    final analytics = AnalyticsService.instance;
    final sessions = analytics.getSessionsForWorkout(_workoutKey);
    
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.grey[800]!,
            width: 1,
          ),
        ),
        child: Center(
          child: Text(
            'No sessions recorded yet.\nComplete a workout to see your history.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ),
      );
    }
    
    // Show last 10 sessions
    final recentSessions = sessions.take(10).toList();
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[800]!,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: recentSessions.asMap().entries.map((entry) {
          final index = entry.key;
          final session = entry.value;
          final date = session.date;
          final dateStr = '${_dayName(date.weekday)}, ${date.day}/${date.month}/${date.year}';
          final timeStr = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
          final durationStr = _formatDuration(session.durationSeconds);
          
          return Column(
            children: [
              if (index > 0)
                Divider(
                  color: Colors.grey[800],
                  height: 1,
                ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      session.completed ? Icons.check_circle : Icons.cancel,
                      color: session.completed ? Colors.green : Colors.orange,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateStr,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            timeStr,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      durationStr,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
  
  String _dayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
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

