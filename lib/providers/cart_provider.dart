import 'package:cloud_firestore/cloud_firestore.dart';

class StoreService {
  static final DocumentReference _doc =
      FirebaseFirestore.instance.collection('settings').doc('store');

  /// Escuchar cambios de estado de la tienda
  static Stream<Map<String, dynamic>?> stream() {
    return _doc.snapshots().map(
          (snap) => snap.exists ? (snap.data() as Map<String, dynamic>?) : null,
        );
  }

  /// Obtener estado una sola vez
  static Future<Map<String, dynamic>?> getOnce() async {
    final snap = await _doc.get();
    return snap.exists ? (snap.data() as Map<String, dynamic>?) : null;
  }

  /// Cambiar estado manual
  static Future<void> setManualOpen(bool open) {
    return _doc.set(
      {'mode': 'manual', 'manualIsOpen': open},
      SetOptions(merge: true),
    );
  }

  /// Ver si está abierta ahora
  static bool isOpenNow(Map<String, dynamic>? data) {
    if (data == null) return true;
    if (data['mode'] == 'manual') {
      return (data['manualIsOpen'] ?? true) == true;
    }
    return true; // si luego hacemos horarios automáticos
  }
}
