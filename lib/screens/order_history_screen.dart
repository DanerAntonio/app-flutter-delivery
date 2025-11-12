// screens/order_history_screen.dart - VERSIÓN DEBUG

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../models/order.dart' as local_order;

class OrderHistoryScreen extends StatelessWidget {
  final String userId;

  const OrderHistoryScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Historial de Pedidos"),
        backgroundColor: Colors.deepOrange,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text('Error al cargar los pedidos'),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No tienes pedidos aún'),
            );
          }

          final orders = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final doc = orders[index];
              final data = doc.data() as Map<String, dynamic>;
              
              // DEBUG: Mostrar todos los campos disponibles
              print('=== DEBUG PEDIDO ${data['orderNumber']} ===');
              print('Campos disponibles: ${data.keys.toList()}');
              print('verificationCode: ${data['verificationCode']}');
              print('status: ${data['status']}');

              final order = local_order.Order.fromMap(data, doc.id);
              final bool isActiveOrder = order.status == 'pendiente' || 
                                       order.status == 'confirmado' || 
                                       order.status == 'asignado' || 
                                       order.status == 'en camino';

              // Obtener código directamente de Firestore (por si acaso)
              final verificationCodeFromFirestore = data['verificationCode']?.toString() ?? 'NO_ENCONTRADO';

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  leading: Icon(
                    Icons.receipt_long,
                    color: isActiveOrder ? Colors.deepOrange : Colors.grey,
                  ),
                  title: Text(
                    "Pedido #${order.orderNumber}",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text("Total: \$${order.total.toStringAsFixed(0)}"),
                      const SizedBox(height: 2),
                      Text(
                        "Fecha: ${DateFormat('yyyy-MM-dd HH:mm').format(order.timestamp)}",
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Estado: ${order.status}",
                        style: TextStyle(
                          color: _getStatusColor(order.status),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      
                      // SECCIÓN DE DEBUG - MOSTRAR SIEMPRE EL CÓDIGO
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.bug_report, size: 16, color: Colors.red.shade700),
                                const SizedBox(width: 6),
                                const Text(
                                  'DEBUG - Código:',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              verificationCodeFromFirestore,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Desde Firestore: $verificationCodeFromFirestore',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade600,
                              ),
                            ),
                            Text(
                              'Desde Modelo: ${order.verificationCode}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.red.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // CÓDIGO NORMAL (solo para pedidos activos)
                      if (isActiveOrder && verificationCodeFromFirestore != 'NO_ENCONTRADO') ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lock, size: 16, color: Colors.blue.shade700),
                              const SizedBox(width: 6),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Código de verificación:',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade700,
                                    ),
                                  ),
                                  Text(
                                    verificationCodeFromFirestore,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Entregue este código al repartidor',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isActiveOrder ? Icons.pending_actions : Icons.check_circle,
                        color: isActiveOrder ? Colors.orange : Colors.green,
                      ),
                      Text(
                        "${order.items.length} items",
                        style: TextStyle(
                          fontSize: 10,
                          color: isActiveOrder ? Colors.orange : Colors.green,
                        ),
                      ),
                    ],
                  ),
                  onTap: () {
                    _showOrderDetails(context, order, data);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showOrderDetails(BuildContext context, local_order.Order order, Map<String, dynamic> firestoreData) {
    final verificationCode = firestoreData['verificationCode']?.toString() ?? 'NO DISPONIBLE';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.receipt_long, color: Colors.deepOrange),
            const SizedBox(width: 8),
            Text('Pedido #${order.orderNumber}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // INFORMACIÓN BÁSICA
              _buildDetailRow('Estado:', order.status, _getStatusColor(order.status)),
              _buildDetailRow('Total:', '\$${order.total.toStringAsFixed(0)}', Colors.black),
              _buildDetailRow('Fecha:', DateFormat('yyyy-MM-dd HH:mm').format(order.timestamp), Colors.grey),
              
              // CÓDIGO DE VERIFICACIÓN (SIEMPRE MOSTRAR)
              const SizedBox(height: 16),
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
                    Row(
                      children: [
                        Icon(Icons.lock, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        const Text(
                          'Código de Verificación',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      verificationCode,
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 8,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ID del pedido: ${order.id}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendiente': return Colors.orange;
      case 'confirmado': return Colors.blue;
      case 'asignado': return Colors.blue;
      case 'en camino': return Colors.deepPurple;
      case 'entregado': return Colors.green;
      default: return Colors.grey;
    }
  }
}