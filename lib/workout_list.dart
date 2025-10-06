// workout_list.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';

class WorkoutList extends StatelessWidget {
  const WorkoutList({super.key});

  @override
  Widget build(BuildContext context) {
    return FItemGroup(
      children: [
        FItem(
          title: Text('item1'),
          suffix: Icon(FIcons.chevronRight),
          onPress: () {},
        ),
      ],
    );
  }
}
