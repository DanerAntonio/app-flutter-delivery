import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ✅ ESTA LÍNEA FALTABA

class FirebaseDebugger extends StatefulWidget {
  @override
  _FirebaseDebuggerState createState() => _FirebaseDebuggerState();
}

class _FirebaseDebuggerState extends State<FirebaseDebugger> {
  String debugText = 'Iniciando diagnóstico...';
  bool firebaseReady = false;

  @override
  void initState() {
    super.initState();
    _diagnoseFirebase();
  }

  Future<void> _diagnoseFirebase() async {
    List<String> logs = [];
    
    try {
      logs.add('🔍 PASO 1: Verificando WidgetsBinding...');
      WidgetsFlutterBinding.ensureInitialized();
      logs.add('✅ WidgetsBinding OK');

      await Future.delayed(Duration(milliseconds: 100));

      logs.add('🔍 PASO 2: Verificando archivo google-services.json...');
      // Verificar si el archivo existe (esto es simbólico)
      logs.add('📁 Archivo google-services.json: PRESUNTO EXISTE');

      await Future.delayed(Duration(milliseconds: 100));

      logs.add('🔍 PASO 3: Intentando inicializar Firebase...');
      
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        logs.add('✅ Firebase con options: INICIALIZADO CORRECTAMENTE');
        firebaseReady = true;
      } catch (e) {
        logs.add('❌ Firebase con options: FALLÓ - $e');
        
        logs.add('🔍 PASO 4: Intentando sin options...');
        try {
          await Firebase.initializeApp();
          logs.add('✅ Firebase sin options: INICIALIZADO');
          firebaseReady = true;
        } catch (e2) {
          logs.add('❌ Firebase sin options: FALLÓ - $e2');
          
          logs.add('🔍 PASO 5: Verificando plataforma...');
          logs.add('📱 Plataforma: ${DefaultFirebaseOptions.currentPlatform}');
        }
      }

    } catch (e) {
      logs.add('💥 ERROR CRÍTICO: $e');
    }

    setState(() {
      debugText = logs.join('\n');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Diagnóstico Firebase')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'DEBUG FIREBASE',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                debugText,
                style: TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _diagnoseFirebase,
              child: Text('REPETIR DIAGNÓSTICO'),
            ),
            SizedBox(height: 20),
            Text(
              firebaseReady ? '✅ FIREBASE LISTO' : '❌ FIREBASE FALLANDO',
              style: TextStyle(
                fontSize: 20,
                color: firebaseReady ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}