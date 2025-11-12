import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/mock_products.dart';

/// Pantalla para migrar los productos de mock_products.dart a Firestore
/// USAR SOLO UNA VEZ
class MigrateProductsScreen extends StatefulWidget {
  const MigrateProductsScreen({super.key});

  @override
  State<MigrateProductsScreen> createState() => _MigrateProductsScreenState();
}

class _MigrateProductsScreenState extends State<MigrateProductsScreen> {
  bool isMigrating = false;
  List<String> logs = [];
  
  Future<void> _migrateProducts() async {
    setState(() {
      isMigrating = true;
      logs.clear();
      logs.add('🚀 Iniciando migración...');
    });

    try {
      final batch = FirebaseFirestore.instance.batch();
      int count = 0;

      for (var product in mockProducts) {
        // Usar el ID del mock_products como ID en Firestore
        final docRef = FirebaseFirestore.instance
            .collection('products')
            .doc(product.id);

        // Verificar si ya existe
        final docSnapshot = await docRef.get();
        
        if (docSnapshot.exists) {
          setState(() {
            logs.add('⚠️ Producto "${product.name}" ya existe (ID: ${product.id})');
          });
          continue;
        }

        batch.set(docRef, {
          'name': product.name,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl,
          'category': product.category,
          'stock': 100, // Stock inicial por defecto
          'createdAt': Timestamp.now(),
        });

        count++;
        setState(() {
          logs.add('✅ Agregando: ${product.name}');
        });
      }

      if (count > 0) {
        await batch.commit();
        setState(() {
          logs.add('');
          logs.add('🎉 ¡Migración completada!');
          logs.add('📦 $count productos agregados a Firestore');
          logs.add('');
          logs.add('✨ Ahora puedes gestionar el stock desde el inventario');
        });
      } else {
        setState(() {
          logs.add('');
          logs.add('ℹ️ Todos los productos ya estaban en Firestore');
        });
      }

      // Mostrar snackbar de éxito
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Text('$count productos migrados exitosamente'),
              ],
            ),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } catch (e) {
      setState(() {
        logs.add('');
        logs.add('❌ ERROR: $e');
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: $e')),
              ],
            ),
            backgroundColor: Colors.red.shade600,
          ),
        );
      }
    } finally {
      setState(() => isMigrating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title: const Text(
          'Migrar Productos a Firestore',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Información Importante',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '• Esta acción copiará todos los productos de mock_products.dart a Firestore\n'
                      '• Cada producto tendrá un stock inicial de 100 unidades\n'
                      '• Si un producto ya existe, se omitirá\n'
                      '• Los IDs de los productos se mantendrán igual (1, 2, 3...)\n'
                      '• Solo necesitas hacer esto UNA VEZ',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Productos a migrar: ${mockProducts.length}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Presiona el botón para iniciar',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: isMigrating ? null : _migrateProducts,
                icon: isMigrating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.cloud_upload),
                label: Text(
                  isMigrating ? 'Migrando...' : 'Migrar Productos',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            if (logs.isNotEmpty) ...[
              Text(
                'Registro de operaciones:',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListView.builder(
                      itemCount: logs.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Text(
                            logs[index],
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}