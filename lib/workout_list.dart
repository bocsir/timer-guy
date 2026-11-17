// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/dance.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/widgets/settings_menu_button.dart';
import 'package:timer_guy/widgets/workout_analytics.dart';
import 'package:timer_guy/widgets/workout_yaml_actions.dart';
import 'package:timer_guy/workout_auth.dart';
import 'package:timer_guy/workout_page.dart';

class WorkoutList extends StatefulWidget {
  const WorkoutList({super.key});

  @override
  State<WorkoutList> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList> {
  bool _exporting = false;
  final Set<dynamic> _selectedKeys = {};

  void _toggleExportMode() {
    setState(() {
      _exporting = !_exporting;
      _selectedKeys.clear();
    });
  }

  void _toggleSelected(dynamic key) {
    setState(() {
      if (!_selectedKeys.remove(key)) {
        _selectedKeys.add(key);
      }
    });
  }

  Future<void> _exportWorkouts(Box<Workout> box) async {
    final workouts = _selectedKeys.isEmpty
        ? box.values.toList()
        : box.keys
              .where(_selectedKeys.contains)
              .map(box.get)
              .whereType<Workout>()
              .toList();

    if (workouts.isEmpty) return;
    await exportWorkoutsAsYaml(context, workouts);
  }

  String get _exportButtonLabel {
    if (_selectedKeys.isEmpty) return 'Export all workouts';
    if (_selectedKeys.length == 1) return 'Export 1 workout';
    return 'Export ${_selectedKeys.length} workouts';
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Workout>(workoutBox);

    return ValueListenableBuilder<Box<Workout>>(
      valueListenable: box.listenable(),
      builder: (BuildContext context, Box<Workout> box, Widget? _) {
        final workouts = box.values.toList();
        final keys = box.keys.toList();

        return FScaffold(
          header: Header(
            hideBackBtn: true,
            titleText: _exporting ? 'Export workouts' : 'Timer Guy',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_exporting)
                  Tooltip(
                    message: 'Cancel export',
                    child: FButton.icon(
                      style: FButtonStyle.ghost(),
                      onPress: _toggleExportMode,
                      child: Icon(
                        FIcons.x,
                        color: context.theme.colors.mutedForeground,
                        size: 24,
                      ),
                    ),
                  )
                else ...[
                  SettingsMenuButton(
                    onImport: () => importWorkoutsFromYaml(context, box),
                    onExport: _toggleExportMode,
                  ),
                  FButton.icon(
                    style: FButtonStyle.ghost(),
                    onPress: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => WorkoutAuth(workoutBox: box),
                      ),
                    ),
                    child: Icon(
                      FIcons.plus,
                      color: context.theme.colors.accent,
                      size: 28,
                    ),
                  ),
                ],
              ],
            ),
          ),
          // The dancing guys keep us company at the bottom of the list.
          // heightFactor: 1 keeps the footer sized to the dancers instead of
          // expanding to fill the scaffold (which would squash the list).
          footer: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_exporting) ...[
                  SizedBox(
                    width: double.infinity,
                    child: FButton(
                      onPress: workouts.isEmpty
                          ? null
                          : () => _exportWorkouts(box),
                      prefix: const Icon(FIcons.download),
                      child: Text(_exportButtonLabel),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                const Center(heightFactor: 1, child: Dance()),
              ],
            ),
          ),
          // The default footer decoration draws a divider line above it.
          scaffoldStyle: (style) =>
              style.copyWith(footerDecoration: const BoxDecoration()),

          childPad: false,
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (workouts.isEmpty)
                    //TODO: eventually add icon to show type of workout. idk what types will be available yet
                    Row(
                      spacing: 8,
                      children: [
                        Text(
                          'No workouts found... add one',
                          style: context.theme.typography.base,
                        ),
                        Icon(FIcons.arrowUpRight),
                      ],
                    )
                  else
                    FItemGroup(
                      divider: FItemDivider.full,
                      children: [
                        for (var i = 0; i < workouts.length; i++)
                          _buildWorkoutItem(context, keys[i], workouts[i]),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  FItem _buildWorkoutItem(BuildContext context, dynamic key, Workout workout) {
    final selected = _selectedKeys.contains(key);
    final box = Hive.box<Workout>(workoutBox);

    return FItem(
      key: ValueKey(key),
      selected: _exporting && selected,
      prefix: _exporting
          ? FCheckbox(
              value: selected,
              onChange: (_) => _toggleSelected(key),
              semanticsLabel: 'Select ${workout.name}',
            )
          : null,
      title: Text(workout.name, style: context.theme.typography.baseSemibold),
      subtitle: workout.description == null || workout.description!.isEmpty
          ? null
          : Text(
              workout.description!,
              style: context.theme.typography.sm.copyWith(
                color: context.theme.colors.mutedForeground,
              ),
            ),
      details: Text(
        '${workout.exercises.length} exercises · ${workout.totalSets} sets · ${workout.totalReps} reps',
        style: context.theme.typography.sm.copyWith(
          color: context.theme.colors.mutedForeground,
        ),
      ),
      suffix: _exporting
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Builder(
                builder: (context) => Row(
                  spacing: 16,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Tooltip(
                      message: 'View analytics',
                      child: FButton.icon(
                        style: FButtonStyle.ghost(),
                        onPress: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) =>
                                WorkoutAnalyticsPage(workout: workout),
                          ),
                        ),
                        child: Icon(
                          FIcons.chartBar,
                          color: context.theme.colors.mutedForeground,
                        ),
                      ),
                    ),
                    FButton.icon(
                      style: FButtonStyle.ghost(),
                      onPress: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              WorkoutAuth(workoutBox: box, workout: workout),
                        ),
                      ),
                      child: Icon(
                        FIcons.pencil,
                        color: context.theme.colors.mutedForeground,
                      ),
                    ),
                  ],
                ),
              ),
            ),
      onPress: _exporting
          ? () => _toggleSelected(key)
          : () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => WorkoutPage(workout: workout),
              ),
            ),
    );
  }
}
