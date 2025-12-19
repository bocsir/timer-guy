// widgets/calendar_heatmap.dart
import 'package:flutter/material.dart';

class CalendarHeatmap extends StatefulWidget {
  final int workoutKey;
  final Map<DateTime, int> heatmapData; // day -> count or duration
  final int year;
  final void Function(int year)? onYearChanged;
  final bool showDuration; // true = show duration, false = show count

  const CalendarHeatmap({
    super.key,
    required this.workoutKey,
    required this.heatmapData,
    required this.year,
    this.onYearChanged,
    this.showDuration = false,
  });

  @override
  State<CalendarHeatmap> createState() => _CalendarHeatmapState();
}

class _CalendarHeatmapState extends State<CalendarHeatmap> {
  static const List<String> _monthLabels = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  
  static const List<String> _dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', ''];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Year selector
        _buildYearSelector(),
        const SizedBox(height: 16),
        // Heatmap grid
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: _buildHeatmapGrid(),
        ),
        const SizedBox(height: 12),
        // Legend
        _buildLegend(),
      ],
    );
  }

  Widget _buildYearSelector() {
    final currentYear = DateTime.now().year;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => widget.onYearChanged?.call(widget.year - 1),
        ),
        Text(
          '${widget.year}',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: widget.year < currentYear
              ? () => widget.onYearChanged?.call(widget.year + 1)
              : null,
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid() {
    // Get the first day of the year
    final firstDay = DateTime(widget.year, 1, 1);
    final lastDay = DateTime(widget.year, 12, 31);
    
    // Calculate number of weeks
    final totalDays = lastDay.difference(firstDay).inDays + 1;
    final firstDayWeekday = firstDay.weekday; // 1 = Monday, 7 = Sunday
    final totalWeeks = ((totalDays + firstDayWeekday - 1) / 7).ceil();
    
    // Build week columns
    List<Widget> weekColumns = [];
    
    // Day labels column
    weekColumns.add(
      Column(
        children: [
          const SizedBox(height: 20), // Space for month labels
          ...List.generate(7, (dayIndex) {
            return SizedBox(
              height: 14,
              width: 24,
              child: Text(
                _dayLabels[dayIndex],
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.grey[400],
                ),
              ),
            );
          }),
        ],
      ),
    );
    
    // Weeks
    DateTime currentDate = firstDay.subtract(Duration(days: firstDayWeekday - 1));
    int lastMonth = -1;
    
    for (int week = 0; week < totalWeeks; week++) {
      List<Widget> dayCells = [];
      
      // Month label for this week
      String monthLabel = '';
      for (int day = 0; day < 7; day++) {
        if (currentDate.add(Duration(days: day)).month != lastMonth &&
            currentDate.add(Duration(days: day)).year == widget.year) {
          lastMonth = currentDate.add(Duration(days: day)).month;
          monthLabel = _monthLabels[lastMonth - 1];
          break;
        }
      }
      
      dayCells.add(
        SizedBox(
          height: 20,
          child: Text(
            monthLabel,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[400],
            ),
          ),
        ),
      );
      
      // Days in this week
      for (int day = 0; day < 7; day++) {
        final cellDate = currentDate.add(Duration(days: day));
        final isCurrentYear = cellDate.year == widget.year;
        final isFuture = cellDate.isAfter(DateTime.now());
        
        if (isCurrentYear && !isFuture) {
          final normalizedDate = DateTime(cellDate.year, cellDate.month, cellDate.day);
          final value = widget.heatmapData[normalizedDate] ?? 0;
          dayCells.add(_buildDayCell(value, cellDate));
        } else {
          dayCells.add(_buildEmptyCell());
        }
      }
      
      weekColumns.add(
        Column(
          children: dayCells,
        ),
      );
      
      currentDate = currentDate.add(const Duration(days: 7));
    }
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: weekColumns,
    );
  }

  Widget _buildDayCell(int value, DateTime date) {
    final color = _getColorForValue(value);
    
    return Tooltip(
      message: _getTooltipText(value, date),
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEmptyCell() {
    return Container(
      width: 12,
      height: 12,
      margin: const EdgeInsets.all(1),
    );
  }

  Color _getColorForValue(int value) {
    if (value == 0) {
      return Colors.grey[800]!;
    }
    
    // Define thresholds based on whether we're showing count or duration
    if (widget.showDuration) {
      // Duration in seconds: light < 10min, medium < 30min, heavy >= 30min
      if (value < 600) return Colors.green[300]!;
      if (value < 1800) return Colors.green[500]!;
      return Colors.green[700]!;
    } else {
      // Count: 1 = light, 2 = medium, 3+ = heavy
      if (value == 1) return Colors.green[300]!;
      if (value == 2) return Colors.green[500]!;
      return Colors.green[700]!;
    }
  }

  String _getTooltipText(int value, DateTime date) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    
    if (value == 0) {
      return '$dateStr\nNo activity';
    }
    
    if (widget.showDuration) {
      final minutes = value ~/ 60;
      final seconds = value % 60;
      return '$dateStr\n${minutes}m ${seconds}s';
    } else {
      return '$dateStr\n$value session${value == 1 ? '' : 's'}';
    }
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Less',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.grey[800],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green[500],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 2),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: Colors.green[700],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(
          'More',
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[400],
          ),
        ),
      ],
    );
  }
}

