import 'package:cloud_firestore/cloud_firestore.dart';

class StoreService {
  static final DocumentReference _doc =
      FirebaseFirestore.instance.collection('settings').doc('store');

  /// Escuchar cambios de estado de la tienda
  static Stream<DocumentSnapshot<Map<String, dynamic>>> stream() {
    return _doc.snapshots() as Stream<DocumentSnapshot<Map<String, dynamic>>>;
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

  /// Ver si está abierta ahora (método mejorado)
  static bool isOpenNow(DocumentSnapshot<Map<String, dynamic>>? snapshot) {
    if (snapshot == null || !snapshot.exists) return true;
    
    final data = snapshot.data();
    if (data == null) return true;
    
    if (data['mode'] == 'manual') {
      return (data['manualIsOpen'] ?? true) == true;
    }
    return true;
  }

  /// Método alternativo para obtener el estado actual directamente
  static Future<bool> getCurrentStatus() async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) return true;
      
      final data = snap.data() as Map<String, dynamic>?;
      if (data == null) return true;
      
      if (data['mode'] == 'manual') {
        return (data['manualIsOpen'] ?? true) == true;
      }
      return true;
    } catch (e) {
      print('Error getting store status: $e');
      return true;
    }
  }

  /// Asegurar que el documento existe con valores por defecto
  static Future<void> ensureDocExists({bool defaultOpen = true}) async {
    try {
      final snap = await _doc.get();
      if (!snap.exists) {
        await _doc.set({
          'mode': 'manual',
          'manualIsOpen': defaultOpen,
          'createdAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error ensuring store doc exists: $e');
    }
  }

  /// NUEVA FUNCIÓN: Inicializar configuración de domicilio
  static Future<void> ensureDeliveryConfigExists() async {
    try {
      final deliveryDoc = FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery');
      
      final snap = await deliveryDoc.get();
      if (!snap.exists) {
        await deliveryDoc.set({
          'fee': 4000,
          'driverPercentage': 100,
          'createdAt': Timestamp.now(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error ensuring delivery config exists: $e');
    }
  }

  /// NUEVA FUNCIÓN: Obtener el costo de domicilio actual
  static Future<double> getDeliveryFee() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery')
          .get();
      
      if (snap.exists) {
        return (snap.data()?['fee'] ?? 4000).toDouble();
      }
    } catch (e) {
      print('Error getting delivery fee: $e');
    }
    return 4000;
  }
}