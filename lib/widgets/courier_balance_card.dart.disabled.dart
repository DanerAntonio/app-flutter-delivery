import 'package:flutter/material.dart';
import '../models/courier_account.dart';

class CourierBalanceCard extends StatelessWidget {
  final CourierAccount account;

  const CourierBalanceCard({
    super.key,
    required this.account,
  });

  @override
  Widget build(BuildContext context) {
    Theme.of(context);
    final isNegative = account.currentBalance < 0;
    final color = account.isBlocked
        ? Colors.red
        : account.isNearCreditLimit
            ? Colors.orange
            : isNegative
                ? Colors.amber
                : Colors.green;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.shade600, color.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                account.isBlocked
                    ? Icons.block
                    : isNegative
                        ? Icons.account_balance_wallet
                        : Icons.savings,
                color: Colors.white,
                size: 32,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isNegative ? 'Debes Consignar' : 'Saldo a Favor',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '\$${account.currentBalance.abs().toStringAsFixed(0)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  account.isBlocked
                      ? Icons.warning
                      : account.isNearCreditLimit
                          ? Icons.warning_amber
                          : Icons.info_outline,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    account.statusMessage,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStat('Pedidos', account.completedOrders.toString()),
              const SizedBox(width: 16),
              _buildStat('Ganado', '\$${account.totalEarned.toStringAsFixed(0)}'),
              const SizedBox(width: 16),
              _buildStat(
                'Efectivo',
                account.canTakeCashOrders ? 'SÍ' : 'NO',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}