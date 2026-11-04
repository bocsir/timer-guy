import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/settings.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/workout_page.dart';

void main() {
  testWidgets('capture light workout background and settings', (tester) async {
    tester.view.physicalSize = const Size(900, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final workout = Workout(
      name: 'Morning Burn',
      description: 'A quick test workout',
      sets: [
        WorkoutSet(name: 'Push Ups', reps: 3, timeOn: 30, timeOff: 15),
      ],
    );

    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          builder: (_, child) => FTheme(data: zincLight, child: child!),
          home: WorkoutPage(workout: workout),
        ),
      ),
    );

    Future<void> capture(String path) async {
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File(path).writeAsBytes(bytes!.buffer.asUint8List());
      });
    }

    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await capture('/tmp/opencode/workout_light_new.png');

    await tester.tap(find.byIcon(FIcons.settings));
    await tester.pump(const Duration(milliseconds: 300));
    await capture('/tmp/opencode/workout_settings.png');

    animatedBackgroundEnabled.value = false;
    await tester.pump(const Duration(milliseconds: 300));
    await capture('/tmp/opencode/workout_light_disabled.png');
    animatedBackgroundEnabled.value = true;
  });
}
