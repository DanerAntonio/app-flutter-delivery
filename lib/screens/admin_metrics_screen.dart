import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({super.key});

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String _selectedDateFilter = 'hoy';
  DateTime _selectedDate = DateTime.now();
  final Map<String, String> _dateFilters = {
    'hoy': 'Hoy',
    'ayer': 'Ayer',
    'semana': 'Esta semana',
    'mes': 'Este mes',
    'personalizado': 'Personalizado',
  };

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _selectedDateFilter = 'personalizado';
      });
    }
  }

  List<QueryDocumentSnapshot> _filterOrdersByDate(List<QueryDocumentSnapshot> orders) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedDateFilter) {
      case 'ayer':
        startDate = DateTime(now.year, now.month, now.day - 1);
        endDate = DateTime(now.year, now.month, now.day - 1, 23, 59, 59);
        break;
      case 'semana':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'mes':
        startDate = DateTime(now.year, now.month - 1, now.day);
        break;
      case 'personalizado':
        startDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        endDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
        break;
      default: // hoy
        startDate = DateTime(now.year, now.month, now.day);
    }

    return orders.where((order) {
      final orderDate = (order['createdAt'] as Timestamp).toDate();
      return orderDate.isAfter(startDate) && orderDate.isBefore(endDate);
    }).toList();
  }

  Map<String, dynamic> _calculateMetrics(List<QueryDocumentSnapshot> filteredOrders) {
    if (filteredOrders.isEmpty) {
      return {
        'totalPedidos': 0,
        'entregados': 0,
        'pendientes': 0,
        'totalVentas': 0.0,
        'ventasPorDia': {},
        'productosVendidos': {},
      };
    }

    final estados = filteredOrders.map((o) {
      return (o['status'] ?? '').toString().toLowerCase().trim();
    }).toList();

    final int totalPedidos = filteredOrders.length;
    final int entregados = estados.where((e) => e == 'entregado').length;
    final int pendientes = estados.where((e) => e == 'pendiente').length;

    final double totalVentas = filteredOrders.fold(
      0.0,
      (sum, o) => sum + (((o['total'] ?? 0) as num).toDouble()),
    );

    // Ventas por día
    final Map<String, double> ventasPorDia = {};
    for (var o in filteredOrders) {
      if (o['createdAt'] != null && o['createdAt'] is Timestamp) {
        final fechaKey = DateFormat('dd/MM').format((o['createdAt'] as Timestamp).toDate());
        ventasPorDia[fechaKey] = (ventasPorDia[fechaKey] ?? 0.0) + (((o['total'] ?? 0) as num).toDouble());
      }
    }

    // Productos más vendidos
    final Map<String, int> productosVendidos = {};
    for (var o in filteredOrders) {
      final items = o['items'] as List? ?? o['products'] as List? ?? [];
      for (var item in items) {
        final productName = item['name']?.toString() ?? '';
        final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
        if (productName.isNotEmpty) {
          productosVendidos[productName] = (productosVendidos[productName] ?? 0) + quantity;
        }
      }
    }

    return {
      'totalPedidos': totalPedidos,
      'entregados': entregados,
      'pendientes': pendientes,
      'totalVentas': totalVentas,
      'ventasPorDia': ventasPorDia,
      'productosVendidos': productosVendidos,
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('orders').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = snapshot.data!.docs;
        final filteredOrders = _filterOrdersByDate(allOrders);
        final metrics = _calculateMetrics(filteredOrders);

        if (allOrders.isEmpty) {
          return const Center(
            child: Text("📊 No hay pedidos registrados aún"),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Filtros de fecha
              _buildDateFilters(),
              const SizedBox(height: 20),

              // KPIs
              _buildKpiRow(metrics),
              const SizedBox(height: 20),

              // Gráficos
              if (filteredOrders.isNotEmpty) ...[
                _buildOrdersChart(metrics),
                const SizedBox(height: 20),
                _buildSalesChart(metrics),
                const SizedBox(height: 20),
                _buildTopProducts(metrics),
              ] else ...[
                _buildNoDataMessage(),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateFilters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Filtrar por fecha:',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _dateFilters.entries.map((entry) {
            final isSelected = entry.key == _selectedDateFilter;
            return FilterChip(
              label: Text(entry.value),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedDateFilter = entry.key;
                  if (entry.key == 'personalizado') {
                    _selectDate(context);
                  }
                });
              },
              selectedColor: Colors.deepOrange,
              checkmarkColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
              ),
            );
          }).toList(),
        ),
        if (_selectedDateFilter == 'personalizado') ...[
          const SizedBox(height: 8),
          Text(
            'Fecha seleccionada: ${DateFormat('dd/MM/yyyy').format(_selectedDate)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ],
    );
  }

  Widget _buildKpiRow(Map<String, dynamic> metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _kpiCard("Pedidos", metrics['totalPedidos'], Icons.shopping_cart, Colors.orange),
        _kpiCard("Ventas", metrics['totalVentas'], Icons.attach_money, Colors.green),
        _kpiCard("Entregados", metrics['entregados'], Icons.check_circle, Colors.blue),
      ],
    );
  }

  Widget _kpiCard(String title, dynamic value, IconData icon, Color color) {
    String displayValue;
    if (value is double) {
      displayValue = '\$${value.toStringAsFixed(0)}';
    } else {
      displayValue = value.toString();
    }

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(16),
        width: 110,
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              displayValue,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersChart(Map<String, dynamic> metrics) {
    final pedidosPorEstado = {
      'Pendiente': metrics['pendientes'],
      'Entregado': metrics['entregados'],
      'Otros': metrics['totalPedidos'] - metrics['pendientes'] - metrics['entregados'],
    };

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "📊 Pedidos por estado",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: (pedidosPorEstado.values.reduce((a, b) => a > b ? a : b) + 2).toDouble(),
                  barGroups: pedidosPorEstado.entries.map((entry) {
                    final index = pedidosPorEstado.keys.toList().indexOf(entry.key);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.toDouble(),
                          width: 20,
                          borderRadius: BorderRadius.circular(4),
                          color: _getStatusColor(entry.key),
                        ),
                      ],
                    );
                  }).toList(),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final keys = pedidosPorEstado.keys.toList();
                          if (index >= 0 && index < keys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(keys[index], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesChart(Map<String, dynamic> metrics) {
    final ventasPorDia = metrics['ventasPorDia'] as Map<String, double>;
    final entriesList = ventasPorDia.entries.toList()
      ..sort((a, b) {
        try {
          final da = DateFormat('dd/MM').parse(a.key);
          final db = DateFormat('dd/MM').parse(b.key);
          return da.compareTo(db);
        } catch (e) {
          return 0;
        }
      });

    final List<FlSpot> spots = List<FlSpot>.generate(entriesList.length, (i) {
      return FlSpot(i.toDouble(), entriesList[i].value);
    });

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "📈 Ventas por día",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: spots.isNotEmpty ? (spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 1000) : 1000,
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: spots,
                      barWidth: 3,
                      dotData: FlDotData(show: true),
                      belowBarData: BarAreaData(show: true, color: Colors.blue.withOpacity(0.2)),
                      color: Colors.blueAccent,
                    ),
                  ],
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 36,
                        getTitlesWidget: (value, meta) {
                          final intIndex = value.toInt();
                          if (intIndex >= 0 && intIndex < entriesList.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 6.0),
                              child: Text(entriesList[intIndex].key, style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: true),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopProducts(Map<String, dynamic> metrics) {
    final productosVendidos = metrics['productosVendidos'] as Map<String, int>;
    final topProducts = productosVendidos.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value))
      ..take(5);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "🏆 Productos más vendidos",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (topProducts.isNotEmpty) ...[
              Column(
                children: topProducts.map((entry) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.deepOrange.shade100,
                    child: Text(
                      entry.value.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(entry.key),
                  trailing: Text('${entry.value} vendidos'),
                )).toList(),
              )
            ] else ...[
              const Text('No hay datos de productos vendidos'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataMessage() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.bar_chart, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No hay datos para el período seleccionado',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta con otro rango de fechas',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pendiente': return Colors.orange;
      case 'Entregado': return Colors.green;
      default: return Colors.blue;
    }
  }
}