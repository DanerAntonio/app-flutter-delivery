// lib/screens/auth_gate.dart - VERSIÓN CORREGIDA
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'admin_home_screen.dart';
import 'driver_home_screen.dart';
import 'menu_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        // DEBUG
        print('🔐 AuthGate - Estado: ${authSnapshot.connectionState}');
        print('🔐 AuthGate - Usuario: ${authSnapshot.data?.email}');
        print('🔐 AuthGate - Error: ${authSnapshot.error}');

        // Mientras carga la autenticación
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSplashScreen();
        }

        // Si hay error en la autenticación
        if (authSnapshot.hasError) {
          print('❌ Error de autenticación: ${authSnapshot.error}');
          return const PublicMenuGate();
        }

        final user = authSnapshot.data;

        // Si no hay usuario -> Menú público
        if (user == null) {
          print('👤 No hay usuario, mostrando menú público');
          return const PublicMenuGate();
        }

        // Usuario autenticado -> Usar FUTURE BUILDER separado
        return _UserRoleGate(user: user);
      },
    );
  }
}

// NUEVO: Widget separado para manejar el rol del usuario
class _UserRoleGate extends StatefulWidget {
  final User user;

  const _UserRoleGate({required this.user});

  @override
  State<_UserRoleGate> createState() => _UserRoleGateState();
}

class _UserRoleGateState extends State<_UserRoleGate> {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;

  @override
  void initState() {
    super.initState();
    // Cargar datos del usuario UNA SOLA VEZ al inicializar
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.user.uid)
        .get();
  }

  @override
  void didUpdateWidget(covariant _UserRoleGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si el usuario cambia, recargar los datos
    if (oldWidget.user.uid != widget.user.uid) {
      _userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .get();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: _userFuture,
      builder: (context, userSnapshot) {
        // DEBUG
        print('👤 UserRoleGate - Estado: ${userSnapshot.connectionState}');
        print('👤 UserRoleGate - Tiene datos: ${userSnapshot.hasData}');
        print('👤 UserRoleGate - Error: ${userSnapshot.error}');

        // Mientras carga el documento
        if (userSnapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingSplashScreen();
        }

        // Si hay error o no hay datos, ir a home por defecto
        if (userSnapshot.hasError || !userSnapshot.hasData) {
          print('❌ Error cargando datos usuario: ${userSnapshot.error}');
          print('📧 Usuario actual: ${widget.user.email}');
          return const HomeScreen();
        }

        // Obtener rol del documento
        final userData = userSnapshot.data?.data();
        if (userData == null) {
          print('⚠️ Datos de usuario nulos');
          return const HomeScreen();
        }

        final rawRole = userData['rol'] ?? userData['role'] ?? 'cliente';
        final role = _normalizeRole(rawRole.toString());
        
        print('✅ Usuario autenticado: ${widget.user.email}, Rol: $role');

        // Redirigir según rol
        switch (role) {
          case 'admin':
            return const AdminHomeScreen();
          case 'courier':
            return const DriverHomeScreen();
          case 'client':
          default:
            return const HomeScreen();
        }
      },
    );
  }

  String _normalizeRole(String value) {
    final v = value.toLowerCase().trim();
    if (v.contains('admin')) return 'admin';
    if (v.contains('courier') || v.contains('domicili')) return 'courier';
    if (v.contains('client') || v.contains('cliente')) return 'client';
    return 'client';
  }
}

// LOGOUT MEJORADO - Asegúrate de usar esta función
Future<void> safeLogout(BuildContext context) async {
  try {
    print('🚪 Cerrando sesión...');
    
    // Cerrar sesión en Firebase
    await FirebaseAuth.instance.signOut();
    
    print('✅ Sesión cerrada exitosamente');
    
    // Navegar limpiando TODO el stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
    
  } catch (e) {
    print('❌ Error en logout: $e');
    // Mostrar error pero forzar navegación
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }
}

// EJEMPLO de cómo hacer logout en tus pantallas:
class LogoutExample extends StatelessWidget {
  const LogoutExample({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutConfirmation(context),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () => _showLogoutConfirmation(context),
          child: const Text('Cerrar Sesión'),
        ),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cerrar Sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Cerrar diálogo
              safeLogout(context);    // Cerrar sesión
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar Sesión'),
          ),
        ],
      ),
    );
  }
}

// El resto del código (PublicMenuGate, _LoadingSplashScreen) se mantiene igual
class PublicMenuGate extends StatefulWidget {
  const PublicMenuGate({super.key});

  @override
  State<PublicMenuGate> createState() => _PublicMenuGateState();
}

class _PublicMenuGateState extends State<PublicMenuGate> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MenuScreen(),
    const LoginScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: theme.colorScheme.surface,
          selectedItemColor: theme.colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.normal,
            fontSize: 11,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu),
              label: 'Nuestro Menú',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.login),
              label: 'Ingresar',
            ),
          ],
        ),
      ),
      persistentFooterButtons: _currentIndex == 0 ? [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.purple.shade600],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              const Icon(Icons.star, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Inicia sesión para hacer pedidos y seguimiento',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _currentIndex = 1;
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  backgroundColor: Colors.white.withOpacity(0.2),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: const Text(
                  'Ingresar',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ] : null,
    );
  }
}

// Mantén tu _LoadingSplashScreen igual...
class _LoadingSplashScreen extends StatefulWidget {
  const _LoadingSplashScreen();

  @override
  State<_LoadingSplashScreen> createState() => _LoadingSplashScreenState();
}

class _LoadingSplashScreenState extends State<_LoadingSplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withOpacity(0.8),
              theme.colorScheme.background,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _pulseAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.restaurant_menu,
                          size: 60,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 40),
                
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Pide Claudia',
                    style: theme.textTheme.displayLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Text(
                    'Comida casera con el mejor sazón',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w400,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 60),
                
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    children: [
                      SizedBox(
                        width: 40,
                        height: 40,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Cargando...',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}