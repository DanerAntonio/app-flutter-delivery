class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  int quantity;
  

  /// Lista de opciones seleccionadas (por ejemplo: "Arroz", "Pollo", etc.)
  final List<String>? selectedOptions;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.quantity = 1,
    this.selectedOptions,
  });

  /// Convierte el producto a un mapa (para guardar en Firebase)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'quantity': quantity,
      'selectedOptions': selectedOptions ?? [],
    };
  }

  /// Crea un producto desde un mapa (al leer de Firebase)
  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      price: (map['price'] is int) ? (map['price'] as int).toDouble() : (map['price'] ?? 0.0),
      imageUrl: map['imageUrl'] ?? '',
      category: map['category'] ?? '',
      quantity: map['quantity'] ?? 1,
      selectedOptions: List<String>.from(map['selectedOptions'] ?? []),
    );
  }
}
