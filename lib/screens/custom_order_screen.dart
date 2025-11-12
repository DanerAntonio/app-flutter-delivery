// lib/screens/custom_order_screen.dart - VERSIÓN CON MÚLTIPLES CANTIDADES
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/order_provider.dart';
import '../models/product.dart';


class CustomOrderScreen extends StatefulWidget {
  const CustomOrderScreen({super.key});

  @override
  State<CustomOrderScreen> createState() => _CustomOrderScreenState();
}

class _CustomOrderScreenState extends State<CustomOrderScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool isAddingToCart = false;

  // ✅ CAMBIADO: Ahora usamos Map<String, int> para guardar CANTIDADES
  Map<String, int> bases = {
    "Arroz porción (\$2000)": 0,
    "Papas (\$3000)": 0,
    "Arepa con queso mozzarella (\$2000)": 0,
  };

  Map<String, int> proteinas = {
    "Pollo (\$5000)": 0,
    "Cerdo (\$5000)": 0,
    "Chicharrón (\$5000)": 0,
    "Res (\$6000)": 0,
    "Tilapia frita (\$15000)": 0,
    "Posta (\$7000)": 0,
    "Bagre frito (\$6000)": 0,
    "Bagre sudado (\$7000)": 0,
    "Trucha frita (\$17000)": 0,
  };

  Map<String, int> acompanantes = {
    "Porción de frijol (\$3000)": 0,
    "Ensalada (\$1000)": 0,
    "Huevo (\$1000)": 0,
    "Porción de aguacate (\$1000)": 0,
    "Porción de sopa (\$3000)": 0,
    "Consomé de tilapia (\$5000)": 0,
    "Patacón medio plátano (\$2000)": 0,
  };

  Map<String, int> bebidas = {
    "Guarapo (\$1000)": 0,
    "Gaseosa (\$3000)": 0,
    "Jugo de guayaba en agua 9oz (\$2000)": 0,
    "Jugo de guayaba en leche 9oz (\$3000)": 0,
  };

  // Opciones adicionales (estas sí pueden ser boolean)
  Map<String, bool> cubiertos = {
    "Incluir cubiertos": false,
    "Incluir servilletas": false,
    "Empaque especial": false,
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
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _fadeController.forward();
    _scaleController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  double calcularTotal() {
    double total = 0;
    total += calcularSeccion(bases);
    total += calcularSeccion(proteinas);
    total += calcularSeccion(acompanantes);
    total += calcularSeccion(bebidas);
    return total;
  }

  // ✅ CAMBIADO: Ahora calcula según CANTIDAD
  double calcularSeccion(Map<String, int> seccion) {
    double total = 0;
    seccion.forEach((key, quantity) {
      if (quantity > 0) {
        final precio = RegExp(r'\$(\d+)').firstMatch(key);
        if (precio != null) {
          total += double.parse(precio.group(1)!) * quantity;
        }
      }
    });
    return total;
  }

  int _getTotalSeleccionados() {
    int count = 0;
    count += bases.values.where((v) => v > 0).length;
    count += proteinas.values.where((v) => v > 0).length;
    count += acompanantes.values.where((v) => v > 0).length;
    count += bebidas.values.where((v) => v > 0).length;
    return count;
  }

  // ✅ NUEVO: Obtener el total de CANTIDADES (no solo items seleccionados)
  int _getTotalCantidades() {
    int total = 0;
    total += bases.values.fold(0, (sum, quantity) => sum + quantity);
    total += proteinas.values.fold(0, (sum, quantity) => sum + quantity);
    total += acompanantes.values.fold(0, (sum, quantity) => sum + quantity);
    total += bebidas.values.fold(0, (sum, quantity) => sum + quantity);
    return total;
  }

  // ✅ MÉTODO MEJORADO: Ahora maneja CANTIDADES
  Future<void> agregarAlCarrito() async {
    setState(() {
      isAddingToCart = true;
    });

    await Future.delayed(const Duration(milliseconds: 500));

    try {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);

      // ✅ NUEVO: Crear lista con CANTIDADES
      List<Map<String, dynamic>> seleccionadosConCantidad = [];
      
      // Agregar bases con cantidad
      bases.forEach((key, quantity) {
        if (quantity > 0) {
          seleccionadosConCantidad.add({
            'nombre': key,
            'cantidad': quantity,
            'precio': _getPrecio(key),
          });
        }
      });

      // Agregar proteínas con cantidad
      proteinas.forEach((key, quantity) {
        if (quantity > 0) {
          seleccionadosConCantidad.add({
            'nombre': key,
            'cantidad': quantity,
            'precio': _getPrecio(key),
          });
        }
      });

      // Agregar acompañantes con cantidad
      acompanantes.forEach((key, quantity) {
        if (quantity > 0) {
          seleccionadosConCantidad.add({
            'nombre': key,
            'cantidad': quantity,
            'precio': _getPrecio(key),
          });
        }
      });

      // Agregar bebidas con cantidad
      bebidas.forEach((key, quantity) {
        if (quantity > 0) {
          seleccionadosConCantidad.add({
            'nombre': key,
            'cantidad': quantity,
            'precio': _getPrecio(key),
          });
        }
      });

      // Agregar opciones adicionales
      final cubiertosSel = cubiertos.entries.where((e) => e.value).map((e) => e.key);

      if (seleccionadosConCantidad.isEmpty && cubiertosSel.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text("Selecciona al menos un producto")),
                ],
              ),
              backgroundColor: Colors.orange.shade600,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.all(16),
            ),
          );
          setState(() => isAddingToCart = false);
        }
        return;
      }

      // ✅ NUEVO: Crear descripción con CANTIDADES
      final descripcionItems = seleccionadosConCantidad.map((item) {
        return '${item['nombre']} x${item['cantidad']}';
      }).toList();

      if (cubiertosSel.isNotEmpty) {
        descripcionItems.addAll(cubiertosSel);
      }

      final descripcionCompleta = descripcionItems.join(", ");

      // ✅ CREAR PRODUCTO CON CANTIDAD TOTAL
      final customProduct = Product(
        id: "custom_${DateTime.now().millisecondsSinceEpoch}",
        name: "Pedido Personalizado",
        description: descripcionCompleta,
        price: calcularTotal(),
        imageUrl: "https://cdn-icons-png.flaticon.com/512/3075/3075977.png",
        category: "Personalizado",
        quantity: 1, // La cantidad del "producto" en el carrito es 1
        selectedOptions: descripcionItems,
      );

      // ✅ AGREGAR DIRECTAMENTE AL CARRITO
      orderProvider.addToCart(customProduct);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(child: Text("¡Pedido personalizado agregado! ($_getTotalCantidades items)")),
              ],
            ),
            backgroundColor: Colors.green.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );

        Navigator.pop(context);
      }

    } catch (e) {
      print('Error en agregarAlCarrito: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(child: Text("Error al agregar pedido")),
              ],
            ),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isAddingToCart = false;
        });
      }
    }
  }

  double _getPrecio(String opcion) {
    final precio = RegExp(r'\$(\d+)').firstMatch(opcion);
    return precio != null ? double.parse(precio.group(1)!) : 0.0;
  }

  // ✅ NUEVO MÉTODO: Incrementar cantidad
  void _incrementQuantity(Map<String, int> seccion, String opcion) {
    setState(() {
      seccion[opcion] = (seccion[opcion] ?? 0) + 1;
    });
  }

  // ✅ NUEVO MÉTODO: Decrementar cantidad
  void _decrementQuantity(Map<String, int> seccion, String opcion) {
    setState(() {
      final current = seccion[opcion] ?? 0;
      if (current > 0) {
        seccion[opcion] = current - 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: _buildUnifiedAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            _buildOptimizedHeader(theme),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildUnifiedSectionCard("Bases", bases, Icons.rice_bowl, Colors.orange, theme),
                  const SizedBox(height: 12),
                  _buildUnifiedSectionCard("Proteínas", proteinas, Icons.set_meal, Colors.red, theme),
                  const SizedBox(height: 12),
                  _buildUnifiedSectionCard("Acompañantes", acompanantes, Icons.restaurant, Colors.green, theme),
                  const SizedBox(height: 12),
                  _buildUnifiedSectionCard("Bebidas", bebidas, Icons.local_drink, Colors.blue, theme),
                  const SizedBox(height: 12),
                  _buildUnifiedSectionCard("Extras", cubiertos, Icons.dining, Colors.purple, theme, showPrice: false),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSheet: _buildOptimizedBottomSheet(theme),
    );
  }

  PreferredSizeWidget _buildUnifiedAppBar(ThemeData theme) {
    return AppBar(
      elevation: 1,
      backgroundColor: theme.colorScheme.primary,
      title: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.tune,
              color: theme.colorScheme.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arma tu Pedido',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Personaliza tu comida',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      iconTheme: const IconThemeData(color: Colors.white),
    );
  }

  Widget _buildOptimizedHeader(ThemeData theme) {
    final totalCantidades = _getTotalCantidades();
    
    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.green.shade50,
              Colors.orange.shade50,
            ],
          ),
          border: Border(
            bottom: BorderSide(color: Colors.green.shade200, width: 1),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.restaurant_menu,
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
                        'Crea tu combo ideal',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      Text(
                        '✅ Puedes elegir MÚLTIPLES cantidades de cada producto',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.star, color: Colors.orange.shade600, size: 20),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.checklist, color: Colors.blue.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Items: $totalCantidades',
                          style: TextStyle(
                            color: Colors.blue.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.attach_money, color: Colors.green.shade700, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Total: \$${calcularTotal().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ CAMBIADO: Ahora maneja tanto Map<String,int> como Map<String,bool>
  Widget _buildUnifiedSectionCard(String titulo, Map<String, dynamic> opciones, 
      IconData icon, Color color, ThemeData theme, {bool showPrice = true}) {
    
    final seleccionados = opciones is Map<String, int> 
        ? opciones.values.where((v) => v > 0).length
        : (opciones as Map<String, bool>).values.where((v) => v).length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            titulo,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            seleccionados > 0 
                ? '$seleccionados seleccionados'
                : 'Toca para seleccionar',
            style: TextStyle(
              color: seleccionados > 0 
                  ? color 
                  : theme.colorScheme.onSurface.withOpacity(0.6),
              fontWeight: seleccionados > 0 ? FontWeight.w600 : FontWeight.normal,
              fontSize: 11,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: seleccionados > 0 ? color : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$seleccionados',
              style: TextStyle(
                color: seleccionados > 0 ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
          ),
          children: opciones.keys.map((opcion) {
            final isCantidad = opciones is Map<String, int>;
            final cantidad = isCantidad ? (opciones[opcion] as int) : 0;
            final isSelected = !isCantidad ? (opciones[opcion] as bool) : cantidad > 0;
            
            final precio = RegExp(r'\$(\d+)').firstMatch(opcion);
            final nombreLimpio = opcion.replaceAll(RegExp(r'\s*\(\$\d+\)'), '');
            final precioTexto = showPrice && precio != null ? '\$${precio.group(1)}' : '';

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected ? color : Colors.transparent,
                  width: 1,
                ),
              ),
              child: isCantidad 
                  ? _buildCantidadItem(opcion, nombreLimpio, precioTexto, color, opciones.cast<String, int>(), theme)
                  : _buildCheckboxItem(opcion, nombreLimpio, precioTexto, isSelected, color, opciones.cast<String, bool>(), theme),
            );
          }).toList(),
        ),
      ),
    );
  }

  // ✅ NUEVO WIDGET: Para items con CANTIDAD (botones + y -)
  Widget _buildCantidadItem(String opcion, String nombreLimpio, String precioTexto, 
      Color color, Map<String, int> seccion, ThemeData theme) {
    final cantidad = seccion[opcion] ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      leading: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: cantidad > 0 ? color : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Text(
          cantidad > 0 ? '$cantidad' : '0',
          style: TextStyle(
            color: cantidad > 0 ? Colors.white : Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(
        nombreLimpio,
        style: TextStyle(
          fontWeight: cantidad > 0 ? FontWeight.w600 : FontWeight.normal,
          color: cantidad > 0 ? color : theme.colorScheme.onSurface,
          fontSize: 13,
        ),
      ),
      subtitle: precioTexto.isNotEmpty
          ? Text(
              precioTexto,
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            )
          : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.remove, size: 16, color: Colors.red.shade600),
            ),
            onPressed: () => _decrementQuantity(seccion, opcion),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, size: 16, color: Colors.green.shade600),
            ),
            onPressed: () => _incrementQuantity(seccion, opcion),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  // ✅ WIDGET EXISTENTE: Para opciones boolean (checkbox)
  Widget _buildCheckboxItem(String opcion, String nombreLimpio, String precioTexto, 
      bool isSelected, Color color, Map<String, bool> seccion, ThemeData theme) {
    return CheckboxListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Text(
        nombreLimpio,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected ? color : theme.colorScheme.onSurface,
          fontSize: 13,
        ),
      ),
      subtitle: precioTexto.isNotEmpty
          ? Text(
              precioTexto,
              style: TextStyle(
                color: Colors.green.shade600,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            )
          : null,
      value: isSelected,
      activeColor: color,
      onChanged: (value) {
        setState(() {
          seccion[opcion] = value ?? false;
        });
      },
      secondary: isSelected 
          ? Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 12,
              ),
            )
          : null,
    );
  }

  Widget _buildOptimizedBottomSheet(ThemeData theme) {
    final totalSeleccionados = _getTotalSeleccionados();
    final totalCantidades = _getTotalCantidades();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.green.shade50,
                    Colors.blue.shade50,
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.restaurant_menu,
                      color: Colors.green.shade700,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tu pedido personalizado',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$totalCantidades items • Total: \$${calcularTotal().toStringAsFixed(0)}',
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (totalSeleccionados > 0)
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.green.shade600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: (totalSeleccionados > 0 && !isAddingToCart) 
                    ? agregarAlCarrito 
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: totalSeleccionados > 0 
                      ? theme.colorScheme.primary 
                      : Colors.grey.shade400,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: totalSeleccionados > 0 ? 3 : 0,
                ),
                icon: isAddingToCart
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(
                        totalSeleccionados > 0 
                            ? Icons.add_shopping_cart_rounded
                            : Icons.restaurant_menu,
                        size: 20,
                      ),
                label: Text(
                  isAddingToCart 
                      ? 'Agregando...' 
                      : totalSeleccionados > 0
                          ? 'Agregar al Carrito (\$${calcularTotal().toStringAsFixed(0)})'
                          : 'Selecciona ingredientes',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            if (totalSeleccionados > 0)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Preparado con ingredientes frescos y sazón casero',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }
}