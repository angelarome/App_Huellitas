import 'package:flutter/material.dart';
import 'screens/inicial1.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
  FlutterError.presentError(details);
  print('🔥 Error de Flutter detectado: ${details.exception}');
};
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: InicioScreen(),
    );
  }
}
