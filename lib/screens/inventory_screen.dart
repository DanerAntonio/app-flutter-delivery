import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_product.dart';

class InventoryScreen extends StatelessWidget {
  const InventoryScreen({super.key});

  void _addProduct(BuildContext context) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController(text: '5');
    final unitController = TextEditingController(text: 'unidades');
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("➕ Agregar Producto Terminado"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: const InputDecoration(labelText: "Nombre del Plato*")
              ),
              const SizedBox(height: 10),
              TextField(
                controller: descriptionController, 
                decoration: const InputDecoration(labelText: "Descripción")
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController, 
                decoration: const InputDecoration(labelText: "Categoría")
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: priceController, 
                      decoration: const InputDecoration(labelText: "Precio de Venta*"), 
                      keyboardType: TextInputType.number
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitController, 
                      decoration: const InputDecoration(labelText: "Unidad*"),
                      onChanged: (value) {
                        if (value.isEmpty) {
                          unitController.text = 'unidades';
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockController, 
                      decoration: const InputDecoration(labelText: "Stock Inicial*"), 
                      keyboardType: TextInputType.number
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: minStockController, 
                      decoration: const InputDecoration(labelText: "Stock Mínimo*"), 
                      keyboardType: TextInputType.number
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text("❌ Cancelar")
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ El nombre es obligatorio")),
                );
                return;
              }

              final newProduct = InventoryProduct(
                id: '',
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                price: double.tryParse(priceController.text) ?? 0,
                imageUrl: '',
                category: categoryController.text.trim(),
                stock: double.tryParse(stockController.text) ?? 0,
                minStock: double.tryParse(minStockController.text) ?? 5,
                unit: unitController.text.trim().isNotEmpty ? unitController.text.trim() : 'unidades',
                active: true,
                productType: ProductType.finishedProduct,
              );

              FirebaseFirestore.instance.collection('products').add(newProduct.toMap());
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Producto terminado agregado correctamente"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("💾 Guardar Plato"),
          ),
        ],
      ),
    );
  }

  void _addIngredient(BuildContext context) {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    final minStockController = TextEditingController(text: '10');
    final unitController = TextEditingController(text: 'unidades');
    final costPriceController = TextEditingController();
    final categoryController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("🥩 Agregar Ingrediente"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: "Nombre del Ingrediente*",
                  hintText: "Ej: Pollo, Arroz, Papas..."
                )
              ),
              const SizedBox(height: 10),
              TextField(
                controller: categoryController,
                decoration: const InputDecoration(
                  labelText: "Categoría*",
                  hintText: "Ej: proteína, base, acompañante, bebida"
                )
              ),
              const SizedBox(height: 10),
              TextField(
                controller: costPriceController,
                decoration: const InputDecoration(
                  labelText: "Precio de Costo*",
                  hintText: "Precio que te cuesta a ti"
                ),
                keyboardType: TextInputType.number
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockController,
                      decoration: const InputDecoration(labelText: "Stock Actual*"),
                      keyboardType: TextInputType.number
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: minStockController,
                      decoration: const InputDecoration(labelText: "Stock Mínimo*"),
                      keyboardType: TextInputType.number
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: unitController,
                decoration: const InputDecoration(
                  labelText: "Unidad de medida*",
                  hintText: "Ej: unidades, libras, kg..."
                )
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue.shade700, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Este ingrediente se usará para platos personalizados",
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("❌ Cancelar")
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ El nombre es obligatorio")),
                );
                return;
              }

              if (categoryController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("❌ La categoría es obligatoria")),
                );
                return;
              }

              final ingredient = InventoryProduct(
                id: '',
                name: nameController.text.trim(),
                description: "Ingrediente para platos personalizados",
                price: 0,
                imageUrl: '',
                category: categoryController.text.trim(),
                stock: double.tryParse(stockController.text) ?? 0,
                minStock: double.tryParse(minStockController.text) ?? 10,
                unit: unitController.text.trim().isNotEmpty ? unitController.text.trim() : 'unidades',
                active: true,
                productType: ProductType.ingredient,
                costPrice: double.tryParse(costPriceController.text) ?? 0,
              );

              FirebaseFirestore.instance.collection('products').add(ingredient.toMap());
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("✅ Ingrediente agregado correctamente"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: const Text("💾 Guardar Ingrediente"),
          ),
        ],
      ),
    );
  }

  void _editProduct(BuildContext context, InventoryProduct product) {
    final nameController = TextEditingController(text: product.name);
    final descriptionController = TextEditingController(text: product.description);
    final priceController = TextEditingController(text: product.price.toString());
    final stockController = TextEditingController(text: product.stock.toString());
    final minStockController = TextEditingController(text: product.minStock.toString());
    final unitController = TextEditingController(text: product.unit);
    final categoryController = TextEditingController(text: product.category);
    final costPriceController = TextEditingController(text: product.costPrice?.toString() ?? '0');

    final bool isIngredient = product.isIngredient;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("✏️ Editar ${isIngredient ? 'Ingrediente' : 'Producto'}"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController, 
                decoration: InputDecoration(
                  labelText: "Nombre*",
                  hintText: isIngredient ? "Nombre del ingrediente" : "Nombre del plato"
                )
              ),
              const SizedBox(height: 10),
              
              if (!isIngredient) ...[
                TextField(
                  controller: descriptionController, 
                  decoration: const InputDecoration(labelText: "Descripción")
                ),
                const SizedBox(height: 10),
              ],
              
              TextField(
                controller: categoryController, 
                decoration: InputDecoration(
                  labelText: "Categoría*",
                  hintText: isIngredient ? "Ej: proteína, base..." : "Ej: plato fuerte, bebida..."
                )
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: isIngredient ? costPriceController : priceController,
                      decoration: InputDecoration(
                        labelText: isIngredient ? "Precio de Costo*" : "Precio de Venta*"
                      ), 
                      keyboardType: TextInputType.number
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: unitController, 
                      decoration: const InputDecoration(labelText: "Unidad*")
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: stockController, 
                      decoration: const InputDecoration(labelText: "Stock Actual*"), 
                      keyboardType: TextInputType.number
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: minStockController, 
                      decoration: const InputDecoration(labelText: "Stock Mínimo*"), 
                      keyboardType: TextInputType.number
                    ),
                  ),
                ],
              ),
              
              if (isIngredient) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.kitchen, color: Colors.purple.shade700, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        "Ingrediente para platos personalizados",
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), 
            child: const Text("❌ Cancelar")
          ),
          ElevatedButton(
            onPressed: () {
              final updatedProduct = product.copyWith(
                name: nameController.text.trim(),
                description: descriptionController.text.trim(),
                price: isIngredient ? 0 : (double.tryParse(priceController.text) ?? product.price),
                category: categoryController.text.trim(),
                stock: double.tryParse(stockController.text) ?? product.stock,
                minStock: double.tryParse(minStockController.text) ?? product.minStock,
                unit: unitController.text.trim().isNotEmpty ? unitController.text.trim() : 'unidades',
                costPrice: double.tryParse(costPriceController.text) ?? product.costPrice,
                lastUpdated: DateTime.now(),
              );

              FirebaseFirestore.instance.collection('products').doc(product.id).update(updatedProduct.toMap());
              Navigator.pop(dialogContext);
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ ${isIngredient ? 'Ingrediente' : 'Producto'} actualizado correctamente"),
                  backgroundColor: Colors.green,
                ),
              );
            },
            child: Text("💾 Actualizar ${isIngredient ? 'Ingrediente' : 'Producto'}"),
          ),
        ],
      ),
    );
  }

  void _showProductDetails(BuildContext context, InventoryProduct product) {
    final isIngredient = product.isIngredient;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isIngredient ? Icons.kitchen : Icons.restaurant,
              color: isIngredient ? Colors.purple : Colors.orange,
            ),
            const SizedBox(width: 8),
            Text("📊 ${product.name}"),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.description.isNotEmpty && !isIngredient) ...[
              Text("📝 ${product.description}", style: const TextStyle(fontStyle: FontStyle.italic)),
              const SizedBox(height: 10),
            ],
            
            Text("🏷️ Tipo: ${isIngredient ? '🥩 Ingrediente' : '🍽️ Plato Terminado'}"),
            Text("📂 Categoría: ${product.category.isEmpty ? 'No especificada' : product.category}"),
            
            if (isIngredient) 
              Text("💰 Precio de costo: \$${(product.costPrice ?? 0).toStringAsFixed(0)}"),
            if (!isIngredient)
              Text("💰 Precio de venta: \$${product.price.toStringAsFixed(0)}"),
              
            Text("📦 Stock: ${product.stock} ${product.unit}"),
            Text("⚠️ Mínimo: ${product.minStock} ${product.unit}"),
            Text("📊 Estado: ${product.stockStatus}"),
            
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: product.stockColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: product.stockColor),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(product.stockIcon, color: product.stockColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    product.stockStatus,
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      color: product.stockColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isIngredient) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "💡 Usado en platos personalizados",
                  style: TextStyle(
                    color: Colors.purple.shade700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cerrar"),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCard(InventoryProduct product, BuildContext context, ThemeData theme) {
    final isIngredient = product.isIngredient;
    
    // Calcular precio a mostrar
    final String precioTexto = isIngredient
        ? (product.costPrice ?? 0).toStringAsFixed(0)
        : product.price.toStringAsFixed(0);
    
    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: product.stockColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Stack(
            children: [
              Center(
                child: Icon(
                  product.stockIcon, 
                  color: product.stockColor,
                ),
              ),
              if (isIngredient)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.kitchen,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                product.name,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: product.isLowStock ? Colors.red : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
            if (isIngredient)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "INGREDIENTE",
                  style: TextStyle(
                    color: Colors.purple.shade800,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock: ${product.stock.toStringAsFixed(0)} ${product.unit} • ${isIngredient ? 'Costo' : 'Precio'}: \$${precioTexto}'),
              if (product.category.isNotEmpty) 
                Text("Categoría: ${product.category}"),
              if (product.isLowStock) ...[
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "STOCK BAJO",
                    style: TextStyle(
                      color: Colors.orange.shade800,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        trailing: SizedBox(
          width: 100,
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility, color: Colors.blue, size: 20),
                onPressed: () => _showProductDetails(context, product),
              ),
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.green, size: 20),
                onPressed: () => _editProduct(context, product),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _confirmDelete(context, product),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, InventoryProduct product) {
    final isIngredient = product.isIngredient;
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("🗑️ Eliminar ${isIngredient ? 'Ingrediente' : 'Producto'}"),
        content: Text("¿Estás seguro de eliminar \"${product.name}\"?${isIngredient ? '\n\n⚠️ Esto afectará los platos personalizados' : ''}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              FirebaseFirestore.instance.collection('products').doc(product.id).delete();
              Navigator.pop(dialogContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("✅ ${isIngredient ? 'Ingrediente' : 'Producto'} eliminado"),
                  backgroundColor: Colors.green.shade600,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text("Eliminar ${isIngredient ? 'Ingrediente' : 'Producto'}"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("📦 Gestión de Inventario"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('products').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', textAlign: TextAlign.center),
                ],
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("No hay productos en el inventario", style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 8),
                  Text(
                    "Usa los botones + para agregar productos o ingredientes",
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final products = snapshot.data!.docs.map((doc) {
            final map = doc.data() as Map<String, dynamic>;
            
            if (map['active'] is String) {
              map['active'] = map['active'].toString().toLowerCase() == 'true';
            }
            
            return InventoryProduct.fromMap(map).copyWith(id: doc.id);
          }).toList();

          final finishedProducts = products.where((p) => p.isFinishedProduct).toList();
          final ingredients = products.where((p) => p.isIngredient).toList();

          finishedProducts.sort((a, b) => a.isLowStock ? -1 : 1);
          ingredients.sort((a, b) => a.isLowStock ? -1 : 1);

          return DefaultTabController(
            length: 2,
            child: Column(
              children: [
                Container(
                  color: Colors.deepOrange,
                  child: const TabBar(
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.restaurant, size: 20),
                        text: 'Platos Terminados',
                      ),
                      Tab(
                        icon: Icon(Icons.kitchen, size: 20),
                        text: 'Ingredientes',
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      finishedProducts.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.restaurant_menu, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text("No hay platos terminados"),
                                  const SizedBox(height: 8),
                                  const Text("Agrega platos preparados para la venta directa"),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: finishedProducts.length,
                              itemBuilder: (context, index) {
                                return _buildProductCard(finishedProducts[index], context, Theme.of(context));
                              },
                            ),

                      ingredients.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.kitchen, size: 64, color: Colors.grey.shade400),
                                  const SizedBox(height: 16),
                                  const Text("No hay ingredientes"),
                                  const SizedBox(height: 8),
                                  const Text("Agrega ingredientes para platos personalizados"),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: ingredients.length,
                              itemBuilder: (context, index) {
                                return _buildProductCard(ingredients[index], context, Theme.of(context));
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: "ingredient_btn",
            onPressed: () => _addIngredient(context),
            backgroundColor: Colors.deepPurple,
            mini: true,
            child: const Icon(Icons.kitchen, color: Colors.white, size: 20),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () => _addProduct(context),
            backgroundColor: Colors.deepOrange,
            child: const Icon(Icons.add, color: Colors.white, size: 28),
          ),
        ],
      ),
    );
  }
}