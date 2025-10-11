// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/header.dart';
import 'package:proj/hive/hive_boxes.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/workout_auth.dart';
import 'package:proj/workout_page.dart';

//TODO: add isEditing state var and pass it to header settingsStuff.
//then if isEditing, show checkboxes (circles) + 'select all' btn
//then if selectedItems.length > 0, show delete button at bottom or somewhere - look at apple ui

class WorkoutList extends StatefulWidget {
  const WorkoutList({super.key});

  @override
  State<WorkoutList> createState() => _WorkoutListState();
}

class _WorkoutListState extends State<WorkoutList>
    with SingleTickerProviderStateMixin {
  late FPopoverController popoverController;

  @override
  void initState() {
    super.initState();
    popoverController = FPopoverController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return FScaffold(
      header: Header(
        popoverController: popoverController,
        settingsStuff: [
          FItemGroup(
            children: [
              FItem(
                prefix: Icon(FIcons.plus),
                title: Text('Add Workout'),
                onPress: () {
                  popoverController.hide();
                  final box = Hive.box<Workout>(workoutBox);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => WorkoutAuth(workoutBox: box),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
      child: ValueListenableBuilder<Box<Workout>>(
        valueListenable: Hive.box<Workout>(workoutBox).listenable(),
        builder: (BuildContext context, Box<Workout> box, Widget? _) {
          final workouts = box.values.toList();
          return workouts.isEmpty
              //TODO: eventually add icon to show type of workout. idk what types will be availible yet
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
                    ...workouts.map(
                      (w) => FItem(
                        title: Text(w.name),
                        suffix: Icon(FIcons.chevronRight, size: 28),
                        onPress: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => WorkoutPage(workout: w),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
        },
      ),
    );
  }
}
