import 'package:flutter/material.dart';
import 'screens/InitScreen.dart';
void main() async {

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InitScreen(),
    );
  }
}