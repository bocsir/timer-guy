// main.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/header.dart';
import 'package:proj/workout_auth.dart';
import 'package:proj/workout_list.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root widget
  @override
  Widget build(BuildContext context) {
    final theme = FThemes.zinc.dark;

    return MaterialApp(
      builder: (_, child) => FTheme(data: theme, child: child!),
      theme: theme.toApproximateMaterialTheme(),
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
    return FScaffold(
      header: Header(),
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: FButton(
              style: FButtonStyle.outline(),
              onPress: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (context) => WorkoutAuth()));
              },
              child: Text('Add Workout'),
            ),
          ),
        ],
      ),
      child: WorkoutList(),
    );
  }
}
