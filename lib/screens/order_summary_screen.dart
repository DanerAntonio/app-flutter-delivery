// order_summary_screen.dart COMPLETO Y CORREGIDO
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../providers/order_provider.dart';
import '../services/store_service.dart';
import 'home_screen.dart';

class OrderSummaryScreen extends StatefulWidget {
  const OrderSummaryScreen({super.key});

  @override
  State<OrderSummaryScreen> createState() => _OrderSummaryScreenState();
}

class _OrderSummaryScreenState extends State<OrderSummaryScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final addressController = TextEditingController();
  final floorController = TextEditingController();
  final noteController = TextEditingController();

  bool isLoading = false;
  String paymentMethod = 'efectivo';
  XFile? comprobanteFile;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadUserData();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          nameController.text = data['name'] ?? '';
          addressController.text = data['address'] ?? '';
          floorController.text = data['floor'] ?? '';
        });
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    nameController.dispose();
    addressController.dispose();
    floorController.dispose();
    noteController.dispose();
    super.dispose();
  }

  // FUNCIÓN CRÍTICA: Generar código de verificación
  String _generateVerificationCode() {
    final random = Random();
    return '${random.nextInt(9)}${random.nextInt(9)}${random.nextInt(9)}${random.nextInt(9)}';
  }

  Future<void> _pickComprobante() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 800,
    );
    
    if (file != null) {
      setState(() => comprobanteFile = file);
    }
  }

  Future<String?> _uploadComprobante(String orderId) async {
    if (comprobanteFile == null) return null;
    
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('comprobantes')
          .child('$orderId.jpg');
      
      await ref.putFile(File(comprobanteFile!.path));
      return await ref.getDownloadURL();
    } catch (e) {
      print('Error uploading comprobante: $e');
      return null;
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Text(message),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _confirmClearCart(OrderProvider orderProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.delete_forever, color: Theme.of(context).colorScheme.error),
            const SizedBox(width: 12),
            const Text('Vaciar Carrito'),
          ],
        ),
        content: const Text('¿Estás seguro de que deseas vaciar tu carrito?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              orderProvider.clearCart();
              Navigator.pop(context);
              _showSnackBar('Carrito vaciado correctamente', true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Vaciar'),
          ),
        ],
      ),
    );
  }

  Future<double> _getDeliveryFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery')
          .get();
      
      if (doc.exists) {
        return (doc.data()?['fee'] ?? 4000).toDouble();
      }
    } catch (e) {
      print('Error getting delivery fee: $e');
    }
    return 4000;
  }

  // ✅ MÉTODO CORREGIDO: Validar stock EXCLUYENDO pedidos personalizados
  Future<Map<String, dynamic>> _validateStock(List<dynamic> cartItems) async {
    try {
      final inventorySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .get();
      
      final inventory = Map<String, int>.fromEntries(
        inventorySnapshot.docs.map((doc) {
          final data = doc.data();
          return MapEntry(doc.id, (data['stock'] ?? 0) as int);
        }),
      );

      for (var item in cartItems) {
        final productId = item['id'];
        final requestedQty = item['quantity'] as int;
        final productName = item['name'] ?? 'Producto';

        // ✅ EXCLUIR PEDIDOS PERSONALIZADOS DE LA VALIDACIÓN
        if (productName == "Pedido Personalizado" || 
            item['category'] == "Personalizado" ||
            productId.startsWith('custom_')) {
          print('✅ Saltando validación para pedido personalizado: $productName');
          continue;
        }

        // Solo validar productos que existen en Firebase
        if (productId.startsWith('temp_') || !productId.contains('_')) {
          print('✅ Saltando validación para producto temporal: $productName');
          continue;
        }

        final availableStock = inventory[productId] ?? 0;

        print('🔍 Validando: $productName - Stock: $availableStock, Necesario: $requestedQty');

        if (availableStock < requestedQty) {
          return {
            'valid': false,
            'message': 'Stock insuficiente para $productName. Disponible: $availableStock, Necesitas: $requestedQty',
          };
        }
      }

      return {'valid': true, 'message': 'Stock válido'};
    } catch (e) {
      print('❌ Error en _validateStock: $e');
      return {
        'valid': true, // ✅ En caso de error, permitir el pedido
        'message': 'Error validando stock, continuando con el pedido'
      };
    }
  }

  // ✅ MÉTODO CORREGIDO: Decrementar stock EXCLUYENDO pedidos personalizados
