import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_product.dart';

class InventoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'products';

  /// ✅ NUEVO: Limpiar nombre de producto (quitar precios y espacios extra)
  static String _cleanProductName(String productName) {
    // Remover precios como ($5000), ($10000), etc.
    String cleaned = productName.replaceAll(RegExp(r'\s*\(\$\d+\)'), '');
    // Remover espacios extra
    cleaned = cleaned.trim();
    return cleaned;
  }


  /// Obtener todos los productos del inventario
  static Stream<List<InventoryProduct>> getProductsStream() {
    return _firestore
        .collection(_collection)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return InventoryProduct.fromMap(data).copyWith(id: doc.id);
      }).toList();
    });
  }

  /// Obtener un producto específico por ID
  static Future<InventoryProduct?> getProductById(String productId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(productId).get();
      if (doc.exists) {
        final data = doc.data()!;
        return InventoryProduct.fromMap(data).copyWith(id: doc.id);
      }
      return null;
    } catch (e) {
      print('❌ Error getting product by ID: $e');
      return null;
    }
  }

  /// ✅ MEJORADO: Buscar producto por nombre (ahora limpia el nombre primero)
  static Future<InventoryProduct?> getProductByName(String productName) async {
    try {
      // Limpiar el nombre antes de buscar
      final cleanName = _cleanProductName(productName);
      
      print('🔍 Buscando producto: "$productName" → limpio: "$cleanName"');
      
      // Buscar por nombre exacto (limpio)
      final query = await _firestore
          .collection(_collection)
          .where('name', isEqualTo: cleanName)
          .limit(1)
          .get();
      
      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        final data = doc.data();
        print('✅ Producto encontrado: $cleanName');
        return InventoryProduct.fromMap(data).copyWith(id: doc.id);
      }
      
      print('⚠️ Producto no encontrado en inventario: $cleanName');
      return null;
    } catch (e) {
      print('❌ Error getting product by name: $e');
      return null;
    }
  }

  /// Descontar stock cuando se entrega un pedido
  static Future<bool> decreaseStock(String productName, double quantity) async {
    try {
      final product = await getProductByName(productName);
      if (product == null) {
        print('⚠️ Product not found: $productName - Skipping stock decrease');
        // No fallar si el producto no está en inventario (puede ser personalizado)
        return true;
      }

      final newStock = product.stock - quantity;
      
      // No permitir stock negativo
      if (newStock < 0) {
        print('❌ Insufficient stock for ${product.name}. Available: ${product.stock}, Required: $quantity');
        return false;
      }

      await _firestore.collection(_collection).doc(product.id).update({
        'stock': newStock,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Stock updated for ${product.name}: ${product.stock} → $newStock');
      return true;
    } catch (e) {
      print('❌ Error decreasing stock: $e');
      return false;
    }
  }

  /// Aumentar stock (para reposiciones o correcciones)
  static Future<bool> increaseStock(String productId, double quantity) async {
    try {
      final product = await getProductById(productId);
      if (product == null) {
        print('❌ Product not found: $productId');
        return false;
      }

      final newStock = product.stock + quantity;

      await _firestore.collection(_collection).doc(productId).update({
        'stock': newStock,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });

      print('✅ Stock increased for ${product.name}: ${product.stock} → $newStock');
      return true;
    } catch (e) {
      print('❌ Error increasing stock: $e');
      return false;
    }
  }

  /// Actualizar stock directamente
  static Future<bool> updateStock(String productId, double newStock) async {
    try {
      await _firestore.collection(_collection).doc(productId).update({
        'stock': newStock,
        'lastUpdated': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('❌ Error updating stock: $e');
      return false;
    }
  }

  /// ✅ MEJORADO: Verificar disponibilidad de stock con validación inteligente
  static Future<bool> checkStockAvailability(List<Map<String, dynamic>> products) async {
    try {
      print('📦 Checking stock availability for ${products.length} products');
      
      for (final productData in products) {
        final productName = productData['name'];
        final quantity = (productData['quantity'] ?? 1).toDouble();
        
        print('  🔍 Checking: $productName (qty: $quantity)');
        
        final product = await getProductByName(productName);
        
        if (product == null) {
          print('  ⚠️ Product not in inventory: $productName - Allowing (custom product)');
          continue; // Permitir productos personalizados que no están en inventario
        }

        // Solo validar stock para productos que SÍ están en inventario
        if (product.stock < quantity) {
          print('  ❌ INSUFFICIENT STOCK for ${product.name}');
          print('     Available: ${product.stock} ${product.unit}');
          print('     Required: $quantity ${product.unit}');
          return false;
        }
        
        print('  ✅ Stock OK for ${product.name}: ${product.stock} ${product.unit}');
      }
      
      print('✅ All products have sufficient stock');
      return true;
    } catch (e) {
      print('❌ Error checking stock availability: $e');
      // En caso de error, permitir el pedido (no bloquear por errores técnicos)
      return true;
    }
  }

  /// ✅ MEJORADO: Procesar descuento de stock con mejor manejo de errores
  static Future<bool> processOrderStockDecrease(List<Map<String, dynamic>> products) async {
    try {
      print('📦 Processing stock decrease for order');
      
      // Primero verificar disponibilidad
      final hasStock = await checkStockAvailability(products);
      if (!hasStock) {
        print('❌ Order blocked: Insufficient stock');
        return false;
      }

      // Procesar cada producto
      bool allSuccess = true;
      for (final productData in products) {
        final productName = productData['name'];
        final quantity = (productData['quantity'] ?? 1).toDouble();
        
        final success = await decreaseStock(productName, quantity);
        if (!success) {
          print('⚠️ Failed to decrease stock for $productName');
          allSuccess = false;
          // Continuar procesando otros productos
        }
      }

      if (allSuccess) {
        print('✅ Stock decrease completed successfully');
      } else {
        print('⚠️ Stock decrease completed with some warnings');
      }
      
      return true; // Permitir el pedido incluso si algunos productos no están en inventario
    } catch (e) {
      print('❌ Error processing order stock decrease: $e');
      return true; // No bloquear pedidos por errores técnicos
    }
  }

  /// ✅ NUEVO: Validar stock para pedidos personalizados
  static Future<Map<String, dynamic>> validateCustomOrder(List<String> selectedOptions) async {
    try {
      print('🎨 Validating custom order with ${selectedOptions.length} items');
      
      final Map<String, dynamic> result = {
        'isValid': true,
        'insufficientItems': <String>[],
        'availableItems': <String>[],
        'notInInventory': <String>[],
      };

      for (final option in selectedOptions) {
        final cleanName = _cleanProductName(option);
        final product = await getProductByName(cleanName);
        
        if (product == null) {
          result['notInInventory'].add(option);
          print('  ℹ️ Not in inventory: $option (will allow)');
          continue;
        }

        if (product.stock < 1) {
          result['insufficientItems'].add(option);
          result['isValid'] = false;
          print('  ❌ Insufficient stock: $option');
        } else {
          result['availableItems'].add(option);
          print('  ✅ Available: $option');
        }
      }

      return result;
    } catch (e) {
      print('❌ Error validating custom order: $e');
      // En caso de error, permitir el pedido
      return {
        'isValid': true,
        'insufficientItems': <String>[],
        'availableItems': selectedOptions,
        'notInInventory': <String>[],
      };
    }
  }

  /// Obtener productos con stock bajo
  static Future<List<InventoryProduct>> getLowStockProducts() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final products = snapshot.docs.map((doc) {
        final data = doc.data();
        return InventoryProduct.fromMap(data).copyWith(id: doc.id);
      }).toList();

      return products.where((product) => product.isLowStock).toList();
    } catch (e) {
      print('❌ Error getting low stock products: $e');
      return [];
    }
  }

  /// Crear o actualizar producto
  static Future<bool> saveProduct(InventoryProduct product) async {
    try {
      if (product.id.isEmpty) {
        // Crear nuevo
        await _firestore.collection(_collection).add(product.toMap());
        print('✅ Product created: ${product.name}');
      } else {
        // Actualizar existente
        await _firestore.collection(_collection).doc(product.id).update(product.toMap());
        print('✅ Product updated: ${product.name}');
      }
      return true;
    } catch (e) {
      print('❌ Error saving product: $e');
      return false;
    }
  }

  /// Eliminar producto
  static Future<bool> deleteProduct(String productId) async {
    try {
      await _firestore.collection(_collection).doc(productId).delete();
      print('✅ Product deleted: $productId');
      return true;
    } catch (e) {
      print('❌ Error deleting product: $e');
      return false;
    }
  }

  /// ✅ NUEVO: Obtener solo ingredientes (para pedidos personalizados)
  static Future<List<InventoryProduct>> getIngredients() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productType', isEqualTo: 'ingredient')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return InventoryProduct.fromMap(data).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error getting ingredients: $e');
      return [];
    }
  }

  /// ✅ NUEVO: Obtener solo productos terminados
  static Future<List<InventoryProduct>> getFinishedProducts() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('productType', isEqualTo: 'finishedProduct')
          .get();
      
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return InventoryProduct.fromMap(data).copyWith(id: doc.id);
      }).toList();
    } catch (e) {
      print('❌ Error getting finished products: $e');
      return [];
    }
  }
}