import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

/// Pantalla de configuración del costo de domicilio
/// Permite al administrador definir:
/// - Costo del domicilio
/// - Porcentaje que recibe el domiciliario
class DeliveryConfigScreen extends StatefulWidget {
  const DeliveryConfigScreen({super.key});

  @override
  State<DeliveryConfigScreen> createState() => _DeliveryConfigScreenState();
}

class _DeliveryConfigScreenState extends State<DeliveryConfigScreen> {
  final _formKey = GlobalKey<FormState>();
  final _feeController = TextEditingController();
  final _percentageController = TextEditingController();
  
  bool isLoading = false;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  @override
  void dispose() {
    _feeController.dispose();
    _percentageController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentConfig() async {
    setState(() => isLoading = true);
    
    try {
      final doc = await FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery')
          .get();
      
      if (doc.exists) {
        final data = doc.data()!;
        _feeController.text = (data['fee'] ?? 4000).toString();
        _percentageController.text = (data['driverPercentage'] ?? 100).toString();
      } else {
        // Valores por defecto
        _feeController.text = '4000';
        _percentageController.text = '100';
      }
    } catch (e) {
      _showSnackBar('Error al cargar configuración: $e', false);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      final fee = double.parse(_feeController.text);
      final percentage = double.parse(_percentageController.text);

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('delivery')
          .set({
        'fee': fee,
        'driverPercentage': percentage,
        'updatedAt': Timestamp.now(),
      });

      _showSnackBar('Configuración guardada exitosamente', true);
    } catch (e) {
      _showSnackBar('Error al guardar: $e', false);
    } finally {
      setState(() => isSaving = false);
    }
  }

  void _showSnackBar(String message, bool isSuccess) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isSuccess ? Colors.green.shade600 : Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
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
        title: const Text(
          'Configuración de Domicilio',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header explicativo
                    Card(
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
                                size: 32,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Gestión de Domicilios',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Configure el costo y la compensación para los domiciliarios',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Costo del domicilio
                    Text(
                      'Costo del Domicilio',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _feeController,
                      decoration: InputDecoration(
                        labelText: 'Costo en COP',
                        prefixIcon: const Icon(Icons.attach_money),
                        hintText: '4000',
                        helperText: 'Este valor se cobrará al cliente por cada pedido',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El costo es obligatorio';
                        }
                        final fee = double.tryParse(value);
                        if (fee == null || fee < 0) {
                          return 'Ingrese un valor válido';
                        }
                        if (fee < 1000) {
                          return 'El mínimo recomendado es \$1,000';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Porcentaje para el domiciliario
                    Text(
                      'Compensación del Domiciliario',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _percentageController,
                      decoration: InputDecoration(
                        labelText: 'Porcentaje (%)',
                        prefixIcon: const Icon(Icons.percent),
                        hintText: '100',
                        helperText: 'Porcentaje del costo de domicilio que recibe el repartidor',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'El porcentaje es obligatorio';
                        }
                        final percentage = double.tryParse(value);
                        if (percentage == null || percentage < 0 || percentage > 100) {
                          return 'Ingrese un valor entre 0 y 100';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Vista previa de cálculo
                    StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('settings')
                          .doc('delivery')
                          .snapshots(),
                      builder: (context, snapshot) {
                        double currentFee = 4000;
                        double currentPercentage = 100;

                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>;
                          currentFee = (data['fee'] ?? 4000).toDouble();
                          currentPercentage = (data['driverPercentage'] ?? 100).toDouble();
                        }

                        final previewFee = double.tryParse(_feeController.text) ?? currentFee;
                        final previewPercentage = double.tryParse(_percentageController.text) ?? currentPercentage;
                        final driverEarnings = previewFee * (previewPercentage / 100);

                        return Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.calculate, color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Vista Previa',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Cliente paga:'),
                                    Text(
                                      '\$${previewFee.toStringAsFixed(0)}',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Domiciliario recibe ($previewPercentage%):'),
                                    Text(
                                      '\$${driverEarnings.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                        fontSize: 18,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 32),

                    // Botón guardar
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : _saveConfig,
                        icon: isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save),
                        label: Text(isSaving ? 'Guardando...' : 'Guardar Configuración'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Información adicional
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
                                    color: Colors.blue.shade700,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '• El costo de domicilio se muestra al cliente antes de confirmar el pedido\n'
                              '• Los cambios se aplican inmediatamente para nuevos pedidos\n'
                              '• El porcentaje define cuánto recibe el domiciliario de cada entrega\n'
                              '• Los pedidos anteriores mantienen su costo original',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.blue.shade900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}