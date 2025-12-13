import 'package:flutter/material.dart';
import 'screens/InitScreen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InitScreen(), // o la pantalla que uses
    );
  }
}

