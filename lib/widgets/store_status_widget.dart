// lib/widgets/store_status_widget.dart - VERSIÓN COMPACTA Y PROFESIONAL
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/store_service.dart';

class StoreStatusWidget extends StatelessWidget {
  final bool isAdmin;
  const StoreStatusWidget({super.key, this.isAdmin = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: StoreService.stream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildCompactStatus(
            context: context,
            isOpen: true,
            isLoading: true,
          );
        }

        if (snapshot.hasError) {
          return _buildCompactStatus(
            context: context,
            isOpen: false,
            hasError: true,
          );
        }

        final isOpen = StoreService.isOpenNow(snapshot.data);

        return _buildCompactStatus(
          context: context,
          isOpen: isOpen,
          onToggle: isAdmin ? () => _toggleStore(context, isOpen) : null,
        );
      },
    );
  }

  Widget _buildCompactStatus({
    required BuildContext context,
    required bool isOpen,
    bool isLoading = false,
    bool hasError = false,
    VoidCallback? onToggle,
  }) {
    
    // Colores según estado
    final statusColor = hasError 
        ? Colors.orange 
        : (isOpen ? Colors.green : Colors.red);
    
    final backgroundColor = hasError
        ? Colors.orange.withOpacity(0.1)
        : (isOpen 
            ? Colors.green.withOpacity(0.1) 
            : Colors.red.withOpacity(0.1));

    // Texto según estado
    String statusText;
    IconData statusIcon;
    
    if (isLoading) {
      statusText = "Cargando...";
      statusIcon = Icons.hourglass_empty_rounded;
    } else if (hasError) {
      statusText = "Error de conexión";
      statusIcon = Icons.warning_amber_rounded;
    } else {
      statusText = isOpen ? "ABIERTO" : "CERRADO";
      statusIcon = isOpen ? Icons.store_rounded : Icons.store_mall_directory_rounded;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Indicador de estado (círculo animado)
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            builder: (context, value, child) {
              return Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(value),
                  shape: BoxShape.circle,
                  boxShadow: isOpen && !isLoading && !hasError
                      ? [
                          BoxShadow(
                            color: statusColor.withOpacity(0.4 * value),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
              );
            },
          ),
          
          const SizedBox(width: 12),
          
          // Ícono de estado
          Icon(
            statusIcon,
            color: statusColor,
            size: 20,
          ),
          
          const SizedBox(width: 8),
          
          // Texto de estado
          if (isLoading)
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(statusColor),
              ),
            )
          else
            Text(
              statusText,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: statusColor,
                letterSpacing: 0.5,
              ),
            ),
          
          // Mensaje adicional (solo para usuarios no admin)
          if (!isAdmin && !isLoading && !hasError) ...[
            const SizedBox(width: 8),
            Text(
              "•",
              style: TextStyle(
                color: statusColor.withOpacity(0.5),
                fontSize: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOpen ? "Puedes hacer pedidos" : "No disponible ahora",
                style: TextStyle(
                  fontSize: 12,
                  color: statusColor.withOpacity(0.8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          
          // Botón admin (compacto e integrado)
          if (isAdmin && !isLoading && !hasError) ...[
            const Spacer(),
            Material(
              color: statusColor,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onToggle,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOpen ? Icons.close_rounded : Icons.check_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isOpen ? "Cerrar" : "Abrir",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _toggleStore(BuildContext context, bool currentState) async {
    final newState = !currentState;
    
    try {
      // Mostrar indicador de carga
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text("Actualizando estado..."),
            ],
          ),
          duration: const Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      
      await StoreService.setManualOpen(newState);
      
      if (!context.mounted) return;
      
      // Mostrar confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                newState ? Icons.check_circle : Icons.cancel,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(newState ? "✅ Tienda abierta" : "🚫 Tienda cerrada"),
            ],
          ),
          backgroundColor: newState ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text("Error: $e")),
            ],
          ),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }
}