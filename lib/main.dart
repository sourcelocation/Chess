import 'package:flutter/material.dart';
import 'package:chess/components/game_screen.dart';

void main() {
  runApp(const Chess());
}

class Chess extends StatelessWidget {
  const Chess({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.grey,
      ),
      home: GameScreen(),
    );
  }
}
