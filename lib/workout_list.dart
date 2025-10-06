// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/hive/hive_boxes.dart';
import 'package:proj/models/workout.dart';

class WorkoutList extends StatelessWidget {
  const WorkoutList({super.key});

  @override
  Widget build(BuildContext context) {
    // get workouts from hive box
    final workouts = Hive.box<Workout>(workoutBox).values;

    return workouts.isEmpty
        ? Column(
            children: [
              Text('No workouts found', style: context.theme.typography.base),
              SizedBox(height: 20),
              Text(
                '''
 o    _ o  __|    \\ /
/|\\    /\\    \\o    |
/ \\   | \\    ( \\  /o\\
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
  }
}
