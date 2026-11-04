// main.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:timer_guy/audio/beep_player.dart';
import 'package:timer_guy/hive/hive_boxes.dart';
import 'package:timer_guy/hive/register_adapters.dart';
import 'package:timer_guy/hive/workout_adapter.dart';
import 'package:timer_guy/hive/workout_set_adapter.dart';
import 'package:timer_guy/models/workout.dart';
import 'package:timer_guy/models/workout_session.dart';
import 'package:timer_guy/services/analytics_service.dart';
import 'package:timer_guy/theme/theme.dart';
import 'package:timer_guy/workout_list.dart';

Future<void> main() async {
  // hive setup
  await Hive.initFlutter();
  registerAdapters();
  final box = await Hive.openBox<Workout>(workoutBox);
  await Hive.openBox<WorkoutSession>(workoutSessionBox);
  AnalyticsService.instance.initialize();

  // Load the persisted theme preference and save future changes.
  final settings = await Hive.openBox<bool>(settingsBox);
  appThemeMode.value = (settings.get(darkModeKey, defaultValue: true) ?? true)
      ? ThemeMode.dark
      : ThemeMode.light;
  appThemeMode.addListener(() {
    settings.put(darkModeKey, appThemeMode.value == ThemeMode.dark);
  });

  // Rewrite records read with the old schema in the current format so the
  // migration only has to run once. See MigratingWorkoutAdapter.read and
  // MigratingWorkoutSetAdapter.read.
  if (MigratingWorkoutAdapter.migratedLegacyData ||
      MigratingWorkoutSetAdapter.migratedLegacyData) {
    await box.putAll({
      for (final entry in box.toMap().entries) entry.key: entry.value,
    });
    // Drop the now-unused frames written with the old schema.
    await box.compact();
    MigratingWorkoutAdapter.migratedLegacyData = false;
    MigratingWorkoutSetAdapter.migratedLegacyData = false;
  }

  await BeepPlayer.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root widget
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: appThemeMode,
      builder: (context, mode, __) {
        final theme = mode == ThemeMode.light ? zincLight : zincDark;
        final materialTheme = theme.toApproximateMaterialTheme().copyWith(
          textTheme: theme.toApproximateMaterialTheme().textTheme.apply(
            fontFamily: 'IBMPlexMono',
          ),
        );

        return MaterialApp(
          builder: (_, child) => FTheme(data: theme, child: child!),
          theme: materialTheme,
          home: const FScaffold(child: HomePage()),
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  @override
  Widget build(context) {
    return WorkoutList();
  }
}
