import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';


class DriverOrderDetailScreen extends StatefulWidget {
  final String orderId;
  final String storeAddress;
  
  const DriverOrderDetailScreen({
    super.key, 
    required this.orderId,
    required this.storeAddress,
  });

  @override
  State<DriverOrderDetailScreen> createState() => _DriverOrderDetailScreenState();
}

class _DriverOrderDetailScreenState extends State<DriverOrderDetailScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool isUpdatingStatus = false;
  final TextEditingController _pinController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _setupAnimations();
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

  @override
  void dispose() {
    _fadeController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  double _getOrderTotal(Map<String, dynamic> data) {
    try {
      if (data['total'] != null) {
        return (data['total'] as num).toDouble();
      }
      
      if (data['items'] != null && data['items'] is List) {
        double total = 0.0;
        for (var item in data['items'] as List) {
          if (item is Map<String, dynamic>) {
            final price = (item['price'] as num?)?.toDouble() ?? 0.0;
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            total += price * quantity;
          }
        }
        return total;
      }
      
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente': return 'PENDIENTE';
      case 'confirmado': return 'CONFIRMADO';
      case 'asignado': return 'ASIGNADO';
      case 'en camino': return 'EN CAMINO';
      case 'entregado': return 'ENTREGADO';
      case 'cerrado': return 'CERRADO';
      default: return status.toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
      case 'confirmado': return Colors.orange;
      case 'asignado': return Colors.blue;
      case 'en camino': return Colors.purple;
      case 'entregado':
      case 'cerrado': return Colors.green;
      default: return Colors.grey;
    }
  }

  // SOLICITAR CÓDIGO PIN ANTES DE MARCAR COMO ENTREGADO - VERSIÓN FINAL
  Future<void> _requestDeliveryVerification(Map<String, dynamic> data) async {
    _pinController.clear();
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.lock, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Verificar Entrega'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Solicita al cliente el código de verificación de 4 dígitos para confirmar la entrega.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
              ),
              decoration: InputDecoration(
                labelText: 'Código de verificación',
                hintText: '1234',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                counterText: '',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'El cliente tiene este código en su resumen de pedido',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade800,
                      ),
                    ),
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
            child: const Text('Verificar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final enteredCode = _pinController.text.trim();

      if (enteredCode.isEmpty) {
        _showSnackBar('Por favor ingresa el código', false);
        return;
      }

      // Obtener el código correcto desde Firestore
      String correctCode = '';
      try {
        final orderDoc = await FirebaseFirestore.instance
            .collection('orders')
            .doc(widget.orderId)
            .get();
        
        if (orderDoc.exists) {
          final orderData = orderDoc.data();
          correctCode = orderData?['verificationCode']?.toString() ?? '';
        }
      } catch (e) {
        print('Error obteniendo código: $e');
        _showSnackBar('Error al verificar el código', false);
        return;
      }

      if (correctCode.isEmpty) {
        _showSnackBar('Error: No se encontró código de verificación para este pedido', false);
        return;
      }

      if (enteredCode != correctCode) {
        _showSnackBar('❌ Código incorrecto. Verifica con el cliente.', false);
        return;
      }

      // Código correcto, proceder con la entrega
      await _updateOrderStatus('entregado', data);
    }
  }

  Future<void> _updateOrderStatus(String newStatus, Map<String, dynamic> data) async {
    setState(() {
      isUpdatingStatus = true;
    });

    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updatedAt': Timestamp.now(),
      };

      switch (newStatus.toLowerCase()) {
        case 'en camino':
          updateData['pickedUpAt'] = Timestamp.now();
          break;
        case 'entregado':
          updateData['deliveredAt'] = Timestamp.now();
          updateData['deliveryFee'] = 4000;
          updateData['isVerified'] = true; // Marcar como verificado
          break;
      }

      await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .update(updateData);

      if (mounted) {
        _showSnackBar('✅ ${_getStatusText(newStatus)} - Entrega verificada', true);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al actualizar estado: $e', false);
      }
    } finally {
      if (mounted) {
        setState(() {
          isUpdatingStatus = false;
        });
      }
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
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // LLAMAR AL CLIENTE
  Future<void> _callCustomer(String phone) async {
    if (phone.isEmpty || phone == 'No registrado') {
      _showSnackBar('No hay número de teléfono disponible', false);
      return;
    }

    final uri = Uri.parse('tel:$phone');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'No se puede realizar la llamada';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al llamar: $e', false);
      }
    }
  }

  // WHATSAPP AL CLIENTE
  Future<void> _whatsappCustomer(String phone) async {
    if (phone.isEmpty || phone == 'No registrado') {
      _showSnackBar('No hay número de WhatsApp disponible', false);
      return;
    }

    // Limpiar el número (quitar espacios, guiones, etc)
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final uri = Uri.parse('https://wa.me/$cleanPhone?text=Hola,%20soy%20tu%20repartidor%20de%20Pide%20Claudia');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'No se puede abrir WhatsApp';
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('Error al abrir WhatsApp: $e', false);
      }
    }
  }

  Future<void> _openInMaps(String address) async {
    if (address.isEmpty || address == 'Dirección no registrada') {
      _showSnackBar('No hay dirección disponible', false);
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
        _showSnackBar('Error al abrir Maps: $e', false);
      }
    }
  }

  Future<void> _openRouteInMaps(String clientAddress, String clientName) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&origin=${Uri.encodeComponent(widget.storeAddress)}'
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
        _showSnackBar('Error: $e', false);
      }
    }
  }

  Widget _buildOrderItems(List<dynamic> items) {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Items del Pedido',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final itemMap = item as Map<String, dynamic>;
              final name = itemMap['name'] ?? 'Producto sin nombre';
              final price = (itemMap['price'] as num?)?.toDouble() ?? 0.0;
              final quantity = (itemMap['quantity'] as num?)?.toInt() ?? 1;
              
              return Container(
                margin: EdgeInsets.only(bottom: index == items.length - 1 ? 0 : 8),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    child: Text(
                      quantity.toString(),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  trailing: Text(
                    '\$${(price * quantity).toStringAsFixed(0)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 16,
                    ),
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> data) {
    final userName = data['userName'] ?? 'Cliente sin nombre';
    final address = data['address'] ?? 'Dirección no registrada';
    final floor = data['floor']?.toString() ?? '';
    final note = data['note']?.toString() ?? '';
    final phone = data['userPhone']?.toString() ?? '';
    final paymentMethod = data['paymentMethod']?.toString() ?? 'No especificado';

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Información del Cliente',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInfoRow('👤 Nombre', userName),
            _buildInfoRow('💳 Método de pago', paymentMethod),
            
            // TELÉFONO CON BOTONES DE CONTACTO
            const SizedBox(height: 8),
            Text(
              '📞 Contacto',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    phone.isEmpty ? 'No registrado' : phone,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (phone.isNotEmpty) ...[
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.phone, color: Colors.green.shade700, size: 20),
                    ),
                    onPressed: () => _callCustomer(phone),
                    tooltip: 'Llamar',
                  ),
                  IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.chat, color: Colors.green.shade700, size: 20),
                    ),
                    onPressed: () => _whatsappCustomer(phone),
                    tooltip: 'WhatsApp',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),
            
            // DIRECCIÓN CON MAPA
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 Dirección de entrega',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        address,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                      if (floor.isNotEmpty) 
                        Text(
                          'Piso: $floor',
                          style: TextStyle(
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map, color: Colors.blue.shade700),
                  ),
                  onPressed: () => _openInMaps(address),
                ),
              ],
            ),
            
            if (note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                '📝 Nota especial:',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  note,
                  style: TextStyle(
                    color: Colors.orange.shade800,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreInfo() {
    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Información de la Tienda',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('🏪 Nombre', 'La Cocina de Claudia'),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📍 Dirección de recogida',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        widget.storeAddress,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.map, color: Colors.blue.shade700),
                  ),
                  onPressed: () => _openInMaps(widget.storeAddress),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(Map<String, dynamic> data) {
    final currentStatus = data['status']?.toString().toLowerCase() ?? 'asignado';
    final address = data['address'] ?? 'Dirección no registrada';
    final userName = data['userName'] ?? 'Cliente';
    final deliveryFee = data['deliveryFee']?.toString() ?? '4000';

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tu ganancia',
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '\$$deliveryFee',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.attach_money, color: Colors.green.shade700),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.directions, size: 24),
              label: const Text(
                'Abrir Ruta Completa',
                style: TextStyle(fontSize: 16),
              ),
              onPressed: () => _openRouteInMaps(address, userName),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          if (currentStatus == 'asignado') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.delivery_dining, size: 24),
                label: const Text(
                  'Marcar como En Camino',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: isUpdatingStatus ? null : () => _updateOrderStatus('en camino', data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          
          if (currentStatus == 'en camino') ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.verified_user, size: 24),
                label: const Text(
                  'Verificar y Entregar',
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: isUpdatingStatus ? null : () => _requestDeliveryVerification(data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
          
          if (currentStatus == 'entregado' || currentStatus == 'cerrado') ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Colors.green.shade600),
                  const SizedBox(width: 8),
                  Text(
                    'Pedido Entregado ✓',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        title: const Text(
          'Detalle del Pedido',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isUpdatingStatus)
            Container(
              padding: const EdgeInsets.only(right: 16),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .doc(widget.orderId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando detalles del pedido...'),
                  ],
                ),
              );
            }

            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.data() == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    const Text('Error al cargar el pedido'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Volver'),
                    ),
                  ],
                ),
              );
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final orderNumber = data['orderNumber'] ?? 'N/A';
            final currentStatus = data['status']?.toString() ?? 'asignado';
            final items = data['items'] is List ? data['items'] as List<dynamic> : [];
            final double orderTotal = _getOrderTotal(data);
            final deliveryFee = data['deliveryFee']?.toString() ?? '4000';

            return SingleChildScrollView(
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          theme.colorScheme.primary.withOpacity(0.8),
                          theme.colorScheme.primary,
                        ],
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Pedido #$orderNumber',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(currentStatus),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(currentStatus),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            Column(
                              children: [
                                Text(
                                  '\$${orderTotal.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Total Pedido',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  '\$$deliveryFee',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Ganancia',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              children: [
                                Text(
                                  items.length.toString(),
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  'Items',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // SECCIONES DE INFORMACIÓN
                  _buildStoreInfo(),
                  _buildClientInfo(data),
                  
                  if (items.isNotEmpty) _buildOrderItems(items),
                  
                  _buildActionButtons(data),
                  
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}