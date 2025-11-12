// lib/services/ingredient_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class IngredientService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mapeo de opciones del menú a nombres de ingredientes en inventario
  static final Map<String, String> _ingredientMapping = {
    // Proteínas
    "Pollo": "Pollo",
    "Cerdo": "Cerdo", 
    "Chicharrón": "Chicharrón",
    "Res": "Res",
    "Tilapia frita": "Tilapia",
    "Posta": "Posta",
    "Bagre frito": "Bagre",
    "Bagre sudado": "Bagre",
    "Trucha frita": "Trucha",
    
    // Bases
    "Arroz porción": "Arroz",
    "Papas": "Papas",
    "Arepa con queso mozzarella": "Arepa",
    
    // Acompañantes
    "Porción de frijol": "Frijol",
    "Ensalada": "Ensalada",
    "Huevo": "Huevo",
    "Porción de aguacate": "Aguacate",
    "Porción de sopa": "Sopa",
    "Consomé de tilapia": "Tilapia",
    "Patacón medio plátano": "Plátano",
    
    // Bebidas
    "Guarapo": "Guarapo",
    "Gaseosa": "Gaseosa",
    "Jugo de guayaba en agua 9oz": "Jugo de guayaba",
    "Jugo de guayaba en leche 9oz": "Jugo de guayaba",
  };

  // Verificar stock de ingredientes para un pedido personalizado
  static Future<Map<String, dynamic>> validateCustomOrderIngredients(
      List<String> selectedIngredients) async {
    try {
      // Obtener todos los ingredientes del inventario
      final ingredientsSnapshot = await _firestore
          .collection('products')
          .where('productType', isEqualTo: 'ingredient')
          .get();

      // Crear mapa de stock disponible
      final ingredientStock = <String, double>{};
      final ingredientIds = <String, String>{};
      
      for (var doc in ingredientsSnapshot.docs) {
        final data = doc.data();
        final ingredientName = data['name'];
        ingredientStock[ingredientName] = (data['stock'] ?? 0).toDouble();
        ingredientIds[ingredientName] = doc.id;
      }

      // Validar cada ingrediente seleccionado
      final missingIngredients = <String>[];
      final lowStockIngredients = <String>[];

      for (var selected in selectedIngredients) {
        final cleanName = _cleanIngredientName(selected);
        final ingredientName = _ingredientMapping[cleanName];
        
        if (ingredientName != null) {
          final availableStock = ingredientStock[ingredientName] ?? 0;
          
          if (availableStock <= 0) {
            missingIngredients.add(ingredientName);
          } else if (availableStock < 2) { // Considerar bajo stock si queda menos de 2 unidades
            lowStockIngredients.add(ingredientName);
          }
        } else {
          print('⚠️ Ingrediente no mapeado: $cleanName');
        }
      }

      // Retornar resultado de validación
      if (missingIngredients.isNotEmpty) {
        return {
          'valid': false,
          'message': 'Ingredientes agotados: ${missingIngredients.join(', ')}',
          'missingIngredients': missingIngredients,
        };
      }

      if (lowStockIngredients.isNotEmpty) {
        return {
          'valid': true,
          'message': 'Advertencia: Bajo stock en: ${lowStockIngredients.join(', ')}',
          'lowStockIngredients': lowStockIngredients,
          'hasLowStockWarning': true,
        };
      }

      return {
        'valid': true,
        'message': 'Stock suficiente para el pedido',
      };
    } catch (e) {
      return {
        'valid': false, 
        'message': 'Error validando ingredientes: $e'
      };
    }
  }

  // Descontar ingredientes usados en pedidos personalizados
  static Future<Map<String, dynamic>> decrementIngredients(List<String> selectedIngredients) async {
    try {
      final batch = _firestore.batch();
      
      // Obtener todos los ingredientes
      final ingredientsSnapshot = await _firestore
          .collection('products')
          .where('productType', isEqualTo: 'ingredient')
          .get();

      final ingredientData = <String, Map<String, dynamic>>{};
      
      for (var doc in ingredientsSnapshot.docs) {
        final data = doc.data();
        final ingredientName = data['name'];
        ingredientData[ingredientName] = {
          'id': doc.id,
          'stock': (data['stock'] ?? 0).toDouble(),
          'minStock': (data['minStock'] ?? 0).toDouble(),
        };
      }

      final updatedIngredients = <String>[];
      final lowStockAfterUpdate = <String>[];

      // Contar uso de cada ingrediente
      final ingredientUsage = <String, int>{};
      
      for (var selected in selectedIngredients) {
        final cleanName = _cleanIngredientName(selected);
        final ingredientName = _ingredientMapping[cleanName];
        
        if (ingredientName != null) {
          ingredientUsage[ingredientName] = (ingredientUsage[ingredientName] ?? 0) + 1;
        }
      }

      // Aplicar descuentos
      for (var entry in ingredientUsage.entries) {
        final ingredientName = entry.key;
        final usageCount = entry.value;
        final data = ingredientData[ingredientName];
        
        if (data != null) {
          final currentStock = data['stock'];
          final minStock = data['minStock'];
          final newStock = currentStock - usageCount;
          
          // Actualizar en batch
          final ingredientRef = _firestore.collection('products').doc(data['id']);
          batch.update(ingredientRef, {
            'stock': newStock,
            'lastUpdated': DateTime.now(),
          });
          
          updatedIngredients.add('$ingredientName: $currentStock → $newStock');
          
          // Verificar si queda bajo stock después del descuento
          if (newStock <= minStock) {
            lowStockAfterUpdate.add(ingredientName);
          }
        }
      }

      await batch.commit();

      return {
        'success': true,
        'message': 'Ingredientes actualizados: ${updatedIngredients.join(', ')}',
        'updatedIngredients': updatedIngredients,
        'lowStockAfterUpdate': lowStockAfterUpdate,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Error actualizando ingredientes: $e',
      };
    }
  }

  // Obtener reporte de stock de ingredientes
  static Future<List<Map<String, dynamic>>> getIngredientStockReport() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('productType', isEqualTo: 'ingredient')
          .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'name': data['name'],
          'stock': (data['stock'] ?? 0).toDouble(),
          'minStock': (data['minStock'] ?? 0).toDouble(),
          'unit': data['unit'] ?? 'unidades',
          'isLowStock': (data['stock'] ?? 0) <= (data['minStock'] ?? 0),
          'category': data['category'] ?? '',
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo reporte de ingredientes: $e');
      return [];
    }
  }

  // Reponer stock de un ingrediente
  static Future<void> restockIngredient(String ingredientId, double quantity) async {
    try {
      await _firestore.collection('products').doc(ingredientId).update({
        'stock': FieldValue.increment(quantity),
        'lastUpdated': DateTime.now(),
      });
    } catch (e) {
      print('Error reponiendo ingrediente: $e');
      rethrow;
    }
  }

  // Helper para limpiar nombres de ingredientes (remover precios)
  static String _cleanIngredientName(String ingredientWithPrice) {
    return ingredientWithPrice.replaceAll(RegExp(r'\s*\(\$\d+\)'), '');
  }

  // Obtener el mapeo de ingredientes (para debugging)
  static Map<String, String> getIngredientMapping() {
    return Map.from(_ingredientMapping);
  }

  // Verificar si un ingrediente específico tiene stock
  static Future<bool> checkIngredientStock(String ingredientName, {double requiredQuantity = 1}) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('productType', isEqualTo: 'ingredient')
          .where('name', isEqualTo: ingredientName)
          .get();

      if (snapshot.docs.isEmpty) return false;
      
      final stock = (snapshot.docs.first.data()['stock'] ?? 0).toDouble();
      return stock >= requiredQuantity;
    } catch (e) {
      print('Error verificando stock de $ingredientName: $e');
      return false;
    }
  }
}