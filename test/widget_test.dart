import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:huellitas/main.dart';

void main() {
  testWidgets('HomeScreen smoke test', (WidgetTester tester) async {
    // Build our app
    await tester.pumpWidget(MyApp()); // <- quitar const

    // Verifica que un texto que sí existe aparezca
    expect(find.text('¡Bienvenido a Huellitas!\nCuida, ama y acompaña 🐶'), findsOneWidget);

    // Verifica que un icono exista
    expect(find.byIcon(Icons.menu), findsOneWidget);
  });
}
