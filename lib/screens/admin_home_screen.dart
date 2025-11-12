import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/store_status_widget.dart';
import '../services/store_service.dart';
import 'admin_orders_screen.dart';
import 'delivery_config_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    StoreService.ensureDocExists(defaultOpen: false);
    _setupAnimations();
    
    _pages = [
      const AdminOrdersScreen(),
      const MetricsScreen(),
      const InventoryScreen(),
    ];
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
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: Theme.of(dialogContext).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Cerrar Sesión Admin'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cerrar la sesión de administrador?\n\nAsegúrate de que no haya operaciones pendientes.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text("Sesión administrativa cerrada"),
            ],
          ),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _refreshStoreStatus(BuildContext context) async {
    try {
      final isOpen = await StoreService.getCurrentStatus();
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isOpen ? Icons.store : Icons.store_mall_directory_outlined,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(isOpen ? "Tienda está ABIERTA" : "Tienda está CERRADA"),
            ],
          ),
          backgroundColor: isOpen ? Colors.green.shade600 : Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 12),
              Text("Error al consultar estado"),
            ],
          ),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: _buildAppBar(theme, context),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: StoreService.stream(),
                builder: (context, snapshot) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: StoreStatusWidget(isAdmin: true),
                  );
                },
              ),
            ),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DeliveryConfigScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.delivery_dining,
                            color: Colors.blue.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Configurar Domicilio',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
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

                                  return Text(
                                    'Costo actual: \$${deliveryFee.toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey.shade400,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            Expanded(child: _pages[_selectedIndex]),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long),
              activeIcon: Icon(Icons.receipt_long),
              label: "Pedidos",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: "Métricas",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_outlined),
              activeIcon: Icon(Icons.inventory_2),
              label: "Inventario",
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          backgroundColor: theme.colorScheme.surface,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
          onTap: _onItemTapped,
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final adminName = user?.displayName ?? 'Admin';
    
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
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
                  "Admin",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  "Bienvenido $adminName",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.refresh, size: 20, color: Colors.white),
            ),
            tooltip: "Actualizar estado",
            onPressed: () => _refreshStoreStatus(context),
          ),
        ),
        Container(
          margin: const EdgeInsets.only(right: 16),
          child: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
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
}

