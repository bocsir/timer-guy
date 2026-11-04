// widgets/calendar_heatmap.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/theme/theme.dart';

/// A GitHub-style activity heatmap for a single year of workout sessions.
class CalendarHeatmap extends StatefulWidget {
  final Map<DateTime, int> heatmapData;
  final int year;
  final void Function(int year)? onYearChanged;
  final bool showDuration;

  const CalendarHeatmap({
    super.key,
    required this.heatmapData,
    required this.year,
    this.onYearChanged,
    this.showDuration = false,
  });

  @override
  State<CalendarHeatmap> createState() => _CalendarHeatmapState();
}

class _CalendarHeatmapState extends State<CalendarHeatmap> {
  static const _monthLabels = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  static const _dayLabels = ['Mon', '', 'Wed', '', 'Fri', '', ''];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildYearSelector(context),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: _buildHeatmapGrid(context),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _buildLegend(context),
      ],
    );
  }

  Widget _buildYearSelector(BuildContext context) {
    final colors = context.theme.colors;
    final currentYear = DateTime.now().year;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FButton.icon(
          style: FButtonStyle.ghost(),
          onPress: () => widget.onYearChanged?.call(widget.year - 1),
          child: Icon(FIcons.chevronLeft, color: colors.mutedForeground),
        ),
        Text('${widget.year}', style: context.theme.typography.lgSemibold),
        FButton.icon(
          style: FButtonStyle.ghost(),
          onPress: widget.year < currentYear
              ? () => widget.onYearChanged?.call(widget.year + 1)
              : null,
          child: Icon(FIcons.chevronRight, color: colors.mutedForeground),
        ),
      ],
    );
  }

  Widget _buildHeatmapGrid(BuildContext context) {
    final firstDay = DateTime(widget.year, 1, 1);
    final lastDay = DateTime(widget.year, 12, 31);
    final totalDays = lastDay.difference(firstDay).inDays + 1;
    final firstDayWeekday = firstDay.weekday;
    final totalWeeks = ((totalDays + firstDayWeekday - 1) / 7).ceil();

    final weekColumns = <Widget>[
      Column(
        children: [
          const SizedBox(height: 20),
          ...List.generate(
            7,
            (dayIndex) => SizedBox(
              height: 14,
              width: 24,
              child: Text(
                _dayLabels[dayIndex],
                style: context.theme.typography.xs.copyWith(
                  fontSize: 9,
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
        ],
      ),
    ];

    var currentDate = firstDay.subtract(Duration(days: firstDayWeekday - 1));
    var lastMonth = -1;

    for (var week = 0; week < totalWeeks; week++) {
      final dayCells = <Widget>[];

      var monthLabel = '';
      for (var day = 0; day < 7; day++) {
        final date = currentDate.add(Duration(days: day));
        if (date.month != lastMonth && date.year == widget.year) {
          lastMonth = date.month;
          monthLabel = _monthLabels[lastMonth - 1];
          break;
        }
      }

      dayCells.add(
        SizedBox(
          height: 20,
          child: Text(
            monthLabel,
            style: context.theme.typography.xs.copyWith(
              fontSize: 9,
              color: context.theme.colors.mutedForeground,
            ),
          ),
        ),
      );

      for (var day = 0; day < 7; day++) {
        final cellDate = currentDate.add(Duration(days: day));
        final isCurrentYear = cellDate.year == widget.year;
        final isFuture = cellDate.isAfter(DateTime.now());

        if (isCurrentYear && !isFuture) {
          final normalizedDate = DateTime(
            cellDate.year,
            cellDate.month,
            cellDate.day,
          );
          dayCells.add(
            _buildDayCell(
              context,
              widget.heatmapData[normalizedDate] ?? 0,
              cellDate,
            ),
          );
        } else {
          dayCells.add(_buildEmptyCell());
        }
      }

      weekColumns.add(Column(children: dayCells));
      currentDate = currentDate.add(const Duration(days: 7));
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: weekColumns,
    );
  }

  Widget _buildDayCell(BuildContext context, int value, DateTime date) {
    return Tooltip(
      message: _tooltipText(value, date),
      child: Container(
        width: 12,
        height: 12,
        margin: const EdgeInsets.all(1),
        decoration: BoxDecoration(
          color: _colorForValue(context, value),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildEmptyCell() =>
      Container(width: 12, height: 12, margin: const EdgeInsets.all(1));

  Color _colorForValue(BuildContext context, int value) {
    final colors = context.theme.colors;
    if (value == 0) return colors.border;

    final intensity = widget.showDuration
        ? (value < 600
              ? 0.35
              : value < 1800
              ? 0.65
              : 1.0)
        : (value == 1
              ? 0.35
              : value == 2
              ? 0.65
              : 1.0);
    return colors.accent.withValues(alpha: intensity);
  }

  String _tooltipText(int value, DateTime date) {
    final dateStr = '${date.day}/${date.month}/${date.year}';
    if (value == 0) return '$dateStr\nNo activity';

    if (widget.showDuration) {
      return '$dateStr\n${value ~/ 60}m ${value % 60}s';
    }
    return '$dateStr\n$value session${value == 1 ? '' : 's'}';
  }

  Widget _buildLegend(BuildContext context) {
    final colors = context.theme.colors;
    final labelStyle = context.theme.typography.xs.copyWith(
      fontSize: 10,
      color: colors.mutedForeground,
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Less', style: labelStyle),
        const SizedBox(width: 4),
        _legendBox(colors.border),
        const SizedBox(width: 2),
        _legendBox(colors.accent.withValues(alpha: 0.35)),
        const SizedBox(width: 2),
        _legendBox(colors.accent.withValues(alpha: 0.65)),
        const SizedBox(width: 2),
        _legendBox(colors.accent),
        const SizedBox(width: 4),
        Text('More', style: labelStyle),
      ],
    );
  }

  Widget _legendBox(Color color) => Container(
    width: 12,
    height: 12,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(2),
    ),
  );
}
