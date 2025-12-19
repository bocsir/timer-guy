// main.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:proj/hive/hive_boxes.dart';
import 'package:proj/hive/hive_registrar.g.dart';
import 'package:proj/models/workout.dart';
import 'package:proj/models/workout_session.dart';
import 'package:proj/services/analytics_service.dart';
import 'package:proj/theme/theme.dart';
import 'package:proj/workout_list.dart';

Future<void> main() async {
  // hive setup
  await Hive.initFlutter();
  Hive.registerAdapters();
  
  // Delete old box if it exists (migration from old model structure)
  try {
    await Hive.deleteBoxFromDisk(workoutBox);
  } catch (e) {
    // Box doesn't exist or already deleted, continue
  }
  
  await Hive.openBox<Workout>(workoutBox);
  await Hive.openBox<WorkoutSession>(workoutSessionBox);
  
  // Initialize analytics service
  AnalyticsService.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root widget
  @override
  Widget build(BuildContext context) {
    final theme = zincDark;

    return MaterialApp(
      builder: (_, child) => FTheme(data: theme, child: child!),
      theme: theme.toApproximateMaterialTheme().copyWith(
        textTheme: theme.toApproximateMaterialTheme().textTheme.apply(
          fontFamily: 'IBMPlexMono',
        ),
      ),
      home: const FScaffold(child: HomePage()),
      debugShowCheckedModeBanner: false,
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