// ✅ MÉTODO CORREGIDO: Decrementar stock incluyendo items personalizados
Future<void> _decrementStock(List<dynamic> cartItems) async {
  try {
    final batch = FirebaseFirestore.instance.batch();

    for (var item in cartItems) {
      final productId = item['id'];
      final productName = item['name'] ?? 'Producto';
      final customItems = item['customItems'] as List<dynamic>?;

      // ✅ NUEVO: Manejar items personalizados
      if (customItems != null && customItems.isNotEmpty) {
        for (var customItem in customItems) {
          final itemName = customItem['nombre']?.toString() ?? '';
          final quantity = customItem['cantidad'] as int? ?? 1;
          
          // Buscar el producto real por nombre
          final productsSnapshot = await FirebaseFirestore.instance
              .collection('products')
              .where('name', isEqualTo: _extractProductName(itemName))
              .get();

          if (productsSnapshot.docs.isNotEmpty) {
            final productDoc = productsSnapshot.docs.first;
            final currentStock = (productDoc.data()['stock'] ?? 0).toDouble();
            final newStock = currentStock - quantity;
            
            batch.update(productDoc.reference, {
              'stock': newStock > 0 ? newStock : 0,
              'lastUpdated': Timestamp.now(),
            });

            print('📦 Stock actualizado (personalizado): ${_extractProductName(itemName)} - De $currentStock a $newStock');
          }
        }
      } 
      // Productos normales
      else if (productName != "Pedido Personalizado" && 
               !productId.startsWith('custom_') &&
               !productId.startsWith('temp_') && 
               productId.contains('_')) {
        
        final productRef = FirebaseFirestore.instance
            .collection('products')
            .doc(productId);
        
        try {
          final doc = await productRef.get();
          if (doc.exists) {
            final currentStock = (doc.data()?['stock'] ?? 0).toDouble();
            final quantity = item['quantity'] as int? ?? 1;
            final newStock = currentStock - quantity;
            
            batch.update(productRef, {
              'stock': newStock > 0 ? newStock : 0,
              'lastUpdated': Timestamp.now(),
            });

            print('📦 Stock actualizado: $productName - De $currentStock a $newStock');
          }
        } catch (e) {
          print('❌ Error actualizando stock de $productName: $e');
        }
      }
    }

    await batch.commit();
    print('✅ Stock actualizado exitosamente');

  } catch (e) {
    print('❌ Error en _decrementStock: $e');
  }
}

