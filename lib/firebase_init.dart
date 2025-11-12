import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'firebase_options.dart';

class FirebaseHelper {
  static bool _initialized = false;
  static bool _hasError = false;
  static String _errorMessage = '';

  static Future<void> initialize() async {
    if (_initialized) return;
    
    try {
      print('🔄 Inicializando Firebase...');
      WidgetsFlutterBinding.ensureInitialized();
      
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      
      _initialized = true;
      _hasError = false;
      print('✅ Firebase inicializado correctamente');
    } catch (e) {
      _initialized = false;
      _hasError = true;
      _errorMessage = e.toString();
      print('❌ Error Firebase: $e');
    }
  }

  static bool get isInitialized => _initialized;
  static bool get hasError => _hasError;
  static String get errorMessage => _errorMessage;
}