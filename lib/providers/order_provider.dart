// ORDER PROVIDER COMPLETO Y CORREGIDO CON VERIFICACIÓN DE USUARIO
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';
import '../services/courier_credit_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderProvider with ChangeNotifier {
  final List<Product> _cartItems = [];

  List<Product> get cartItems => List.unmodifiable(_cartItems);

  int get itemCount => _cartItems.fold(0, (total, item) => total + item.quantity);

  double get totalPrice => _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  // 🔹 ADD TO CART CON VERIFICACIÓN DE USUARIO
  void addToCart(Product product, [BuildContext? context]) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null && context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debes iniciar sesión para agregar productos al carrito.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    try {
      final index = _cartItems.indexWhere((p) => p.id == product.id);
      if (index >= 0) {
        _cartItems[index] = Product(
          id: _cartItems[index].id,
          name: _cartItems[index].name,
          description: _cartItems[index].description,
          price: _cartItems[index].price,
          imageUrl: _cartItems[index].imageUrl,
          category: _cartItems[index].category,
          quantity: _cartItems[index].quantity + product.quantity,
          selectedOptions: _cartItems[index].selectedOptions,
        );
      } else {
        _cartItems.add(Product(
          id: product.id,
          name: product.name,
          description: product.description,
          price: product.price,
          imageUrl: product.imageUrl,
          category: product.category,
          quantity: product.quantity,
          selectedOptions: product.selectedOptions,
        ));
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  void updateQuantity(String productId, int quantity) {
    try {
      final index = _cartItems.indexWhere((p) => p.id == productId);
      if (index >= 0) {
        if (quantity <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index] = Product(
            id: _cartItems[index].id,
            name: _cartItems[index].name,
            description: _cartItems[index].description,
            price: _cartItems[index].price,
            imageUrl: _cartItems[index].imageUrl,
            category: _cartItems[index].category,
            quantity: quantity,
            selectedOptions: _cartItems[index].selectedOptions,
          );
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating quantity: $e');
    }
  }

  void incrementQuantity(String productId) {
    final index = _cartItems.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      updateQuantity(productId, _cartItems[index].quantity + 1);
    }
  }

  void decrementQuantity(String productId) {
    final index = _cartItems.indexWhere((p) => p.id == productId);
    if (index >= 0) {
      updateQuantity(productId, _cartItems[index].quantity - 1);
    }
  }

  void removeFromCart(String productId) {
    try {
      _cartItems.removeWhere((item) => item.id == productId);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
    }
  }

  void clearCart() {
    try {
      _cartItems.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
    }
  }

  int getProductQuantity(String productId) {
    final index = _cartItems.indexWhere((p) => p.id == productId);
    return index >= 0 ? _cartItems[index].quantity : 0;
  }

  bool isProductInCart(String productId) => _cartItems.any((item) => item.id == productId);

  double getProductSubtotal(String productId) {
    final index = _cartItems.indexWhere((p) => p.id == productId);
    if (index >= 0) return _cartItems[index].price * _cartItems[index].quantity;
    return 0.0;
  }

  Future<Map<String, dynamic>> validateStock() async {
    try {
      List<String> outOfStockProducts = [];
      List<String> lowStockProducts = [];

      for (var product in _cartItems) {
        if (product.category == "Personalizado" || 
            product.name == "Pedido Personalizado" ||
            product.id.startsWith('custom_')) {
          debugPrint('✅ Saltando validación para pedido personalizado: ${product.name}');
          continue;
        }

        if (product.id.startsWith('temp_') || !product.id.contains('_')) {
          debugPrint('✅ Saltando validación para producto temporal: ${product.name}');
          continue;
        }

        try {
          final doc = await FirebaseFirestore.instance.collection('products').doc(product.id).get();
          if (doc.exists) {
            final data = doc.data() as Map<String, dynamic>;
            final currentStock = (data['stock'] ?? 0).toDouble();
            final minStock = (data['minStock'] ?? 0).toDouble();
            final productName = data['name'] ?? 'Producto sin nombre';
            final requiredQuantity = product.quantity.toDouble();

            debugPrint('🔍 Validando: $productName - Stock: $currentStock, Necesario: $requiredQuantity');

            if (currentStock <= 0) {
              outOfStockProducts.add(productName);
            } else if (currentStock < requiredQuantity) {
              outOfStockProducts.add('$productName (solo hay $currentStock, necesitas $requiredQuantity)');
            } else if (currentStock < minStock) {
              lowStockProducts.add('$productName ($currentStock disponibles)');
            }
          } else {
            debugPrint('⚠️ Producto no encontrado en Firebase: ${product.name} (ID: ${product.id})');
          }
        } catch (e) {
          debugPrint('❌ Error validando stock de ${product.name}: $e');
        }
      }

      final result = {
        'valid': outOfStockProducts.isEmpty,
        'outOfStock': outOfStockProducts,
        'lowStock': lowStockProducts,
        'message': outOfStockProducts.isNotEmpty
            ? 'Stock insuficiente: ${outOfStockProducts.join(', ')}'
            : lowStockProducts.isNotEmpty
                ? 'Stock bajo: ${lowStockProducts.join(', ')}'
                : 'Stock válido'
      };

      debugPrint('📊 Resultado validación: $result');
      return result;
    } catch (e) {
      debugPrint('❌ Error en validateStock: $e');
      return {
        'valid': true,
        'outOfStock': [],
        'lowStock': [],
        'message': 'Error validando stock, continuando con el pedido'
      };
    }
  }

  Future<Map<String, dynamic>> placeOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String userAddress,
    required String paymentMethod,
    required double deliveryFee,
    String? notes,
  }) async {
    try {
      debugPrint('🚀 Iniciando placeOrder...');

      final stockValidation = await validateStock();
      if (!stockValidation['valid']) {
        debugPrint('❌ Validación de stock falló: ${stockValidation['message']}');
        return {'success': false, 'message': stockValidation['message'], 'orderId': null};
      }

      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderId = orderRef.id;

      final orderData = {
        'id': orderId,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'userAddress': userAddress,
        'items': _cartItems.map((item) => {
          'id': item.id,
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'quantity': item.quantity,
          'selectedOptions': item.selectedOptions,
          'isCustomOrder': item.category == "Personalizado" || item.name == "Pedido Personalizado",
        }).toList(),
        'total': totalPrice + deliveryFee,
        'subtotal': totalPrice,
        'deliveryFee': deliveryFee,
        'paymentMethod': paymentMethod,
        'status': 'pendiente',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'notes': notes ?? '',
      };

      await orderRef.set(orderData);
      await _updateStockForNonCustomProducts();
      clearCart();

      debugPrint('✅ Pedido creado exitosamente: $orderId');
      return {'success': true, 'message': 'Pedido creado exitosamente', 'orderId': orderId};
    } catch (e) {
      debugPrint('❌ Error en placeOrder: $e');
      return {'success': false, 'message': 'Error al crear el pedido: $e', 'orderId': null};
    }
  }

  Future<void> _updateStockForNonCustomProducts() async {
    try {
      final batch = FirebaseFirestore.instance.batch();
      for (var product in _cartItems) {
        if (product.category == "Personalizado" || product.name == "Pedido Personalizado" || product.id.startsWith('custom_')) {
          debugPrint('✅ Saltando actualización de stock para pedido personalizado: ${product.name}');
          continue;
        }

        if (!product.id.startsWith('temp_') && product.id.contains('_')) {
          final productRef = FirebaseFirestore.instance.collection('products').doc(product.id);
          try {
            final doc = await productRef.get();
            if (doc.exists) {
              final currentStock = (doc.data()?['stock'] ?? 0).toDouble();
              final newStock = currentStock - product.quantity;
              batch.update(productRef, {'stock': newStock > 0 ? newStock : 0, 'lastUpdated': Timestamp.now()});
              debugPrint('📦 Stock actualizado: ${product.name} - De $currentStock a $newStock');
            }
          } catch (e) {
            debugPrint('❌ Error actualizando stock de ${product.name}: $e');
          }
        }
      }
      await batch.commit();
      debugPrint('✅ Stock actualizado exitosamente');
    } catch (e) {
      debugPrint('❌ Error en _updateStockForNonCustomProducts: $e');
    }
  }

  Future<Map<String, dynamic>> placeOrderWithoutStockValidation({
    required String userId,
    required String userName,
    required String userPhone,
    required String userAddress,
    required String paymentMethod,
    required double deliveryFee,
    String? notes,
  }) async {
    try {
      debugPrint('🚀 Iniciando placeOrderWithoutStockValidation...');
      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderId = orderRef.id;

      final orderData = {
        'id': orderId,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'userAddress': userAddress,
        'items': _cartItems.map((item) => {
          'id': item.id,
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'imageUrl': item.imageUrl,
          'category': item.category,
          'quantity': item.quantity,
          'selectedOptions': item.selectedOptions,
          'isCustomOrder': item.category == "Personalizado" || item.name == "Pedido Personalizado",
        }).toList(),
        'total': totalPrice + deliveryFee,
        'subtotal': totalPrice,
        'deliveryFee': deliveryFee,
        'paymentMethod': paymentMethod,
        'status': 'pendiente',
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
        'notes': notes ?? '',
        'stockValidationBypassed': true,
      };

      await orderRef.set(orderData);
      clearCart();

      debugPrint('✅ Pedido creado (sin validación): $orderId');
      return {'success': true, 'message': 'Pedido creado exitosamente (validación omitida)', 'orderId': orderId};
    } catch (e) {
      debugPrint('❌ Error en placeOrderWithoutStockValidation: $e');
      return {'success': false, 'message': 'Error al crear el pedido: $e', 'orderId': null};
    }
  }

  Future<void> processDelivery(String orderId) async {
    try {
      final orderDoc = await FirebaseFirestore.instance.collection('orders').doc(orderId).get();
      if (!orderDoc.exists) throw Exception('Pedido no encontrado');

      final orderData = orderDoc.data()!;
      final courierId = orderData['courierId'];
      final paymentMethod = orderData['paymentMethod'] ?? 'transfer';
      final total = (orderData['total'] ?? 0).toDouble();
      final deliveryFee = (orderData['deliveryFee'] ?? 4000).toDouble();

      if (courierId == null) throw Exception('Pedido sin domiciliario asignado');

      await CourierCreditService.registerOrderDelivery(
        courierId: courierId,
        orderId: orderId,
        paymentMethod: paymentMethod,
        totalAmount: total,
        deliveryFee: deliveryFee,
      );

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'courierPaid': true,
        'courierPaymentProcessedAt': Timestamp.now(),
      });

      debugPrint('✅ Entrega procesada correctamente');
    } catch (e) {
      debugPrint('❌ Error procesando entrega: $e');
      rethrow;
    }
  }
}
