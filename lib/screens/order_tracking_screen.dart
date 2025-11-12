import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'home_screen.dart';

class OrderTrackingScreen extends StatefulWidget {  
  final String userId;
  const OrderTrackingScreen({super.key, required this.userId});

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> with TickerProviderStateMixin {
  String? lastStatus;
  late AnimationController _fadeController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _pulseAnimation;
// Almacena los códigos de los pedidos

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _fadeController.forward();
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // CORREGIDO: Generar código de 4 dígitos consistente
  String _generateOrderCode(String orderId) {
    // Usar el orderId como base para generar un código consistente de 4 dígitos
    final hash = orderId.hashCode.abs();
    return (hash % 10000).toString().padLeft(4, '0');
  }

  DateTime _toDateTime(dynamic value) {
    if (value == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    try {
      return DateTime.parse(value.toString());
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  int _getStepIndex(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 0;
      case 'asignado':
        return 1;
      case 'en camino':
        return 2;
      case 'entregado':
        return 3;
      case 'cerrado':
        return 4;
      default:
        return 0;
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'asignado':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      case 'cerrado':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Icons.access_time;
      case 'asignado':
        return Icons.person_pin;
      case 'en camino':
        return Icons.local_shipping;
      case 'entregado':
        return Icons.check_circle;
      case 'cerrado':
        return Icons.done_all;
      default:
        return Icons.help_outline;
    }
  }

  String _statusMessage(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Tu pedido está siendo procesado';
      case 'asignado':
        return 'Un repartidor ha tomado tu pedido';
      case 'en camino':
        return 'Tu pedido va en camino';
      case 'entregado':
        return 'Tu pedido ha sido entregado';
      case 'cerrado':
        return 'Pedido finalizado';
      default:
        return 'Estado desconocido';
    }
  }

  Future<void> _closeOrder(String orderId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green.shade600),
            const SizedBox(width: 12),
            const Text('Finalizar Pedido'),
          ],
        ),
        content: const Text('¿Confirmas que recibiste tu pedido correctamente?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
            ),
            child: const Text('Finalizar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
          'status': 'cerrado',
          'closedAt': Timestamp.now(),
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Pedido finalizado exitosamente'),
                ],
              ),
              backgroundColor: Colors.green.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Text("Error al cerrar pedido: $e"),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    }
  }

  void _showStatusNotification(String status) {
    final message = _statusMessage(status);
    final color = _statusColor(status);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(_statusIcon(status), color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: color.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showDeliveryInfo(BuildContext context, Map<String, dynamic> order) {
    final orderId = order['_id'] ?? '';
    final orderCode = _generateOrderCode(orderId); // Siempre el mismo código
    
    // Asegurarnos de que el código se guarde en Firestore
    _saveDeliveryCodeToFirestore(orderId, orderCode);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.qr_code, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Información para el Domiciliario'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Código del pedido
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Column(
                children: [
                  Text(
                    'CÓDIGO DEL PEDIDO',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    orderCode,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Muestra este código al domiciliario',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            // Información de entrega
            Text(
              'Dirección de Entrega:',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              order['address'] ?? 'No especificada',
              style: const TextStyle(fontSize: 16),
            ),
            
            if (order['floor'] != null && order['floor'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Piso/Apartamento:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(order['floor'].toString()),
            ],
            
            if (order['note'] != null && order['note'].toString().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Instrucciones adicionales:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(order['note'].toString()),
            ],
            
            const SizedBox(height: 16),
            Divider(color: Colors.grey.shade300),
            
            // Información del pedido
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cliente: ${order['userName'] ?? 'No especificado'}',
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
          ElevatedButton(
            onPressed: () {
              _shareOrderInfo(order, orderCode);
            },
            child: const Text('Compartir'),
          ),
        ],
      ),
    );
  }

  // NUEVO: Guardar código en Firestore para consistencia
  Future<void> _saveDeliveryCodeToFirestore(String orderId, String code) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'deliveryCode': code,
        'deliveryCodeGeneratedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Error guardando código en Firestore: $e');
    }
  }

  void _shareOrderInfo(Map<String, dynamic> order, String code) {
    final message = '''
🚚 **Información del Pedido**

📦 **Código:** $code
📍 **Dirección:** ${order['address'] ?? 'No especificada'}
${order['floor'] != null ? '🏢 **Piso/Apto:** ${order['floor']}' : ''}
${order['note'] != null ? '📝 **Instrucciones:** ${order['note']}' : ''}
👤 **Cliente:** ${order['userName'] ?? 'No especificado'}

*Por favor mostrar este código al domiciliario*
''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Compartir Información'),
        content: Text('Copia esta información para compartirla: \n\n$message'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Información copiada al portapapeles')),
              );
              Navigator.pop(context);
            },
            child: const Text('Copiar'),
          ),
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
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.track_changes,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Seguimiento de Pedido',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('orders')
              .where('userId', isEqualTo: widget.userId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar pedidos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.red.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('${snapshot.error}', style: TextStyle(color: Colors.grey.shade600)),
                  ],
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando tus pedidos...'),
                  ],
                ),
              );
            }

            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade400),
                    const SizedBox(height: 16),
                    Text(
                      'No tienes pedidos activos',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Haz tu primer pedido desde el menú',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Ver Menú'),
                    ),
                  ],
                ),
              );
            }

            final orders = docs.map((d) {
              final map = Map<String, dynamic>.from(d.data() as Map<String, dynamic>);
              map['_id'] = d.id;
              return map;
            }).toList();

            // Ordenar por fecha de creación
            orders.sort((a, b) {
              final da = _toDateTime(a['createdAt']);
              final db = _toDateTime(b['createdAt']);
              return db.compareTo(da);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                return _buildOrderCard(order, theme);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, ThemeData theme) {
    final status = (order['status'] ?? 'pendiente').toString();
    final currentStep = _getStepIndex(status);
    final createdAt = _toDateTime(order['createdAt']);
    final dateStr = (createdAt.millisecondsSinceEpoch == 0)
        ? 'Sin fecha'
        : DateFormat('dd/MM/yyyy HH:mm').format(createdAt);
    final products = (order['products'] is List) ? List.from(order['products']) : <dynamic>[];
    final orderNumber = order['orderNumber'] ?? order['_id'] ?? '—';
    final total = order['total'] ?? 0;
    final orderId = order['_id'] ?? '';
    final deliveryCode = order['deliveryCode'] ?? _generateOrderCode(orderId);

    // Mostrar notificación si el estado cambió
    if (lastStatus != status) {
      lastStatus = status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showStatusNotification(status);
      });
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Header del pedido
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _statusColor(status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      AnimatedBuilder(
                        animation: _pulseAnimation,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: status.toLowerCase() == 'en camino' ? _pulseAnimation.value : 1.0,
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _statusColor(status),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _statusIcon(status),
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pedido #${orderNumber.toString().split('-').last}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statusMessage(status),
                              style: TextStyle(
                                color: _statusColor(status),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(Icons.calendar_today, 'Fecha', dateStr, theme),
                      ),
                      Expanded(
                        child: _buildInfoItem(Icons.person, 'Cliente', order['userName'] ?? '', theme),
                      ),
                      Expanded(
                        child: _buildInfoItem(Icons.attach_money, 'Total', '\$${total}', theme),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Stepper de progreso
            Container(
              padding: const EdgeInsets.all(20),
              child: _buildProgressStepper(currentStep, theme),
            ),

            // Detalles del pedido
            ExpansionTile(
              title: Text(
                'Detalles del Pedido',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              leading: Icon(Icons.receipt_long, color: theme.colorScheme.primary),
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Lista de productos
                      if (products.isNotEmpty) ...[
                        Text(
                          'Productos (${products.length}):',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...products.map((p) => _buildProductItem(p, theme)),
                        const SizedBox(height: 16),
                      ],
                      
                      // Información de entrega
                      if (order['address'] != null && order['address'].toString().isNotEmpty) ...[
                        _buildDeliveryInfo(order, theme),
                        const SizedBox(height: 16),
                      ],
                      
                      // Código de entrega (SIEMPRE VISIBLE)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.qr_code, color: Colors.blue.shade600, size: 24),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Código de entrega:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    deliveryCode,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  Text(
                                    'Muestra este código al domiciliario',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Comprobante de pago
                      if (order['comprobanteUrl'] != null && order['comprobanteUrl'].toString().isNotEmpty)
                        _buildReceiptButton(order['comprobanteUrl'], theme),
                    ],
                  ),
                ),
              ],
            ),

            // Botones de acción
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  // Botón para mostrar información al domiciliario
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeliveryInfo(context, order),
                      icon: const Icon(Icons.qr_code),
                      label: const Text('Ver Código de Entrega'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Botón finalizar pedido (solo si está entregado)
                  if (status.toLowerCase() == 'entregado')
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _closeOrder(order['_id']),
                        icon: const Icon(Icons.check_circle),
                        label: const Text('Finalizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value, ThemeData theme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: theme.colorScheme.primary.withOpacity(0.7)),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgressStepper(int currentStep, ThemeData theme) {
    final steps = [
      {'title': 'Pedido Recibido', 'subtitle': 'Procesando tu orden'},
      {'title': 'Asignado', 'subtitle': 'Repartidor asignado'},
      {'title': 'En Camino', 'subtitle': 'Dirigiéndose a ti'},
      {'title': 'Entregado', 'subtitle': 'Pedido completado'},
      {'title': 'Finalizado', 'subtitle': 'Proceso terminado'},
    ];

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isActive = index <= currentStep;
        final isCurrent = index == currentStep;

        return Row(
          children: [
            // Círculo del paso
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive ? theme.colorScheme.primary : Colors.grey.shade300,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: isActive
                    ? Icon(
                        index < currentStep ? Icons.check : Icons.circle,
                        color: Colors.white,
                        size: 16,
                      )
                    : Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 16),
            // Texto del paso
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title']!,
                    style: TextStyle(
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isActive ? theme.colorScheme.onSurface : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    step['subtitle']!,
                    style: TextStyle(
                      fontSize: 12,
                      color: isActive ? theme.colorScheme.onSurface.withOpacity(0.7) : Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildProductItem(dynamic product, ThemeData theme) {
    final name = product['name'] ?? '';
    final qty = (product['quantity'] ?? 1).toString();
    final price = product['price'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              Icons.fastfood,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Cantidad: $qty',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '\$$price',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(Map<String, dynamic> order, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Información de Entrega:',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.location_on, size: 16, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order['address'] ?? '',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
        if (order['floor'] != null && order['floor'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.apartment, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text('Piso/Apt: ${order['floor']}'),
            ],
          ),
        ],
        if (order['note'] != null && order['note'].toString().isNotEmpty) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.note, size: 16, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Nota: ${order['note']}'),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildReceiptButton(String url, ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: () {
        showDialog(
          context: context,
          builder: (_) => Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: const Text('Comprobante de Pago'),
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Image.network(
                    url,
                    errorBuilder: (c, e, st) => Column(
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                        const SizedBox(height: 16),
                        const Text("No se pudo cargar la imagen"),
                      ],
                    ),
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
      icon: const Icon(Icons.receipt_long),
      label: const Text('Ver Comprobante'),
    );
  }
}