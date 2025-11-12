import 'package:cloud_firestore/cloud_firestore.dart';

class OrderItem {
  final String name;
  final double price;
  final int quantity;

  OrderItem({
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory OrderItem.fromMap(Map<String, dynamic> data) {
    return OrderItem(
      name: data['name'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final List<OrderItem> items;
  final DateTime timestamp;
  final double total;
  final double deliveryFee; // NUEVO: Siempre $4,000
  final double subtotal; // NUEVO: Total - deliveryFee
  final String status;
  final String verificationCode;
  final bool isVerified;
  final String? courierId; // NUEVO: ID del domiciliario asignado
  final String paymentMethod; // NUEVO: 'cash' o 'transfer'
  final bool courierPaid; // NUEVO: ¿Ya se le pagó al domiciliario?

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.items,
    required this.timestamp,
    required this.total,
    this.deliveryFee = 4000,
    double? subtotal,
    required this.status,
    this.verificationCode = '',
    this.isVerified = false,
    this.courierId,
    this.paymentMethod = 'transfer',
    this.courierPaid = false,
  }) : subtotal = subtotal ?? (total - 4000);

  // Cuánto debe consignar el domiciliario (si es en efectivo)
  double get courierMustDeposit {
    if (paymentMethod == 'transfer') return 0;
    return total - deliveryFee; // Total menos sus $4,000
  }

  factory Order.fromMap(Map<String, dynamic> data, String documentId) {
    final total = (data['total'] ?? 0).toDouble();
    final deliveryFee = (data['deliveryFee'] ?? 4000).toDouble();
    
    return Order(
      id: documentId,
      userId: data['userId'] ?? '',
      orderNumber: data['orderNumber'] ?? '',
      items: (data['products'] as List<dynamic>?)?.map((item) {
            return OrderItem.fromMap(item as Map<String, dynamic>);
          }).toList() ??
          [],
      timestamp: data['createdAt'] != null && data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      total: total,
      deliveryFee: deliveryFee,
      subtotal: (data['subtotal'] ?? (total - deliveryFee)).toDouble(),
      status: data['status'] ?? 'pendiente',
      verificationCode: data['verificationCode'] ?? '',
      isVerified: data['isVerified'] ?? false,
      courierId: data['courierId'],
      paymentMethod: data['paymentMethod'] ?? 'transfer',
      courierPaid: data['courierPaid'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'orderNumber': orderNumber,
      'products': items.map((item) => item.toMap()).toList(),
      'createdAt': Timestamp.fromDate(timestamp),
      'total': total,
      'deliveryFee': deliveryFee,
      'subtotal': subtotal,
      'status': status,
      'verificationCode': verificationCode,
      'isVerified': isVerified,
      'courierId': courierId,
      'paymentMethod': paymentMethod,
      'courierPaid': courierPaid,
    };
  }
}