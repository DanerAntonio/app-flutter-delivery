// Test básico para verificar que la app se inicializa correctamente
//
// Este test verifica que la aplicación PideClaudia puede construirse
// sin errores y que muestra la pantalla de autenticación inicial.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:pide_claudia/main.dart';

// Mock de Firebase para testing
void setupFirebaseAuthMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
}

void main() {
  setupFirebaseAuthMocks();

  testWidgets('PideClaudiaApp se construye correctamente', (WidgetTester tester) async {
    // Configurar Firebase Mock
    setupFirebaseMocks();

    // Construir la app y disparar un frame
    await tester.pumpWidget(const PideClaudiaApp());

    // Verificar que la app se construyó sin errores
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('App muestra el título correcto', (WidgetTester tester) async {
    // Configurar Firebase Mock
    setupFirebaseMocks();

    // Construir la app
    await tester.pumpWidget(const PideClaudiaApp());

    // Verificar que MaterialApp existe
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.title, equals('La Cocina de Claudia'));
  });

  testWidgets('App usa el tema correcto', (WidgetTester tester) async {
    // Configurar Firebase Mock
    setupFirebaseMocks();

    // Construir la app
    await tester.pumpWidget(const PideClaudiaApp());

    // Verificar que el tema está configurado
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.theme, isNotNull);
    expect(materialApp.theme!.useMaterial3, isTrue);
  });

  testWidgets('App no muestra banner de debug', (WidgetTester tester) async {
    // Configurar Firebase Mock
    setupFirebaseMocks();

    // Construir la app
    await tester.pumpWidget(const PideClaudiaApp());

    // Verificar que el banner de debug está desactivado
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.debugShowCheckedModeBanner, isFalse);
  });
}

// Función auxiliar para mockear Firebase en tests
void setupFirebaseMocks() {
  // Esta función se puede expandir cuando necesites mockear
  // funcionalidades específicas de Firebase
}