import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/courier_account.dart';

class CourierCreditService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtener cuenta del domiciliario
  static Future<CourierAccount> getCourierAccount(String courierId) async {
    try {
      final doc = await _firestore.collection('courier_accounts').doc(courierId).get();
      
      if (!doc.exists) {
        final newAccount = CourierAccount(
          courierId: courierId,
          createdAt: DateTime.now(),
        );
        await _firestore.collection('courier_accounts').doc(courierId).set(newAccount.toFirestore());
        return newAccount;
      }
      
      return CourierAccount.fromFirestore(doc);
    } catch (e) {
      print('❌ Error obteniendo cuenta: $e');
      rethrow;
    }
  }

  // Verificar si el domiciliario puede tomar un pedido
  static Future<Map<String, dynamic>> canTakeOrder(
    String courierId,
    String paymentMethod,
  ) async {
    try {
      final account = await getCourierAccount(courierId);

      // Si el pedido es por transferencia, siempre puede
      if (paymentMethod == 'transferencia') {
        return {'canTake': true, 'reason': '', 'warning': null};
      }

      // Si el pedido es en efectivo
      if (paymentMethod == 'efectivo') {
        // Verificar si está bloqueado
        if (account.shouldBeBlocked) {
          return {
            'canTake': false,
            'reason': '🚫 Estás bloqueado\n\nDebes consignar \$${(-account.currentBalance).toStringAsFixed(0)} para poder seguir aceptando pedidos en efectivo.',
            'warning': null,
          };
        }

        // Verificar si puede aceptar efectivo
        if (!account.canTakeCashOrders) {
          return {
            'canTake': false,
            'reason': '⚠️ No puedes aceptar pedidos en efectivo aún\n\nCompleta más pedidos por transferencia o contacta al administrador.\n\nGanancias acumuladas: \$${account.totalEarned.toStringAsFixed(0)}\nNecesitas: \$50,000',
            'warning': null,
          };
        }

        // Advertencia si está cerca del límite
        if (account.isNearCreditLimit) {
          return {
            'canTake': true,
            'reason': '',
            'warning': '⚠️ IMPORTANTE: Estás cerca del límite de crédito (\$50,000)\n\nDebes: \$${(-account.currentBalance).toStringAsFixed(0)}\n\n¡Consigna pronto para evitar bloqueo!',
          };
        }
      }

      return {'canTake': true, 'reason': '', 'warning': null};
    } catch (e) {
      print('❌ Error verificando capacidad: $e');
      return {'canTake': false, 'reason': 'Error al verificar tu cuenta', 'warning': null};
    }
  }

  // Registrar entrega de pedido
  static Future<void> registerOrderDelivery({
    required String courierId,
    required String orderId,
    required String paymentMethod,
    required double totalAmount,
    required double deliveryFee,
  }) async {
    try {
      final accountRef = _firestore.collection('courier_accounts').doc(courierId);
      
      await _firestore.runTransaction((firebaseTransaction) async {
        final accountDoc = await firebaseTransaction.get(accountRef);
        
        CourierAccount account;
        if (!accountDoc.exists) {
          account = CourierAccount(
            courierId: courierId,
            createdAt: DateTime.now(),
          );
        } else {
          account = CourierAccount.fromFirestore(accountDoc);
        }

        double balanceChange = 0;
        String transactionType = '';
        String note = '';

        if (paymentMethod == 'efectivo') {
          final mustDeposit = totalAmount - deliveryFee;
          balanceChange = -mustDeposit;
          transactionType = 'order_cash';
          note = 'Debes consignar \$${mustDeposit.toStringAsFixed(0)} (Total: \$${totalAmount.toStringAsFixed(0)} - Tu ganancia: \$${deliveryFee.toStringAsFixed(0)})';
        } else {
          balanceChange = deliveryFee;
          transactionType = 'order_transfer';
          note = 'Ganaste \$${deliveryFee.toStringAsFixed(0)} por entrega';
        }

        final newBalance = account.currentBalance + balanceChange;
        final newTotalEarned = account.totalEarned + deliveryFee;
        final newCompletedOrders = account.completedOrders + 1;

        final shouldBlock = newBalance <= -50000 && !account.adminOverride;

        final canAcceptCash = account.adminOverride || 
                             newTotalEarned >= 50000 || 
                             (newBalance >= 0 && newCompletedOrders >= 5);

        final newTransaction = CourierTransaction(
          type: transactionType,
          amount: balanceChange,
          orderId: orderId,
          timestamp: DateTime.now(),
          note: note,
        );

        final updatedTransactions = [...account.transactions, newTransaction];

        final updateData = {
          'currentBalance': newBalance,
          'totalEarned': newTotalEarned,
          'completedOrders': newCompletedOrders,
          'isBlocked': shouldBlock,
          'canAcceptCash': canAcceptCash,
          'transactions': updatedTransactions.map((t) => t.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        };

        if (!accountDoc.exists) {
          updateData['createdAt'] = Timestamp.now();
          updateData['courierId'] = courierId;
        }

        firebaseTransaction.set(accountRef, updateData, SetOptions(merge: true));
      });

      print('✅ Balance actualizado para domiciliario $courierId');
    } catch (e) {
      print('❌ Error actualizando balance: $e');
      rethrow;
    }
  }

  // Registrar consignación del domiciliario
  static Future<void> registerPayment(
    String courierId,
    double amount,
    String? note,
  ) async {
    try {
      final accountRef = _firestore.collection('courier_accounts').doc(courierId);
      
      await _firestore.runTransaction((firebaseTransaction) async {
        final accountDoc = await firebaseTransaction.get(accountRef);
        final account = CourierAccount.fromFirestore(accountDoc);

        final newBalance = account.currentBalance + amount;
        final shouldBlock = newBalance <= -50000 && !account.adminOverride;

        final newTransaction = CourierTransaction(
          type: 'payment',
          amount: amount,
          orderId: 'payment',
          timestamp: DateTime.now(),
          note: note ?? 'Consignación registrada',
        );

        final updatedTransactions = [...account.transactions, newTransaction];

        firebaseTransaction.update(accountRef, {
          'currentBalance': newBalance,
          'isBlocked': shouldBlock,
          'lastPaymentAt': Timestamp.now(),
          'transactions': updatedTransactions.map((t) => t.toMap()).toList(),
          'updatedAt': Timestamp.now(),
        });
      });

      print('✅ Pago registrado: \$$amount para $courierId');
    } catch (e) {
      print('❌ Error registrando pago: $e');
      rethrow;
    }
  }

  // Admin: Autorizar manualmente a un domiciliario
  static Future<void> adminAuthorize(String courierId, bool authorize) async {
    try {
      await _firestore.collection('courier_accounts').doc(courierId).set({
        'adminOverride': authorize,
        'canAcceptCash': authorize,
        'isBlocked': false,
        'updatedAt': Timestamp.now(),
      }, SetOptions(merge: true));
      
      print('✅ Domiciliario ${authorize ? "autorizado" : "desautorizado"}');
    } catch (e) {
      print('❌ Error en autorización: $e');
      rethrow;
    }
  }

  // Obtener stream de la cuenta
  static Stream<CourierAccount> watchCourierAccount(String courierId) {
    return _firestore
        .collection('courier_accounts')
        .doc(courierId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) {
        return CourierAccount(
          courierId: courierId,
          createdAt: DateTime.now(),
        );
      }
      return CourierAccount.fromFirestore(doc);
    });
  }
}
