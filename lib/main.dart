import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/firebase_notifications.dart'; // Tu archivo con configurarFCM()
import 'screens/InitScreen.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Necesario para async en main

  // Inicializa Firebase
  await Firebase.initializeApp();

  // Configura notificaciones (Web + Móvil)
  await configurarFCM();

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