// ✅ NUEVO: Extraer nombre del producto del string del pedido personalizado
String _extractProductName(String itemName) {
  // Ejemplo: "Chicharrón (\$5000) x2" -> "Chicharrón"
  return itemName.replaceAll(RegExp(r'\s*\(\$.*\)\s*x\d+'), '').trim();
}
  // ✅ MÉTODO DE EMERGENCIA: Enviar pedido sin validación de stock
  Future<void> _submitOrderWithoutValidation(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final products = orderProvider.cartItems;

    if (user == null) {
      _showSnackBar('Debes iniciar sesión para realizar un pedido', false);
      return;
    }

    if (products.isEmpty) {
      _showSnackBar('Tu carrito está vacío', false);
      return;
    }

    if (paymentMethod == 'transferencia' && comprobanteFile == null) {
      _showSnackBar('Debes subir el comprobante de transferencia', false);
      return;
    }

    final isOpen = await StoreService.getCurrentStatus();
    if (!isOpen) {
      _showSnackBar('⛔ La tienda está cerrada en este momento', false);
      return;
    }

    final deliveryFee = await _getDeliveryFee();
    final totalConDomicilio = orderProvider.totalPrice + deliveryFee;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 12),
            const Text('Confirmar Pedido (Sin Validación)'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚠️  EN MODO EMERGENCIA\n\n'
              'Se omitirá la validación de stock.\n'
              '¿Continuar con el pedido?',
              style: TextStyle(color: Colors.orange),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Productos:'),
                      Text('\$${orderProvider.totalPrice.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Domicilio:'),
                      Text('\$${deliveryFee.toStringAsFixed(0)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${totalConDomicilio.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);

    try {
      String userName = nameController.text.trim();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        userName = userDoc.data()?['name'];
      }

      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderId = orderRef.id;
      final comprobanteUrl = await _uploadComprobante(orderId);
      
      // GENERAR CÓDIGO DE VERIFICACIÓN
      final verificationCode = _generateVerificationCode();

      // DATOS DEL PEDIDO
      final orderData = {
        'orderNumber': "PED-${DateTime.now().millisecondsSinceEpoch}",
        'userId': user.uid,
        'userName': userName,
        'address': addressController.text.trim(),
        'floor': floorController.text.trim(),
        'note': noteController.text.trim(),
        'products': products.map((p) => p.toMap()).toList(),
        'subtotal': orderProvider.totalPrice,
        'deliveryFee': deliveryFee,
        'total': totalConDomicilio,
        'status': 'pendiente',
        'paymentMethod': paymentMethod,
        'comprobanteUrl': comprobanteUrl,
        'verificationCode': verificationCode,
        'isVerified': false,
        'stockValidationBypassed': true, // ✅ Marcar que se saltó la validación
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await orderRef.set(orderData);
      
      // ✅ ACTUALIZAR STOCK (excluyendo pedidos personalizados)
      await _decrementStock(products.map((p) => p.toMap()).toList());
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': userName,
        'address': addressController.text.trim(),
        'floor': floorController.text.trim(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      orderProvider.clearCart();

      if (mounted) {
        await _showSuccessDialog(verificationCode);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al enviar pedido: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  // FUNCIÓN PRINCIPAL CORREGIDA
  Future<void> _submitOrder(BuildContext context) async {
    if (!_formKey.currentState!.validate()) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final products = orderProvider.cartItems;

    if (user == null) {
      _showSnackBar('Debes iniciar sesión para realizar un pedido', false);
      return;
    }

    if (products.isEmpty) {
      _showSnackBar('Tu carrito está vacío', false);
      return;
    }

    if (paymentMethod == 'transferencia' && comprobanteFile == null) {
      _showSnackBar('Debes subir el comprobante de transferencia', false);
      return;
    }

    final isOpen = await StoreService.getCurrentStatus();
    if (!isOpen) {
      _showSnackBar('⛔ La tienda está cerrada en este momento', false);
      return;
    }

    // ✅ VALIDAR STOCK (excluyendo pedidos personalizados)
    final stockValidation = await _validateStock(
      products.map((p) => p.toMap()).toList(),
    );

    if (!(stockValidation['valid'] as bool)) {
      // Mostrar opción de emergencia
      final useEmergency = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 12),
              Text('Stock Insuficiente'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(stockValidation['message'] as String),
              const SizedBox(height: 16),
              const Text(
                '¿Deseas enviar el pedido de todas formas?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text('Enviar de Todas Formas'),
            ),
          ],
        ),
      );

      if (useEmergency != true) {
        return;
      }
      // Si elige emergencia, usar el método sin validación
      await _submitOrderWithoutValidation(context);
      return;
    }

    final deliveryFee = await _getDeliveryFee();
    final totalConDomicilio = orderProvider.totalPrice + deliveryFee;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.shopping_cart_checkout, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Confirmar Pedido'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('¿Estás seguro de que quieres enviar este pedido?'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Productos:'),
                      Text('\$${orderProvider.totalPrice.toStringAsFixed(0)}'),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Domicilio:'),
                      Text('\$${deliveryFee.toStringAsFixed(0)}'),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '\$${totalConDomicilio.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isLoading = true);

    try {
      String userName = nameController.text.trim();
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
          
      if (userDoc.exists && userDoc.data()?['name'] != null) {
        userName = userDoc.data()?['name'];
      }

      final orderRef = FirebaseFirestore.instance.collection('orders').doc();
      final orderId = orderRef.id;
      final comprobanteUrl = await _uploadComprobante(orderId);
      
      final verificationCode = _generateVerificationCode();

      final orderData = {
        'orderNumber': "PED-${DateTime.now().millisecondsSinceEpoch}",
        'userId': user.uid,
        'userName': userName,
        'address': addressController.text.trim(),
        'floor': floorController.text.trim(),
        'note': noteController.text.trim(),
        'products': products.map((p) => p.toMap()).toList(),
        'subtotal': orderProvider.totalPrice,
        'deliveryFee': deliveryFee,
        'total': totalConDomicilio,
        'status': 'pendiente',
        'paymentMethod': paymentMethod,
        'comprobanteUrl': comprobanteUrl,
        'verificationCode': verificationCode,
        'isVerified': false,
        'createdAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      };

      await orderRef.set(orderData);
      
      // ✅ ACTUALIZAR STOCK (excluyendo pedidos personalizados)
      await _decrementStock(products.map((p) => p.toMap()).toList());
      
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': userName,
        'address': addressController.text.trim(),
        'floor': floorController.text.trim(),
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));

      orderProvider.clearCart();

      if (mounted) {
        await _showSuccessDialog(verificationCode);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al enviar pedido: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _showSuccessDialog(String verificationCode) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('Pedido Confirmado'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.celebration, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            const Text(
              '¡Pedido enviado exitosamente!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // CÓDIGO DE VERIFICACIÓN
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'Código de Verificación',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    verificationCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 8,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Entrega este código al repartidor para confirmar la entrega o vuelve a consultar caundo te entreguen el peidido.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            const Text(
              'Te contactaremos pronto para confirmar tu pedido.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  // ... (el resto del código permanece igual - _buildStoreStatus, _buildProductItem, etc.)
  // [Mantén todo el código de los métodos de UI que ya tienes]

  Widget _buildStoreStatus() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: StoreService.stream(),
      builder: (context, snapshot) {
        final isOpen = StoreService.isOpenNow(snapshot.data);
        
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isOpen ? Colors.green.shade50 : Colors.orange.shade50,
            border: Border.all(
              color: isOpen ? Colors.green.shade200 : Colors.orange.shade200,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                isOpen ? Icons.storefront : Icons.store_mall_directory,
                color: isOpen ? Colors.green.shade600 : Colors.orange.shade600,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isOpen ? 'Tienda Abierta' : 'Tienda Cerrada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isOpen ? Colors.green.shade700 : Colors.orange.shade700,
                      ),
                    ),
                    Text(
                      isOpen 
                          ? 'Puedes enviar tu pedido' 
                          : 'No se pueden enviar pedidos en este momento',
                      style: TextStyle(
                        color: isOpen ? Colors.green.shade600 : Colors.orange.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductItem(Map<String, dynamic> product) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          child: Text(
            product['quantity'].toString(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        title: Text(
          product['name'],
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: product['selectedOptions'] != null && 
                 (product['selectedOptions'] as List).isNotEmpty
            ? Text(
                'Opciones: ${(product['selectedOptions'] as List).join(', ')}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              )
            : null,
        trailing: Text(
          '\$${(product['price'] * product['quantity']).toStringAsFixed(0)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Método de Pago',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption(
              value: 'efectivo',
              title: 'Efectivo al recibir',
              subtitle: 'Paga cuando recibas tu pedido',
              icon: Icons.money,
            ),
            _buildPaymentOption(
              value: 'transferencia',
              title: 'Transferencia Bancaria ',
              subtitle: 'Transfiere antes de enviar el pedido (Cuenta de ahorros Bancolombia: 01256806602)(Nequi: 3112762618)',
              icon: Icons.account_balance,
            ),
           
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: paymentMethod == value 
              ? Theme.of(context).colorScheme.primary 
              : Colors.grey.shade300,
          width: paymentMethod == value ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: paymentMethod == value 
            ? Theme.of(context).colorScheme.primary.withOpacity(0.05)
            : Colors.transparent,
      ),
      child: RadioListTile(
        value: value,
        groupValue: paymentMethod,
        onChanged: (value) => setState(() => paymentMethod = value!),
        title: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
          ],
        ),
        controlAffinity: ListTileControlAffinity.trailing,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final products = orderProvider.cartItems;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        title: const Text(
          "Confirmar Pedido",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (products.isNotEmpty)
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.delete_forever, size: 20, color: Colors.white),
              ),
              tooltip: "Vaciar carrito",
              onPressed: () => _confirmClearCart(orderProvider),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: _buildStoreStatus(),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      // Resumen de productos CON DELIVERY FEE DINÁMICO
                      StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('settings')
                            .doc('delivery')
                            .snapshots(),
                        builder: (context, snapshot) {
                          double deliveryFee = 4000;
                          
                          if (snapshot.hasData && snapshot.data!.exists) {
                            deliveryFee = (snapshot.data!.data() as Map<String, dynamic>)['fee']?.toDouble() ?? 4000;
                          }

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(Icons.shopping_cart, color: theme.colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Resumen del Pedido",
                                        style: theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  if (products.isEmpty)
                                    const Text(
                                      "Tu carrito está vacío",
                                      style: TextStyle(color: Colors.grey),
                                    )
                                  else
                                    Column(
                                      children: products.map((p) => _buildProductItem({
                                        'name': p.name,
                                        'price': p.price,
                                        'quantity': p.quantity,
                                        'selectedOptions': p.selectedOptions,
                                      })).toList(),
                                    ),
                                  if (products.isNotEmpty) ...[
                                    const SizedBox(height: 12),
                                    Divider(color: Colors.grey.shade300),
                                    const SizedBox(height: 8),
                                    
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "Subtotal productos:",
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        Text(
                                          "\$${orderProvider.totalPrice.toStringAsFixed(0)}",
                                          style: theme.textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.blue.shade50,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.blue.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.delivery_dining, color: Colors.blue.shade700, size: 20),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Costo de domicilio',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: Colors.blue.shade800,
                                                  ),
                                                ),
                                                Text(
                                                  'Apoya a tu repartidor',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors.blue.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Text(
                                            "\$${deliveryFee.toStringAsFixed(0)}",
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 12),
                                    Divider(color: Colors.grey.shade400, thickness: 1.5),
                                    const SizedBox(height: 8),

                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "Total a pagar:",
                                              style: theme.textTheme.titleMedium?.copyWith(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              "Incluye domicilio",
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          "\$${(orderProvider.totalPrice + deliveryFee).toStringAsFixed(0)}",
                                          style: theme.textTheme.titleLarge?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: theme.colorScheme.primary,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 16),

                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.location_on, color: theme.colorScheme.primary),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Información de Entrega",
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildFormField(
                                controller: nameController,
                                label: "Nombre completo",
                                icon: Icons.person,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Nombre requerido";
                                  }
                                  if (value.trim().length < 3) {
                                    return "Debe tener al menos 3 caracteres";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildFormField(
                                controller: addressController,
                                label: "Dirección de entrega",
                                icon: Icons.home,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return "Dirección requerida";
                                  }
                                  if (value.trim().length < 5) {
                                    return "Dirección demasiado corta";
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              _buildFormField(
                                controller: floorController,
                                label: "Piso o Apartamento (opcional)",
                                icon: Icons.meeting_room,
                              ),
                              const SizedBox(height: 12),
                              _buildFormField(
                                controller: noteController,
                                label: "Notas adicionales (opcional)",
                                icon: Icons.note,
                                maxLines: 3,
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildPaymentMethodSelector(),

                      if (paymentMethod == 'transferencia') ...[
                        const SizedBox(height: 16),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Comprobante de Transferencia",
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ElevatedButton.icon(
                                  onPressed: _pickComprobante,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(comprobanteFile != null
                                      ? "Comprobante seleccionado"
                                      : "Seleccionar comprobante"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade50,
                                    foregroundColor: Colors.blue.shade700,
                                  ),
                                ),
                                if (comprobanteFile != null) ...[
                                  const SizedBox(height: 12),
                                  Container(
                                    height: 150,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey.shade300),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(comprobanteFile!.path),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                        stream: StoreService.stream(),
                        builder: (context, snapshot) {
                          final isOpen = StoreService.isOpenNow(snapshot.data);

                          return SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton.icon(
                              onPressed: (products.isEmpty || isLoading || !isOpen)
                                  ? null
                                  : () => _submitOrder(context),
                              icon: isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.send),
                              label: isLoading
                                  ? const Text('Procesando...')
                                  : Text(isOpen ? "Enviar Pedido" : "Tienda Cerrada"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isOpen && !isLoading
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
      maxLines: maxLines,
    );
  }
}