import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'driver_order_detail_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> with TickerProviderStateMixin {
  String? driverId;
  String? driverName;
  double totalEarnings = 0.0;
  int deliveredCount = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Dirección fija de la tienda
  final String storeAddress = "diagonal 43 avenida 34E-20 torre 4 apartamento 9928 unidad residencial cuarzo en bello Antioquia";
  final String storeName = "La Cocina de Claudia";
  final String storePhone = "+573112762618";
  
  // Controlador para el código de 4 dígitos
  final TextEditingController _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    driverId = FirebaseAuth.instance.currentUser?.uid;
    driverName = FirebaseAuth.instance.currentUser?.displayName ?? 'Repartidor';
    _setupAnimations();
    _loadDriverStats();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
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

  @override
  void dispose() {
    _fadeController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _loadDriverStats() async {
    if (driverId == null) return;
    
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('orders')
          .where('driverId', isEqualTo: driverId)
          .get();

      double total = 0.0;
      int count = 0;
      
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final status = data['status']?.toString().toLowerCase();
        
        if (status == 'entregado' || status == 'cerrado') {
          final deliveryFee = data['deliveryFee']?.toDouble() ?? 0.0;
          total += deliveryFee;
          count++;
        }
      }

      if (mounted) {
        setState(() {
          totalEarnings = total;
          deliveredCount = count;
        });
      }
    } catch (e) {
      print('Error loading driver stats: $e');
    }
  }

  Future<void> _takeOrder(String orderId) async {
    try {
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        _showSnackBar("El pedido ya no existe", false);
        return;
      }

      final data = orderDoc.data();
      final currentDriverId = data?['driverId'];
      final currentStatus = data?['status']?.toString().toLowerCase();

      bool isAvailable = true;
      
      if (currentDriverId != null) {
        if (currentDriverId is String && currentDriverId.isNotEmpty) {
          isAvailable = false;
        }
      }

      if (currentStatus != 'pendiente' && currentStatus != 'confirmado') {
        isAvailable = false;
      }

      if (!isAvailable) {
        _showSnackBar("Este pedido ya fue tomado", false);
        return;
      }

      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'asignado',
        'driverId': driverId,
        'driverName': driverName,
        'assignedAt': Timestamp.now(),
        'deliveryFee': 4000,
        'storeAddress': storeAddress,
        'storeName': storeName,
      });

      _showSnackBar("¡Pedido tomado exitosamente!", true);
      _loadDriverStats();

    } catch (e) {
      print('Error taking order: $e');
      _showSnackBar("Error al tomar el pedido", false);
    }
  }

  // CORREGIDO: Solo verificar código, NO mostrarlo
  Future<void> _verifyDeliveryCode(String orderId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code_scanner, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Verificar Entrega'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pide al cliente que te muestre el código de 4 dígitos de su aplicación e ingrésalo aquí:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _codeController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: InputDecoration(
                labelText: 'Código de 4 dígitos',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
                counterText: '',
                hintText: '0000',
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, letterSpacing: 2),
              onChanged: (value) {
                if (value.length == 4) {
                  _codeController.text = value;
                }
              },
            ),
            const SizedBox(height: 8),
            const Text(
              '⚠️ Solo el cliente puede proporcionar el código',
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              _codeController.clear();
              Navigator.pop(context);
            },
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => _validateCode(orderId),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Verificar Entrega'),
          ),
        ],
      ),
    );
  }

  // CORREGIDO: Validar código sin mostrarlo al domiciliario
  Future<void> _validateCode(String orderId) async {
    final enteredCode = _codeController.text.trim();
    
    if (enteredCode.length != 4) {
      _showSnackBar("El código debe tener 4 dígitos", false);
      return;
    }

    try {
      // Verificar el código contra Firestore
      final orderDoc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .get();

      if (!orderDoc.exists) {
        _showSnackBar("El pedido no existe", false);
        return;
      }

      final data = orderDoc.data();
      final expectedCode = data?['deliveryCode']?.toString();

      if (expectedCode == null || expectedCode.isEmpty) {
        _showSnackBar("Este pedido no tiene código de entrega", false);
        return;
      }

      if (enteredCode != expectedCode) {
        _showSnackBar("❌ Código incorrecto", false);
        _codeController.clear();
        return;
      }

      // Código correcto - proceder con la entrega
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': 'entregado',
        'deliveredAt': Timestamp.now(),
        'deliveryVerified': true,
        'verificationCode': enteredCode,
      });

      if (mounted) {
        _codeController.clear();
        Navigator.pop(context);
        _showSnackBar("✅ Entrega verificada exitosamente", true);
        _loadDriverStats();
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("Error al verificar entrega: $e", false);
      }
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline, 
              color: Colors.white
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

  Future<void> _openRouteInMaps(String clientAddress, String clientName) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(storeAddress)}'
      '&destination=${Uri.encodeComponent(clientAddress)}'
      '&travelmode=driving'
    );
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir Google Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _openInMaps(String address) async {
    if (address.isEmpty || address == 'Dirección no registrada') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay dirección disponible')),
      );
      return;
    }

    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir Maps';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.logout, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cerrar sesión?\n\nAsegúrate de completar todas las entregas pendientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      _showSnackBar("Sesión cerrada correctamente", true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (driverId == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                "⚠️ No se encontró el usuario",
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => _logout(context),
                child: const Text("Volver al inicio"),
              ),
            ],
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        appBar: _buildAppBar(theme),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildStatsHeader(theme),
              
              Container(
                color: theme.colorScheme.surface,
                child: TabBar(
                  labelColor: theme.colorScheme.primary,
                  unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.6),
                  indicatorColor: theme.colorScheme.primary,
                  indicatorWeight: 3,
                  tabs: const [
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.assignment, size: 18),
                          SizedBox(width: 8),
                          Text("Disponibles", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    Tab(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_shipping, size: 18),
                          SizedBox(width: 8),
                          Text("Mis Pedidos", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: TabBarView(
                  children: [
                    _buildAvailableOrdersTab(),
                    _buildMyOrdersTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.delivery_dining,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Reparte y Gana con Nosotros",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Hola $driverName",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, size: 20, color: Colors.white),
            ),
            tooltip: "Cerrar sesión",
            onPressed: () => _logout(context),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              "Entregas Realizadas",
              deliveredCount.toString(),
              Icons.check_circle,
              Colors.green,
              theme,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: _buildStatCard(
              "Ganancias Totales",
              "\$${totalEarnings.toStringAsFixed(0)}",
              Icons.attach_money,
              Colors.blue,
              theme,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator("Buscando pedidos...");
        }

        if (snapshot.hasError) {
          return _buildErrorWidget("Error: ${snapshot.error}");
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            Icons.inbox,
            "No hay datos",
            "No se recibió información del servidor"
          );
        }

        final allOrders = snapshot.data!.docs;
        final availableOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isOrderAvailable(data);
        }).toList();

        if (availableOrders.isEmpty) {
          return _buildEmptyState(
            Icons.inbox,
            "No hay pedidos disponibles",
            "Los nuevos pedidos aparecerán aquí"
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: availableOrders.length,
          itemBuilder: (context, index) {
            final order = availableOrders[index];
            final data = order.data() as Map<String, dynamic>;
            return _buildOrderCard(order, data, true);
          },
        );
      },
    );
  }

  Widget _buildMyOrdersTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingIndicator("Cargando pedidos...");
        }

        if (snapshot.hasError) {
          return _buildErrorWidget("Error: ${snapshot.error}");
        }

        if (!snapshot.hasData) {
          return _buildEmptyState(
            Icons.local_shipping_outlined,
            "Error de conexión",
            "No se pudo conectar con el servidor"
          );
        }

        final allOrders = snapshot.data!.docs;
        final myOrders = allOrders.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return _isMyOrder(data);
        }).toList();

        if (myOrders.isEmpty) {
          return _buildEmptyState(
            Icons.local_shipping_outlined,
            "No tienes pedidos activos",
            "Toma un pedido para empezar"
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: myOrders.length,
          itemBuilder: (context, index) {
            final order = myOrders[index];
            final data = order.data() as Map<String, dynamic>;
            return _buildOrderCard(order, data, false);
          },
        );
      },
    );
  }

  bool _isOrderAvailable(Map<String, dynamic> data) {
    final driverIdValue = data['driverId'];
    final status = data['status']?.toString().toLowerCase() ?? '';
    
    bool driverAvailable = true;
    if (driverIdValue != null) {
      if (driverIdValue is String) {
        if (driverIdValue.isNotEmpty) {
          driverAvailable = false;
        }
      } else {
        driverAvailable = false;
      }
    }
    
    bool statusAvailable = ['pendiente', 'confirmado'].contains(status);
    
    return driverAvailable && statusAvailable;
  }

  bool _isMyOrder(Map<String, dynamic> data) {
    final driverIdValue = data['driverId'];
    final status = data['status']?.toString().toLowerCase() ?? '';
    
    bool isMine = driverIdValue == driverId;
    bool isActive = ['asignado', 'en camino', 'entregado', 'cerrado'].contains(status);
    
    return isMine && isActive;
  }

  Widget _buildOrderCard(QueryDocumentSnapshot order, Map<String, dynamic> data, bool isAvailable) {
    final orderNumber = data['orderNumber'] ?? 'N/A';
    final userName = data['userName'] ?? 'Cliente sin nombre';
    final address = data['address'] ?? 'Dirección no especificada';
    final total = data['total']?.toString() ?? '0';
    final status = data['status'] ?? 'desconocido';
    final deliveryFee = data['deliveryFee']?.toString() ?? '4000';
    final createdAt = data['createdAt'] as Timestamp?;
    final storeAddressFromData = data['storeAddress'] ?? storeAddress;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      "Pedido #$orderNumber",
                      style: TextStyle(
                        color: _getStatusColor(status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (isAvailable && createdAt != null)
                    Text(
                      _formatTime(createdAt.toDate()),
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  if (!isAvailable)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              
              // INFORMACIÓN DE VERIFICACIÓN (SOLO PARA PEDIDOS EN CAMINO)
              if (!isAvailable && status.toLowerCase() == 'en camino') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.security, color: Colors.orange.shade600, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verificación requerida',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Pide al cliente el código de 4 dígitos de su app para completar la entrega',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              
              // DIRECCIÓN DE LA TIENDA (SOLO PARA PEDIDOS ACEPTADOS)
              if (!isAvailable) ...[
                Row(
                  children: [
                    Icon(Icons.store, size: 16, color: Colors.orange.shade600),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recoger en:',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          Text(
                            storeAddressFromData,
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _openInMaps(storeAddressFromData),
                      icon: Icon(Icons.map, size: 20, color: Colors.blue.shade600),
                      tooltip: 'Ver tienda en mapa',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
              
              // INFORMACIÓN DEL CLIENTE
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                  const SizedBox(width: 8),
                  Text(userName, style: const TextStyle(fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 8),
              
              // DIRECCIÓN DEL CLIENTE
              Row(
                children: [
                  Icon(Icons.location_on, size: 16, color: Colors.red.shade600),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      address,
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                  if (!isAvailable)
                    IconButton(
                      onPressed: () => _openInMaps(address),
                      icon: Icon(Icons.map, size: 20, color: Colors.blue.shade600),
                      tooltip: 'Ver cliente en mapa',
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // BOTÓN DE RUTA COMPLETA (SOLO PARA PEDIDOS ACEPTADOS)
              if (!isAvailable) ...[
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openRouteInMaps(address, userName),
                    icon: Icon(Icons.directions, color: Colors.green.shade600),
                    label: Text(
                      'Ruta completa: Tienda → Cliente',
                      style: TextStyle(color: Colors.green.shade600),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.green.shade300),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              
              // INFORMACIÓN DE PAGOS
              Row(
                children: [
                  Icon(Icons.attach_money, size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text("Total: \$${total}"),
                  if (!isAvailable) ...[
                    const SizedBox(width: 16),
                    Icon(Icons.delivery_dining, size: 16, color: Colors.blue.shade600),
                    const SizedBox(width: 8),
                    Text(
                      "Ganancia: \$${deliveryFee}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              
              // BOTONES DE ACCIÓN
              Row(
                children: [
                  const Spacer(),
                  if (isAvailable)
                    ElevatedButton.icon(
                      onPressed: () => _takeOrder(order.id),
                      icon: const Icon(Icons.delivery_dining, size: 18),
                      label: const Text("Tomar Pedido"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  if (!isAvailable)
                    Row(
                      children: [
                        if (status.toLowerCase() == 'en camino')
                          ElevatedButton.icon(
                            onPressed: () => _verifyDeliveryCode(order.id),
                            icon: const Icon(Icons.verified_user, size: 16),
                            label: const Text("Verificar Entrega"),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DriverOrderDetailScreen(
                                  orderId: order.id,
                                  storeAddress: storeAddressFromData,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility, size: 18),
                          label: const Text("Ver Detalles"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(message),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
          const SizedBox(height: 16),
          const Text(
            "Error al cargar",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => setState(() {}),
            child: const Text("Reintentar"),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(IconData icon, String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              subtitle,
              style: TextStyle(color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'confirmado':
        return Colors.orange;
      case 'asignado':
        return Colors.orange;
      case 'en camino':
        return Colors.blue;
      case 'entregado':
      case 'cerrado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'PENDIENTE';
      case 'confirmado':
        return 'CONFIRMADO';
      case 'asignado':
        return 'ASIGNADO';
      case 'en camino':
        return 'EN CAMINO';
      case 'entregado':
      case 'cerrado':
        return 'ENTREGADO';
      default:
        return status.toUpperCase();
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes}m';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours}h';
    } else {
      return 'Hace ${difference.inDays}d';
    }
  }
}