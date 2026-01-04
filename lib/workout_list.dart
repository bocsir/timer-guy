// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/dance.dart';
import 'package:proj/hive/hive_boxes.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/theme/theme.dart';
import 'package:proj/workout_auth.dart';
import 'package:proj/workout_page.dart';

class WorkoutList extends StatefulWidget {
  const WorkoutList({super.key});

  @override
  State<WorkoutList> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList> with SingleTickerProviderStateMixin {
  late FPopoverController popoverController;

  @override
  void initState() {
    super.initState();
    popoverController = FPopoverController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      footer: Padding(
        padding: const EdgeInsets.all(16),
        child: FButton(
          prefix: Icon(FIcons.plus, color: context.theme.colors.foreground),
          style: FButtonStyle.ghost(),
          onPress: () {
            popoverController.hide();
            final box = Hive.box<Workout>(workoutBox);
            Navigator.of(context).push(MaterialPageRoute(builder: (context) => WorkoutAuth(workoutBox: box)));
          },
          child: Text(
            'Add Workout',
            style: context.theme.typography.base.copyWith(color: context.theme.colors.foreground, height: 1),
          ),
        ),
      ),

      childPad: false,
      child: SafeArea(
        child: ValueListenableBuilder<Box<Workout>>(
          valueListenable: Hive.box<Workout>(workoutBox).listenable(),
          builder: (BuildContext context, Box<Workout> box, Widget? _) {
            final workouts = box.values.toList();
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text('Workouts', style: context.theme.typography.xl3Semibold),
                  ),
                  workouts.isEmpty
                      //TODO: eventually add icon to show type of workout. idk what types will be available yet
                      ? Column(
                          spacing: 8,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('No workouts found', style: context.theme.typography.base),
                            Dance(),
                          ],
                        )
                      : FItemGroup(
                          divider: FItemDivider.full,
                          children: [
                            ...workouts.map(
                              (w) => FItem(
                                //TODO:
                                // Title           (sets, reps)
                                // description
                                title: Text(w.name, style: context.theme.typography.baseSemibold),
                                suffix: Icon(FIcons.chevronRight, size: 25, color: context.theme.colors.foreground),
                                onPress: () => Navigator.of(
                                  context,
                                ).push(MaterialPageRoute(builder: (context) => WorkoutPage(workout: w))),
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
