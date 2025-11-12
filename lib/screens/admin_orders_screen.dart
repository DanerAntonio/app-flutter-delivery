import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/inventory_service.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});
     
  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with TickerProviderStateMixin {
  Timestamp? _lastCreatedAt;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _selectedFilter = 'todos';
  bool _isUpdating = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final Map<String, String> _statusFilters = {
    'todos': 'Todos los pedidos',
    'pendiente': 'Pendientes',
    'asignado': 'Asignados',
    'en camino': 'En camino',
    'entregado': 'Entregados',
  };

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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _updateStatus(String orderId, String newStatus, Map<String, dynamic> orderData) async {
    setState(() {
      _isUpdating = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('orders')
          .doc(orderId)
          .update({
        'status': newStatus,
        'updatedAt': Timestamp.now(),
        if (newStatus == 'asignado') 'assignedAt': Timestamp.now(),
        if (newStatus == 'en camino') 'pickedUpAt': Timestamp.now(),
        if (newStatus == 'entregado') 'deliveredAt': Timestamp.now(),
      });

      // Descontar stock al marcar como entregado usando el servicio
      if (newStatus == 'entregado') {
        final products = orderData['products'] as List;
        final productList = products.cast<Map<String, dynamic>>();
        
        final stockSuccess = await InventoryService.processOrderStockDecrease(productList);
        if (!stockSuccess && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white),
                  const SizedBox(width: 12),
                  const Text('Advertencia: No se pudo actualizar el inventario'),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
            ),
          );
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('Estado actualizado: ${_getStatusText(newStatus)}'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                const Text('Error al actualizar estado'),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUpdating = false;
        });
      }
    }
  }

  Future<void> _playAlert() async {
    try {
      await _audioPlayer.play(
        AssetSource("sounds/new-notification-09-352705.mp3"),
      );
    } catch (e) {
      debugPrint("Error reproduciendo sonido: $e");
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Colors.orange;
      case 'asignado':
        return Colors.blue;
      case 'en camino':
        return Colors.purple;
      case 'entregado':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return 'Pendiente';
      case 'asignado':
        return 'Asignado';
      case 'en camino':
        return 'En Camino';
      case 'entregado':
        return 'Entregado';
      default:
        return status;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente':
        return Icons.access_time;
      case 'asignado':
        return Icons.person_pin;
      case 'en camino':
        return Icons.local_shipping;
      case 'entregado':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Stream<QuerySnapshot> _getOrdersStream() {
    Query query = FirebaseFirestore.instance
        .collection('orders')
        .orderBy('createdAt', descending: true);

    if (_selectedFilter != 'todos') {
      query = query.where('status', isEqualTo: _selectedFilter);
    }

    return query.snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          // Filtros de estado
          _buildFilterChips(theme),
          
          // Lista de pedidos
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getOrdersStream(),
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

                if (!snapshot.hasData) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Cargando pedidos...'),
                      ],
                    ),
                  );
                }

                final orders = snapshot.data!.docs;

                // Detectar nuevos pedidos y reproducir alerta
                if (orders.isNotEmpty) {
                  final newestOrder = orders.first['createdAt'] as Timestamp;
                  if (_lastCreatedAt == null || newestOrder.compareTo(_lastCreatedAt!) > 0) {
                    _playAlert();
                  }
                  _lastCreatedAt = newestOrder;
                }

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFilter == 'todos' 
                              ? 'No hay pedidos' 
                              : 'No hay pedidos ${_statusFilters[_selectedFilter]?.toLowerCase()}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Los pedidos aparecerán aquí en tiempo real',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final data = order.data() as Map<String, dynamic>;
                    return _buildOrderCard(order.id, data, theme);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ThemeData theme) {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _statusFilters.length,
        itemBuilder: (context, index) {
          final filterKey = _statusFilters.keys.elementAt(index);
          final filterLabel = _statusFilters[filterKey]!;
          final isSelected = filterKey == _selectedFilter;

          return Container(
            margin: const EdgeInsets.only(right: 12),
            child: FilterChip(
              label: Text(
                filterLabel,
                style: TextStyle(
                  color: isSelected ? Colors.white : theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = filterKey;
                });
              },
              backgroundColor: theme.colorScheme.surface,
              selectedColor: theme.colorScheme.primary,
              checkmarkColor: Colors.white,
              side: BorderSide(
                color: isSelected 
                    ? theme.colorScheme.primary 
                    : theme.colorScheme.outline.withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  Widget _buildOrderCard(String orderId, Map<String, dynamic> data, ThemeData theme) {
    final status = data['status'] ?? 'pendiente';
    final date = data['createdAt'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(data['createdAt'].toDate())
        : 'Sin fecha';
    final productos = data['products'] as List? ?? [];
    final orderNumber = data['orderNumber'] ?? 'N/A';
    final userName = data['userName'] ?? 'Cliente sin nombre';
    final address = data['address'] ?? 'Sin dirección';
    final total = data['total'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            // Header del pedido
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _getStatusColor(status).withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getStatusColor(status),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: Colors.white,
                      size: 24,
                    ),
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
                          userName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(status).toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '\$${total}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Información del pedido
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dirección
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          address,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  
                  if (productos.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Icon(Icons.shopping_bag, size: 20, color: theme.colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Productos (${productos.length})',
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    
                    ...productos.map((p) {
                      final opciones = (p['selectedOptions'] as List?) ?? [];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "${p['name']} x${p['quantity']}",
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                Text(
                                  '\$${p['price']}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                              ],
                            ),
                            if (opciones.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Opciones: ${opciones.join(', ')}",
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.6),
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }),
                  ],

                  const SizedBox(height: 20),
                  
                  // Botones de acción
                  Text(
                    'Cambiar Estado:',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusButton('pendiente', 'Pendiente', Icons.access_time, Colors.orange, orderId, data),
                      _buildStatusButton('asignado', 'Asignado', Icons.person_pin, Colors.blue, orderId, data),
                      _buildStatusButton('en camino', 'En Camino', Icons.local_shipping, Colors.purple, orderId, data),
                      _buildStatusButton('entregado', 'Entregado', Icons.check_circle, Colors.green, orderId, data),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusButton(String statusValue, String statusLabel, IconData icon, 
      Color color, String orderId, Map<String, dynamic> data) {
    final isCurrentStatus = data['status'] == statusValue;
    
    return ElevatedButton.icon(
      onPressed: (_isUpdating || isCurrentStatus) ? null : () => _updateStatus(orderId, statusValue, data),
      style: ElevatedButton.styleFrom(
        backgroundColor: isCurrentStatus ? color : color.withOpacity(0.1),
        foregroundColor: isCurrentStatus ? Colors.white : color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        side: BorderSide(
          color: color,
          width: isCurrentStatus ? 0 : 1,
        ),
      ),
      icon: _isUpdating 
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                color: isCurrentStatus ? Colors.white : color,
                strokeWidth: 2,
              ),
            )
          : Icon(icon, size: 18),
      label: Text(statusLabel),
    );
  }
}