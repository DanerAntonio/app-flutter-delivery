// lib/screens/home_screen.dart - VERSIÓN MEJORADA
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../data/mock_products.dart';
import '../widgets/product_card.dart';
import '../models/product.dart';
import '../providers/order_provider.dart';
import 'login_screen.dart';
import 'order_summary_screen.dart';
import 'custom_order_screen.dart';
import 'admin_home_screen.dart';
import 'order_tracking_screen.dart';
import 'menu_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/store_status_widget.dart';
import '../services/store_service.dart';
import 'order_history_screen.dart';
import 'auth_gate.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  String? userId;
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  final List<String> _mensajesCristianos = [
  "💖 El alimento espiritual también es importante",
  "🙏 Yo soy el pan de vida (Juan 6:35)",
  "⭐ Que Dios bendiga tu comida",
  "✨ El mayor es el amor (1 Cor 13:13)",
  "🌟 Todo lo puedo en Cristo (Filipenses 4:13)",
  "💫 Donde está el Espíritu hay libertad",
  "🌞 El gozo del Señor es mi fortaleza",
  "🌿 Jehová es mi pastor (Salmo 23:1)",
  "🍞 No solo de pan vivirá el hombre (Mateo 4:4)",
  "💛 Dios es amor (1 Juan 4:8)",
  "🌻 Bendice, oh alma mía, a Jehová (Salmo 103:1)",
  "🌼 La bendición de Jehová enriquece (Proverbios 10:22)",
  "☀️ En tus manos están mis tiempos (Salmo 31:15)",
  "🌈 Confía en el Señor y Él actuará (Salmo 37:5)",
  "🍇 El Señor proveerá (Génesis 22:14)",
  "🍯 Gustad y ved que es bueno Jehová (Salmo 34:8)",
  "🍃 El amor nunca deja de ser (1 Cor 13:8)",
  "🕊️ El Señor es mi luz y mi salvación (Salmo 27:1)",
  "🌸 Sed agradecidos (Colosenses 3:15)",
  "🌹 Con amor eterno te he amado (Jeremías 31:3)",
  "🌺 Jehová peleará por vosotros (Éxodo 14:14)",
  "🌾 Todo tiene su tiempo (Eclesiastés 3:1)",
  "🌷 La fe mueve montañas (Mateo 17:20)",
  "🌻 Buscad primero el reino de Dios (Mateo 6:33)",
  "🌼 El Señor es fiel en todo tiempo",
  "🌟 Dios cuida de ti (Salmo 121)",
  "💫 Echa sobre Jehová tu carga (Salmo 55:22)",
  "🍂 Sé fuerte y valiente (Josué 1:9)",
  "🕯️ La paz de Dios guardará tu corazón (Filipenses 4:7)",
  "🕊️ Cristo vive en mí (Gálatas 2:20)",
  "🌺 Gracias Señor por este día",
  "🌼 Dios te ama más de lo que imaginas",
  "🌻 Eres bendecido para bendecir",
  "🌹 Confía, Dios tiene el control",
  "🌿 Jesús es el camino, la verdad y la vida (Juan 14:6)",
  "🌞 Cada día es un regalo de Dios",
  "🌾 Jehová proveerá todo lo que necesitas",
  "🍇 Agradece por lo que tienes hoy",
  "🍯 Dios multiplica lo poco con amor",
  "🍃 Comparte amor, comparte bendición",
  "🕊️ Paz, amor y gratitud siempre",
  "✨ Dios hace todo perfecto a su tiempo",
  "⭐ La alegría viene de Dios",
  "💖 Gracias a Dios por los alimentos",
  "🌸 Alimenta tu alma con fe y esperanza",
  "🌞 Bendecido día lleno de gracia",
  "🌈 Con Dios todo es posible",
  "🌼 No temas, Dios está contigo",
  "🌻 Que tu corazón tenga paz hoy",
  "🌿 Todo es posible para el que cree (Marcos 9:23)",

  ];

  int _mensajeIndex = 0;
  late Timer _mensajeTimer;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    userId = user?.uid;
    _initializeStore();
    _setupAnimations();
    _startMensajeTimer();
  }

  void _setupAnimations() {
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleController = AnimationController(
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

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  void _startMensajeTimer() {
    _mensajeTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _mensajeIndex = (_mensajeIndex + 1) % _mensajesCristianos.length;
        });
      }
    });
  }

  Future<void> _initializeStore() async {
    try {
      await StoreService.ensureDeliveryConfigExists();
    } catch (e) {
      debugPrint('[ERROR] Store init: $e');
    }
  }

  void _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: Theme.of(dialogContext).colorScheme.primary),
            const SizedBox(width: 12),
            const Text('Cerrar Sesión'),
          ],
        ),
        content: const Text('¿Estás seguro que deseas cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final orderProvider = Provider.of<OrderProvider>(context, listen: false);
        orderProvider.clearCart();
        await FirebaseAuth.instance.signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      } catch (e) {
        debugPrint('Error en logout: $e');
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    }
  }

  void _goToAdmin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
    );
  }

  void _goToOrderTracking(BuildContext context) {
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderTrackingScreen(userId: userId!)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.white),
              SizedBox(width: 12),
              Text("Inicia sesión para ver seguimiento"),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  Future<void> _openWhatsApp() async {
    final url = Uri.parse("https://wa.me/573112762618?text=Hola%20quiero%20soporte%20con%20mi%20pedido");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  Future<void> _checkStoreAndNavigate(BuildContext context, Widget destination, String actionName) async {
    final isOpen = await StoreService.getCurrentStatus();

    if (!mounted) return;

    if (!isOpen) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.store_rounded, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("La tienda está cerrada. No puedes $actionName ahora.")),
            ],
          ),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
  }

  String _normalizeAssetPath(String path) {
    if (path.startsWith('assets/')) return path;
    if (path.startsWith('/')) return path.substring(1);
    return 'assets/$path';
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    _mensajeTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final theme = Theme.of(context);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: StoreService.stream(),
      builder: (context, storeSnapshot) {
        final isOpen = StoreService.isOpenNow(storeSnapshot.data);
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return const LoginScreen();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
          builder: (context, userSnapshot) {
            final userData = userSnapshot.data?.data();
            final userName = userData?['name'];
            final userRole = userData?['rol'];

            return Scaffold(
              backgroundColor: theme.colorScheme.surface,
              appBar: _buildAppBar(theme, userRole, orderProvider, context),
              body: FadeTransition(
                opacity: _fadeAnimation,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    // Header compacto
                    SliverToBoxAdapter(
                      child: _buildCompactHeader(userName, userRole, theme, isOpen, context),
                    ),
                    // Grid de productos
                    SliverPadding(
                      padding: const EdgeInsets.all(12),
                      sliver: SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final product = mockProducts[index];
                            final imagePath = _normalizeAssetPath(product.imageUrl);
                            return ProductCard(
                              product: Product(
                                id: product.id,
                                name: product.name,
                                description: product.description,
                                price: product.price,
                                imageUrl: imagePath,
                                category: product.category,
                                quantity: product.quantity,
                                selectedOptions: product.selectedOptions,
                              ),
                            );
                          },
                          childCount: mockProducts.length,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: _buildQuickActionsFAB(isOpen, context),
            );
          },
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme, String? userRole, OrderProvider orderProvider, BuildContext context) {
    return AppBar(
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              Icons.restaurant_rounded,
              color: theme.colorScheme.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "La Cocina de Claudia",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
      actions: [
        if (userRole == "admin")
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 20),
            ),
            onPressed: () => _goToAdmin(context),
          ),

        Stack(
          children: [
            Container(
              margin: const EdgeInsets.only(right: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.shopping_cart_rounded, color: Colors.white, size: 24),
                onPressed: () => _checkStoreAndNavigate(context, const OrderSummaryScreen(), "ver pedido"),
              ),
            ),
            if (orderProvider.itemCount > 0)
              Positioned(
                right: 0,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(
                    '${orderProvider.itemCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),

        IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.logout_rounded, color: Colors.white, size: 20),
          ),
          onPressed: () => _logout(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildCompactHeader(String? userName, String? userRole, ThemeData theme, bool isOpen, BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.1),
            theme.colorScheme.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Estado de la tienda compacto
          Padding(
            padding: const EdgeInsets.all(12),
            child: StoreStatusWidget(isAdmin: userRole == "admin"),
          ),
          
          // Mensaje de bienvenida y cristiano
          if (userName != null)
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.waving_hand_rounded,
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
                            "¡Hola $userName!",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 500),
                            child: Text(
                              key: ValueKey(_mensajeIndex),
                              _mensajesCristianos[_mensajeIndex],
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontStyle: FontStyle.italic,
                                fontSize: 12,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsFAB(bool isOpen, BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Botón de Armar Pedido
        if (isOpen)
          FloatingActionButton.extended(
            onPressed: () => _checkStoreAndNavigate(context, const CustomOrderScreen(), "armar pedido"),
            icon: const Icon(Icons.restaurant_menu_rounded),
            label: const Text('Armar Pedido'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            heroTag: 'armar',
          ),
        const SizedBox(height: 12),
        
        // Botón de Menú
        FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MenuScreen()),
          ),
          backgroundColor: Colors.green,
          child: const Icon(Icons.menu_book_rounded),
          heroTag: 'menu',
        ),
        const SizedBox(height: 12),
        
        // Botón de Seguimiento
        FloatingActionButton(
          onPressed: () => _goToOrderTracking(context),
          backgroundColor: Colors.blue,
          child: const Icon(Icons.delivery_dining_rounded),
          heroTag: 'tracking',
        ),
        const SizedBox(height: 12),
        
        // Botón de WhatsApp
        FloatingActionButton(
          onPressed: _openWhatsApp,
          backgroundColor: const Color(0xFF25D366),
          child: const Icon(Icons.support_agent_rounded),
          heroTag: 'whatsapp',
        ),
      ],
    );
  }
}