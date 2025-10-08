// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/header.dart';
import 'package:proj/hive/hive_boxes.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/workout_auth.dart';

class WorkoutList extends StatelessWidget {
  const WorkoutList({super.key});

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: Header(),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              bottom: 32,
              right: 32,
              top: 16,
              left: 16,
            ),
            child: FButton(
              style: FButtonStyle.outline(),
              onPress: () {
                final box = Hive.box<Workout>(workoutBox);
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => WorkoutAuth(workoutBox: box),
                  ),
                );
              },
              child: Text('Add Workout'),
            ),
          ),
        ],
      ),
      child: ValueListenableBuilder<Box<Workout>>(
        valueListenable: Hive.box<Workout>(workoutBox).listenable(),
        builder: (BuildContext context, Box<Workout> box, Widget? _) {
          final workouts = box.values.toList();
          return workouts.isEmpty
              ? Column(
                  children: [
                    Text(
                      'No workouts found',
                      style: context.theme.typography.base,
                    ),
                    SizedBox(height: 20),
                    Text(
                      '''
 o    _ o   __|    \\ /
/|\\    /\\     \\o    |
/ \\   | \\     ( \\  /o\\
                      ''',
                      style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14),
                    ),
                  ],
                )
              : FItemGroup(
                  children: [
                    FItem(
                      title: Text('item1'),
                      suffix: Icon(FIcons.chevronRight),
                      onPress: () {},
                    ),
                    ...workouts.map(
                      (w) => FItem(
                        title: Text(w.name),
                        suffix: Icon(FIcons.chevronRight),
                        onPress: () {},
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
