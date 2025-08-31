// main.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:proj/timer_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // root widget
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // wrap entire app widget tree `child` with FTheme
      builder: (context, child) {
        return FTheme(data: FThemes.yellow.dark, child: child!);
      },
      home: HomePage(),
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
      header: const Row(children: [Text('timer app')]),
      child: TimerPage(time: 3),
    );
  }
}
