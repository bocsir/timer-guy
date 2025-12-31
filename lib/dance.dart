// dance.dart
import 'package:flutter/material.dart';

class Dance extends StatelessWidget {
  const Dance({super.key});

  @override
  Widget build(BuildContext context) {
    return
    // dart format off
                          Text('''
       o    _ o   __|    \\ /
      /|\\    /\\     \\o    |
      / \\   | \\     ( \\  /o\\
                                          ''', 
                            style: TextStyle(fontFamily: 'IBMPlexMono', fontSize: 14));
    // dart format on
  }
}
