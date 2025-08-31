// timer.dart
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';

class Timer extends StatefulWidget {
  const Timer({super.key});

  @override
  TimerState createState() => TimerState();
}

class TimerState extends State<Timer> {
  @override
  Widget build(context) {
    return const Text('timer');
  }
}
