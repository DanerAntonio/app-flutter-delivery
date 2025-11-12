import 'package:flutter/material.dart';

// AGREGAR ENUM PARA TIPOS DE PRODUCTO
enum ProductType {
  finishedProduct,  // Plato terminado
  ingredient        // Ingrediente para armar platos
}

class InventoryProduct {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final double stock;
  final double minStock;
  final String unit;
  final bool active;
  final DateTime createdAt;
  final DateTime lastUpdated;
  
  // NUEVAS PROPIEDADES PARA INGREDIENTES
  final ProductType productType;
  final List<String>? categories;
  final double? costPrice;

  InventoryProduct({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    required this.stock,
    required this.minStock,
    required this.unit,
    required this.active,
    DateTime? createdAt,
    DateTime? lastUpdated,
    // NUEVOS PARÁMETROS CON VALORES POR DEFECTO
    this.productType = ProductType.finishedProduct,
    this.categories,
    this.costPrice,
  })  : createdAt = createdAt ?? DateTime.now(),
        lastUpdated = lastUpdated ?? DateTime.now();

  // Getter para verificar si el stock está bajo
  bool get isLowStock => stock <= minStock;

  // Color según el estado del stock
  Color get stockColor {
    if (stock <= 0) return Colors.red;
    if (isLowStock) return Colors.orange;
    return Colors.green;
  }

  // Icono según el estado del stock
  IconData get stockIcon {
    if (stock <= 0) return Icons.warning;
    if (isLowStock) return Icons.warning_amber;
    return Icons.check_circle;
  }

  // Texto del estado del stock
  String get stockStatus {
    if (stock <= 0) return 'AGOTADO';
    if (isLowStock) return 'STOCK BAJO';
    return 'DISPONIBLE';
  }

  // NUEVO: Getter para saber si es ingrediente
  bool get isIngredient => productType == ProductType.ingredient;

  // NUEVO: Getter para saber si es producto terminado
  bool get isFinishedProduct => productType == ProductType.finishedProduct;

  // Crear desde Map (Firestore)
  factory InventoryProduct.fromMap(Map<String, dynamic> map) {
    return InventoryProduct(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      stock: (map['stock'] ?? 0).toDouble(),
      minStock: (map['minStock'] ?? 0).toDouble(),
      unit: map['unit'] ?? 'unidades',
      active: _parseBool(map['active']),
      createdAt: map['createdAt'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : DateTime.now(),
      lastUpdated: map['lastUpdated'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(map['lastUpdated'])
          : DateTime.now(),
      // NUEVAS PROPIEDADES EN fromMap
      productType: map['productType'] != null 
          ? ProductType.values.firstWhere(
              (e) => e.name == map['productType'],
              orElse: () => ProductType.finishedProduct)
          : ProductType.finishedProduct,
      categories: map['categories'] != null 
          ? List<String>.from(map['categories'])
          : null,
      costPrice: (map['costPrice'] ?? 0).toDouble(),
    );
  }

  // Helper para parsear bool desde string o bool
  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is String) return value.toLowerCase() == 'true';
    return false;
  }

  // Convertir a Map (para Firestore) - ACTUALIZADO
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'stock': stock,
      'minStock': minStock,
      'unit': unit,
      'active': active,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch,
      // NUEVAS PROPIEDADES EN toMap
      'productType': productType.name,
      'categories': categories,
      'costPrice': costPrice,
    };
  }

  // Método copyWith para actualizaciones inmutables - ACTUALIZADO
  InventoryProduct copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? category,
    double? stock,
    double? minStock,
    String? unit,
    bool? active,
    DateTime? createdAt,
    DateTime? lastUpdated,
    // NUEVOS PARÁMETROS EN copyWith
    ProductType? productType,
    List<String>? categories,
    double? costPrice,
  }) {
    return InventoryProduct(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      unit: unit ?? this.unit,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? DateTime.now(),
      // NUEVAS PROPIEDADES EN copyWith
      productType: productType ?? this.productType,
      categories: categories ?? this.categories,
      costPrice: costPrice ?? this.costPrice,
    );
  }

  @override
  String toString() {
    return 'InventoryProduct(id: $id, name: $name, stock: $stock, isLowStock: $isLowStock, productType: $productType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is InventoryProduct && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}