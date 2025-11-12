// lib/models/courier_account.dart
import 'package:cloud_firestore/cloud_firestore.dart';

// ============================================================================
// MODELO DE TRANSACCIÓN
// ============================================================================
class CourierTransaction {
  final String type; // 'order_cash', 'order_transfer', 'payment', 'adjustment'
  final double amount;
  final String orderId;
  final DateTime timestamp;
  final String? note;

  CourierTransaction({
    required this.type,
    required this.amount,
    required this.orderId,
    required this.timestamp,
    this.note,
  });

  factory CourierTransaction.fromMap(Map<String, dynamic> data) {
    return CourierTransaction(
      type: data['type'] ?? '',
      amount: (data['amount'] ?? 0).toDouble(),
      orderId: data['orderId'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      note: data['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'orderId': orderId,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}

// ============================================================================
// MODELO DE CUENTA DEL DOMICILIARIO
// ============================================================================
class CourierAccount {
  final String courierId;
  final double currentBalance;
  final double totalEarned;
  final int completedOrders;
  final bool isBlocked;
  final bool canAcceptCash;
  final bool adminOverride;
  final List<CourierTransaction> transactions;
  final DateTime createdAt;
  final DateTime? lastPaymentAt;

  CourierAccount({
    required this.courierId,
    this.currentBalance = 0,
    this.totalEarned = 0,
    this.completedOrders = 0,
    this.isBlocked = false,
    this.canAcceptCash = false,
    this.adminOverride = false,
    this.transactions = const [],
    required this.createdAt,
    this.lastPaymentAt,
  });

  bool get canTakeCashOrders {
    if (adminOverride) return true;
    if (isBlocked) return false;
    if (totalEarned >= 50000) return true;
    if (currentBalance >= 0 && completedOrders >= 5) return true;
    return false;
  }

  bool get isNearCreditLimit => currentBalance < -40000 && currentBalance > -50000;

  bool get shouldBeBlocked => currentBalance <= -50000 && !adminOverride;

  String get statusMessage {
    if (isBlocked) return '🚫 Bloqueado - Consigna el dinero pendiente';
    if (isNearCreditLimit) return '⚠️ Cerca del límite - Consigna pronto';
    if (currentBalance < 0) return '💰 Debes \$${(-currentBalance).toStringAsFixed(0)}';
    if (currentBalance > 0) return '✅ Te deben \$${currentBalance.toStringAsFixed(0)}';
    return '✅ Al día';
  }

  factory CourierAccount.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CourierAccount(
      courierId: doc.id,
      currentBalance: (data['currentBalance'] ?? 0).toDouble(),
      totalEarned: (data['totalEarned'] ?? 0).toDouble(),
      completedOrders: data['completedOrders'] ?? 0,
      isBlocked: data['isBlocked'] ?? false,
      canAcceptCash: data['canAcceptCash'] ?? false,
      adminOverride: data['adminOverride'] ?? false,
      transactions: (data['transactions'] as List<dynamic>?)
              ?.map((t) => CourierTransaction.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastPaymentAt: (data['lastPaymentAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'currentBalance': currentBalance,
      'totalEarned': totalEarned,
      'completedOrders': completedOrders,
      'isBlocked': isBlocked,
      'canAcceptCash': canAcceptCash,
      'adminOverride': adminOverride,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastPaymentAt': lastPaymentAt != null ? Timestamp.fromDate(lastPaymentAt!) : null,
    };
  }
}
