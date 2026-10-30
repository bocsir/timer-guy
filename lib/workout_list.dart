// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/dance.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/header.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/workout_auth.dart';
import 'package:timer_guy/workout_page.dart';

class WorkoutList extends StatelessWidget {
  const WorkoutList({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Workout>(workoutBox);

    return ValueListenableBuilder<Box<Workout>>(
      valueListenable: box.listenable(),
      builder: (BuildContext context, Box<Workout> box, Widget? _) {
        final workouts = box.values.toList();
        return FScaffold(
          header: Header(
            hideBackBtn: true,
            titleText: 'Workouts',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<ThemeMode>(
                  valueListenable: appThemeMode,
                  builder: (context, mode, _) {
                    final isDark = mode != ThemeMode.light;
                    return FButton.icon(
                      style: FButtonStyle.ghost(),
                      onPress: () => appThemeMode.value = isDark ? ThemeMode.light : ThemeMode.dark,
                      child: Icon(
                        isDark ? FIcons.sun : FIcons.moon,
                        color: context.theme.colors.mutedForeground,
                        size: 24,
                      ),
                    );
                  },
                ),
                FButton.icon(
                  style: FButtonStyle.ghost(),
                  onPress: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (context) => WorkoutAuth(workoutBox: box))),
                  child: Icon(FIcons.plus, color: context.theme.colors.accent, size: 28),
                ),
              ],
            ),
          ),
          // The dancing guys keep us company at the bottom of the list.
          // heightFactor: 1 keeps the footer sized to the dancers instead of
          // expanding to fill the scaffold (which would squash the list).
          footer: const Padding(
            padding: EdgeInsets.all(16),
            child: Center(heightFactor: 1, child: Dance()),
          ),
          // The default footer decoration draws a divider line above it.
          scaffoldStyle: (style) => style.copyWith(footerDecoration: const BoxDecoration()),

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
                        Text('No workouts found... add one', style: context.theme.typography.base),
                        Icon(FIcons.arrowUpRight),
                      ],
                    )
                  else
                    FItemGroup(
                      divider: FItemDivider.full,
                      children: [
                        ...workouts.map(
                          (w) => FItem(
                            title: Text(w.name, style: context.theme.typography.baseSemibold),
                            subtitle: w.description == null || w.description!.isEmpty
                                ? null
                                : Text(
                                    w.description!,
                                    style: context.theme.typography.sm.copyWith(
                                      color: context.theme.colors.mutedForeground,
                                    ),
                                  ),
                            details: Text(
                              '${w.sets.length} sets · ${w.totalReps} reps',
                              style: context.theme.typography.sm.copyWith(
                                color: context.theme.colors.mutedForeground,
                              ),
                            ),
                            suffix: Row(
                              spacing: 16,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FButton.icon(
                                  style: FButtonStyle.ghost(),
                                  onPress: () => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => WorkoutAuth(workoutBox: box, workout: w),
                                    ),
                                  ),
                                  child: Icon(FIcons.pencil, color: context.theme.colors.mutedForeground),
                                ),
                                Icon(FIcons.chevronRight, size: 25, color: context.theme.colors.foreground),
                              ],
                            ),
                            onPress: () => Navigator.of(
                              context,
                            ).push(MaterialPageRoute(builder: (context) => WorkoutPage(workout: w))),
                          ),
                        ),
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
}