class MetricsScreen extends StatelessWidget {
  const MetricsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Cargando métricas..."),
              ],
            ),
          );
        }

        final orders = snapshot.data!.docs;
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        
        int totalPedidos = orders.length;
        int entregados = orders.where((o) {
          final data = o.data() as Map<String, dynamic>;
          return (data['status'] ?? '') == 'entregado';
        }).length;
        int pendientes = orders.where((o) {
          final data = o.data() as Map<String, dynamic>;
          return (data['status'] ?? '') == 'pendiente';
        }).length;
        int enCamino = orders.where((o) {
          final data = o.data() as Map<String, dynamic>;
          return (data['status'] ?? '') == 'en camino';
        }).length;
        
        double totalVentas = orders.fold(0.0, (total, o) {
          final data = o.data() as Map<String, dynamic>;
          return total + ((data['total'] ?? 0) as num).toDouble();
        });
        
        double totalDomicilios = orders.fold(0.0, (total, o) {
          final data = o.data() as Map<String, dynamic>;
          return total + ((data['deliveryFee'] ?? 4000) as num).toDouble();
        });
        int cantidadDomicilios = orders.length;
        
        final ordersToday = orders.where((o) {
          final data = o.data() as Map<String, dynamic>;
          final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
          return createdAt != null && createdAt.isAfter(today);
        }).toList();
        
        int pedidosHoy = ordersToday.length;
        double ventasHoy = ordersToday.fold(0.0, (total, o) {
          final data = o.data() as Map<String, dynamic>;
          return total + ((data['total'] ?? 0) as num).toDouble();
        });
        double domiciliosHoy = ordersToday.fold(0.0, (total, o) {
          final data = o.data() as Map<String, dynamic>;
          return total + ((data['deliveryFee'] ?? 4000) as num).toDouble();
        });

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Métricas del Negocio",
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "Análisis en tiempo real",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.analytics,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildMetricCard("Total Pedidos", "$totalPedidos", Icons.shopping_cart, Colors.blue, theme),
                  _buildMetricCard("Entregados", "$entregados", Icons.check_circle, Colors.green, theme),
                  _buildMetricCard("Pendientes", "$pendientes", Icons.pending_actions, Colors.orange, theme),
                  _buildMetricCard("En Camino", "$enCamino", Icons.local_shipping, Colors.purple, theme),
                ],
              ),
              
              const SizedBox(height: 24),
              
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('settings').doc('delivery').snapshots(),
                builder: (context, deliverySnapshot) {
                  double currentFee = 4000;
                  double driverPercentage = 100;
                  
                  if (deliverySnapshot.hasData && deliverySnapshot.data!.exists) {
                    final data = deliverySnapshot.data!.data() as Map<String, dynamic>;
                    currentFee = (data['fee'] ?? 4000).toDouble();
                    driverPercentage = (data['driverPercentage'] ?? 100).toDouble();
                  }

                  final gananciaPromedioDomiciliario = cantidadDomicilios > 0 
                      ? (totalDomicilios * (driverPercentage / 100)) / cantidadDomicilios 
                      : 0.0;

                  return Card(
                    color: Colors.blue.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.delivery_dining, color: Colors.blue.shade700),
                              const SizedBox(width: 8),
                              Text(
                                "Métricas de Domicilio",
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade900,
                                ),
                              ),
                            ],
                          ),
                          const Divider(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total cobrado:'),
                              Text('\$${totalDomicilios.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Ganancia promedio domiciliario ($driverPercentage%):'),
                              Text(
                                '\$${gananciaPromedioDomiciliario.toStringAsFixed(0)}',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green.shade700, fontSize: 16),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Costo actual:'),
                              Text('\$${currentFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              
              const SizedBox(height: 24),
              
              Text("Ventas", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Row(
                children: [
                  Expanded(child: _buildSalesCard("Total Ventas", "\$${totalVentas.toStringAsFixed(0)}", Icons.attach_money, Colors.green, theme)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildSalesCard("Ventas Hoy", "\$${ventasHoy.toStringAsFixed(0)}", Icons.today, Colors.blue, theme)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              Text("Resumen Diario", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                          const SizedBox(width: 12),
                          Text("Hoy ${_formatDate(now)}", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              Text("$pedidosHoy", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.blue)),
                              Text("Pedidos", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                            ],
                          ),
                          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                          Column(
                            children: [
                              Text("\$${ventasHoy.toStringAsFixed(0)}", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.green)),
                              Text("Ventas", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                            ],
                          ),
                          Container(width: 1, height: 40, color: theme.colorScheme.outline.withValues(alpha: 0.3)),
                          Column(
                            children: [
                              Text("\$${domiciliosHoy.toStringAsFixed(0)}", style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: Colors.orange)),
                              Text("Domicilios", style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0.1), color.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(value, style: theme.textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7), fontWeight: FontWeight.w500), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesCard(String title, String value, IconData icon, Color color, ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                  Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, color: color)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => "${date.day}/${date.month}/${date.year}";
}

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _addProduct(BuildContext context) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(dialogContext).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.add_business, color: Theme.of(dialogContext).colorScheme.primary),
                  ),
                  const SizedBox(width: 12),
                  Text("Agregar Producto", style: Theme.of(dialogContext).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: "Nombre del producto",
                  hintText: "Ej: Hamburguesa especial",
                  prefixIcon: Icon(Icons.fastfood, color: Theme.of(dialogContext).colorScheme.primary),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(labelText: "Precio", hintText: "0.00", prefixIcon: Icon(Icons.attach_money, color: Colors.green)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(labelText: "Stock disponible", hintText: "0", prefixIcon: Icon(Icons.inventory_2, color: Colors.blue)),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancelar"))),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (nameController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("El nombre es obligatorio")));
                          return;
                        }
                        try {
                          await FirebaseFirestore.instance.collection('products').add({
                            'name': nameController.text.trim(),
                            'price': double.tryParse(priceController.text) ?? 0,
                            'stock': int.tryParse(stockController.text) ?? 0,
                            'createdAt': Timestamp.now(),
                          });
                          if (context.mounted) {
                            Navigator.pop(dialogContext);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                              content: const Row(
                                children: [
                                  Icon(Icons.check_circle, color: Colors.white),
                                  SizedBox(width: 12),
                                  Text("Producto agregado")
                                ],
                              ),
                              backgroundColor: Colors.green.shade600,
                            ));
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                          }
                        }
                      },
                      child: const Text("Guardar"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text("Cargando inventario...")
              ],
            ),
          );
        }

        final products = snapshot.data!.docs;

        return Scaffold(
          backgroundColor: theme.colorScheme.surface,
          body: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Inventario", style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                          Text("${products.length} productos", style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12)
                      ),
                      child: Icon(Icons.inventory_2, color: theme.colorScheme.primary, size: 28),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text("No hay productos", style: theme.textTheme.headlineSmall?.copyWith(color: Colors.grey.shade600)),
                            const SizedBox(height: 8),
                            Text("Agrega productos para empezar", style: TextStyle(color: Colors.grey.shade500)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: products.length,
                        itemBuilder: (context, index) {
                          final product = products[index];
                          final data = product.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Sin nombre';
                          final price = data['price']?.toDouble() ?? 0.0;
                          final stock = data['stock']?.toInt() ?? 0;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                        borderRadius: BorderRadius.circular(8)
                                      ),
                                      child: Icon(Icons.fastfood, color: theme.colorScheme.primary, size: 20),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(name, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.inventory_2, size: 14, color: stock > 0 ? Colors.green : Colors.red),
                                              const SizedBox(width: 4),
                                              Text("Stock: $stock", style: TextStyle(color: stock > 0 ? Colors.green : Colors.red, fontWeight: FontWeight.w500, fontSize: 12)),
                                              const SizedBox(width: 16),
                                              const Icon(Icons.attach_money, size: 14, color: Colors.blue),
                                              const SizedBox(width: 4),Text("\$${price.toStringAsFixed(0)}", style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 12)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(8)
                                        ),
                                        child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                                      ),
                                      onPressed: () async {
                                        final confirmed = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogContext) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                            title: const Row(
                                              children: [
                                                Icon(Icons.delete_outline, color: Colors.red),
                                                SizedBox(width: 12),
                                                Text('Eliminar Producto')
                                              ],
                                            ),
                                            content: Text('¿Eliminar "$name"?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogContext, false),
                                                child: const Text('Cancelar')
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(dialogContext, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                  foregroundColor: Colors.white
                                                ),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmed == true) {
                                          try {
                                            await FirebaseFirestore.instance.collection('products').doc(product.id).delete();
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                                content: const Row(
                                                  children: [
                                                    Icon(Icons.check_circle, color: Colors.white),
                                                    SizedBox(width: 12),
                                                    Text("Producto eliminado")
                                                  ],
                                                ),
                                                backgroundColor: Colors.green.shade600,
                                              ));
                                            }
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
                                            }
                                          }
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _addProduct(context),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add),
            label: const Text("Agregar Producto"),
          ),
        );
      },
    );
  }
}