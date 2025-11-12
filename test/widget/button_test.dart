import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Debe mostrar el texto "Hola Mundo"', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(home: Text('Hola Mundo')));
    expect(find.text('Hola Mundo'), findsOneWidget);
  });
}
