import '../models/product.dart';

final List<Product> mockProducts = [
  Product(
    id: '1',
    name: 'CHUZOS DE POLLO',
    description: 'AREPA CON QUESO MOZARELLA, ENSALADA DULCE, TOCINETA, MAICITOS, PAPAS A LA FRANCESA Y GASEOSA',
    price: 18000,
    imageUrl: 'assets/images/CHUZO DE POLLO 2.jpeg',
    category: 'Parrilla',
  ),
  Product(
    id: '2',
    name: 'CHUZOS DE CERDO',
    description: 'AREPA CON QUESO MOZARELLA, ENSALADA DULCE, TOCINETA, MAICITOS, PAPAS A LA FRANCESA Y GASEOSA',
    price: 18000,
    imageUrl: 'assets/images/CHUZO DE CERDO 3.jpeg',
    category: 'Parrilla',
  ),
  Product(
    id: '3',
    name: 'TILAPIA FRITA',
    description: 'ARROZ DE COCO O BLANCO, PATACON, ENSALADA, COMSOME DE BAGRE, GUARAPO',
    price: 25000,
    imageUrl: 'assets/images/TILAPIA.jpeg',
    category: 'Platos Principales',
  ),
  Product(
    id: '4',
    name: 'MONDONGO',
    description: 'MONDONGO, COSTILLA DE CERDO AHUMADA, PERNIL DE CERDO, SECO, BANANO, ENSALADA, GUARAPO O CLARO',
    price: 25000,
    imageUrl: 'assets/images/MONDONGOO.jpeg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '5',
    name: 'SANCOCHO TRIFASICO ANTIOQUEÑO',
    description: 'CARNE DE SOBREBARRIGA, COSTILLA DE CERDO AHUMADA, POLLO, SECO, AGUACATE, ENSALADA, GUARAPO O CLARO',
    price: 25000,
    imageUrl: 'assets/images/SANCOCHO.jpeg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '6',
    name: 'BANDEJA PAISA',
    description: 'CARNE A LA PLANCHA, CHORIZO, CHICHARRÓN, FRIJOL, HUEVO, TAJADA DE MADURO, AGUACATE, SECO, ENSALADA, GUARAPO O CLARO',
    price: 25000,
    imageUrl: 'assets/images/bandeja paisa.jpg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '7',
    name: 'ARROZ PAISA (2 PERSONAS)',
    description: '#1 PROMOCIÓN: ARROZ PAISA 600 GRAMOS PARA 2 PERSONAS, COSTILLA A LA BBQ, PAPAS A LA FRANCESA, 2 GASEOSAS',
    price: 30000,
    imageUrl: 'assets/images/arroz1.jpeg',
    category: 'Promociones',
  ),
  Product(
    id: '8',
    name: 'ARROZ PAISA (4 PERSONAS)',
    description: 'PROMOCIÓN: ARROZ PAISA 1200 GRAMOS PARA 4 PERSONAS, COSTILLA A LA BBQ, PAPAS A LA FRANCESA, 4 GASEOSAS',
    price: 50000,
    imageUrl: 'assets/images/arroz1.jpeg',
    category: 'Promociones',
  ),
  Product(
    id: '9',
    name: 'COMBO ALITAS PICANTES, BBQ, A LA NARANJA (1 PERSONA)',
    description: '8 ALITAS, PAPAS A LA FRANCESA, ENSALADA DULCE, GASEOSA',
    price: 18000,
    imageUrl: 'assets/images/alitas 1.jpeg',
    category: 'Combos',
  ),
  Product(
    id: '10',
    name: 'COMBO ALITAS PICANTES, BBQ, A LA NARANJA (2 PERSONAS)',
    description: '16 ALITAS, PAPAS A LA FRANCESA, ENSALADA DULCE, 2 GASEOSAS',
    price: 32000,
    imageUrl: 'assets/images/combo alitas 2 personas.jpg',
    category: 'Combos',
  ),
  Product(
    id: '11',
    name: 'ARROZ PAISA PERSONAL',
    description: '#2 ARROZ PAISA 300 GRAMOS PARA 1 PERSONA, COSTILLA A LA BBQ, PAPAS A LA FRANCESA, 1 GASEOSA',
    price: 20000,
    imageUrl: 'assets/images/arroz1.jpeg',
    category: 'Platos Principales',
  ),
  Product(
    id: '12',
    name: 'POSTA SUDADA',
    description: 'ARROZ, ENSALADA, FRIJOL O SOPA, TAJADA DE MADURO, GUARAPO, GASEOSA O CLARO, AGUACATE',
    price: 20000,
    imageUrl: 'assets/images/POSTA4.jpg',
    category: 'Platos Principales',
  ),
  Product(
    id: '13',
    name: 'HÍGADO ENCEBOLLADO',
    description: 'ARROZ, ENSALADA, FRIJOL O SOPA, AGUACATE, TAJADA DE MADURO, GUARAPO, GASEOSA O CLARO',
    price: 18000,
    imageUrl: 'assets/images/HIGADO ENCEBOLLADO1.jpg',
    category: 'Platos Principales',
  ),
  Product(
    id: '14',
    name: 'CARNE DE CERDO ESPECIAL ASADO AL BARRIL',
    description: '300 GRAMOS DE CERDO ESPECIAL ASADO AL BARRIL, SALSAS CHIMICHURRI Y HOGAO, AREPA CON MOZARELLA, PAPA COCIDA, 1 GASEOSA',
    price: 20000,
    imageUrl: 'assets/images/CARNE ASADA 2.jpeg',
    category: 'Parrilla',
  ),
  Product(
    id: '15',
    name: 'CARNE DE RES ASADA AL BARRIL',
    description: '300 GRAMOS DE RES ESPECIAL ASADA AL BARRIL, SALSAS CHIMICHURRI Y HOGAO, AREPA CON MOZARELLA, PAPA COCIDA, 1 GASEOSA',
    price: 21000,
    imageUrl: 'assets/images/CARNE ASADA 2.jpeg',
    category: 'Parrilla',
  ),
  Product(
    id: '16',
    name: 'CHICHARRÓN ASADO AL BARRIL',
    description: 'CHICHARRÓN ASADO AL BARRIL, SALSAS CHIMICHURRI Y HOGAO, AREPA CON MOZARELLA, PAPA COCIDA, 1 GASEOSA',
    price: 20000,
    imageUrl: 'assets/images/chicharron azado.jpg',
    category: 'Parrilla',
  ),
  Product(
    id: '17',
    name: 'CHORIZO ASADO AL BARRIL',
    description: 'CHORIZO DEL ORIENTE ASADO AL BARRIL, SALSAS CHIMICHURRI Y HOGAO, AREPA CON MOZARELLA, PAPA COCIDA, 1 GASEOSA',
    price: 18000,
    imageUrl: 'assets/images/chorizo asado1.jpeg',
    category: 'Parrilla',
  ),
  Product(
    id: '18',
    name: 'SANCOCHO DE GALLINA CRIOLLA',
    description: 'SANCOCHO DE GALLINA CRIOLLA, SECO, ENSALADA, AGUACATE, BANANO, SALSAS CHIMICHURRI Y HOGAO, GUARAPO O GASEOSA',
    price: 25000,
    imageUrl: 'assets/images/gallina1.gif',
    category: 'Platos Típicos',
  ),
  Product(
    id: '19',
    name: 'PICADA DEL BARRIL (2 PERSONAS)',
    description: 'PICADA AL BARRIL 6 PROTEÍNAS: CERDO, CHORIZO, POLLO, CHICHARRÓN, COSTILLA, MORCILLA, PAPA COCIDA, SALSAS CHIMICHURRI Y HOGAO, PATACÓN, 2 GASEOSAS',
    price: 30000,
    imageUrl: 'assets/images/PICADA NOMBER ONE.jpeg',
    category: 'Promociones',
  ),
  Product(
    id: '20',
    name: 'PICADA DEL BARRIL FAMILIAR (4 PERSONAS)',
    description: 'PICADA AL BARRIL 6 PROTEÍNAS: CERDO, CHORIZO, POLLO, CHICHARRÓN, COSTILLA, MORCILLA, PAPA COCIDA, SALSAS CHIMICHURRI Y HOGAO, PATACÓN, 4 GASEOSAS',
    price: 50000,
    imageUrl: 'assets/images/picada familiar 1.jpeg',
    category: 'Promociones',
  ),
  Product(
    id: '21',
    name: 'PATACÓN CON CARNE DE SOBREBARRIGA DESMECHADA',
    description: 'PATACÓN DE MADURO O VERDE, GUACAMOLE, HOGAO, QUESO MOZARELLA, GASEOSA O GUARAPO',
    price: 18000,
    imageUrl: 'assets/images/patacon final1.jpeg',
    category: 'Patacones',
  ),
  Product(
    id: '22',
    name: 'PATACÓN MIXTO (CARNE DE SOBREBARRIGA Y POLLO)',
    description: 'PATACÓN DE MADURO O VERDE, GUACAMOLE, HOGAO, QUESO MOZARELLA, GASEOSA O GUARAPO',
    price: 18000,
    imageUrl: 'assets/images/patacon final1.jpeg',
    category: 'Patacones',
  ),
  Product(
    id: '23',
    name: 'PATACÓN CON TODO',
    description: 'CARNE DE SOBREBARRIGA, POLLO, CERDO, SALCHICHA RANCHERA, TOCINETA. PATACÓN DE MADURO O VERDE, GUACAMOLE, HOGAO, QUESO MOZARELLA, GASEOSA O GUARAPO',
    price: 20000,
    imageUrl: 'assets/images/patacon final1.jpeg',
    category: 'Patacones',
  ),
  Product(
    id: '24',
    name: 'TAMALES DE MASA',
    description: '3 CARNES: CHICHARRÓN, CARNE DE CERDO, COSTILLA DE CERDO, PORCIÓN DE AGUACATE MÁS GASEOSA',
    price: 20000,
    imageUrl: 'assets/images/tamal con gaseosa.jpg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '25',
    name: 'FIAMBRES',
    description: 'CHICHARRÓN, CARNE MOLIDA, CHORIZO, HUEVO COCIDO, PURÉ DE PAPA, TAJADA DE MADURO, AGUACATE MÁS GASEOSA',
    price: 22000,
    imageUrl: 'assets/images/fiambre 19.jpg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '26',
    name: 'SUDADO DE POLLO',
    description: 'ARROZ, FRIJOL, ENSALADA, TAJADA DE MADURO, AGUACATE, BANANO, GUARAPO, SOPA DEL DÍA',
    price: 18000,
    imageUrl: 'assets/images/pollo sudado.jpeg',
    category: 'Platos Principales',
  ),
  Product(
    id: '27',
    name: 'MENÚ COMPLETICO CON RES',
    description: 'ARROZ, FRIJOL, ENSALADA, HUEVO, PAPAS FRITAS, AGUACATE, GUARAPO, SOPA DEL DÍA',
    price: 17000,
    imageUrl: 'assets/images/menu completico res.jpg',
    category: 'Menús Ejecutivos',
  ),
  Product(
    id: '28',
    name: 'MENÚ COMPLETICO CON PECHUGA',
    description: 'ARROZ, FRIJOL, ENSALADA, HUEVO, PAPAS FRITAS, AGUACATE, GUARAPO, SOPA DEL DÍA',
    price: 16000,
    imageUrl: 'assets/images/menu completico pechuga.jpg',
    category: 'Menús Ejecutivos',
  ),
  Product(
    id: '29',
    name: 'MENÚ COMPLETICO CON CERDO',
    description: 'ARROZ, FRIJOL, ENSALADA, HUEVO, PAPAS FRITAS, AGUACATE, GUARAPO, SOPA DEL DÍA',
    price: 16000,
    imageUrl: 'assets/images/menu completico cerdo.jpg',
    category: 'Menús Ejecutivos',
  ),
  Product(
    id: '30',
    name: 'MENÚ COMPLETICO CON CHICHARRÓN',
    description: 'ARROZ, FRIJOL, ENSALADA, HUEVO, PAPAS FRITAS, AGUACATE, GUARAPO, SOPA DEL DÍA',
    price: 16000,
    imageUrl: 'assets/images/menu completico chicharron.jpg',
    category: 'Menús Ejecutivos',
  ),
  Product(
    id: '31',
    name: 'PECHUGA A LA PLANCHA BANDEJA',
    description: 'ARROZ, FRIJOL, ENSALADA, TAJADA DE MADURO, PAPITAS A LA FRANCESA, AGUACATE, BANANO, GUARAPO, SOPA DEL DÍA',
    price: 20000,
    imageUrl: 'assets/images/bandeja pechuga .jpg',
    category: 'Platos Principales',
  ),
  Product(
    id: '32',
    name: 'HAMBURGUESA SENCILLA',
    description: 'HAMBURGUESA DE 150 GRAMOS, QUESO, LECHUGA, TOMATE, CEBOLLA, PAPAS A LA FRANCESA, GASEOSA',
    price: 19000,
    imageUrl: 'assets/images/hamburguesa sencilla.jpeg',
    category: 'Parrilla',
  ),
  Product(
    id: '33',
    name: 'NUESTROS VIDEOS SE LES SALE LA CARNE',
    description: 'Mira cómo preparamos nuestros deliciosos tamales',
    price: 0,
    imageUrl: 'assets/videos/arroz paisa video.mp4',
    category: 'Platos Típicos',
  ),
  Product(
    id: '34',
    name: 'GRATINADOS DE LA CASA',
    description: 'Gratinados de la Cocina de Claudia',
    price: 18000,
    imageUrl: 'assets/images/gratinados.jpeg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '35',
    name: 'SANDWIS CUBANOS DE LA CASA',
    description: 'Sandwis Cubanos de la Cocina de Claudia ',
    price: 25000,
    imageUrl: 'assets/images/sandwis cubanos.jpg',
    category: 'Platos Típicos',
  ),
  Product(
    id: '36',
    name: 'SALCHIPAPAS DE LA CASA',
    description: 'Salchipapas de la Cocina de Claudia',
    price: 15000,
    imageUrl: 'assets/images/salchipapas.jpg',
    category: 'Combos',
   ),
  Product(
    id: '37',
    name: 'WRAPS DE LA CASA',
    description: 'wraps de la Cocina de Claudia',
    price: 23000,
    imageUrl: 'assets/images/wraps.jpg',
    category: 'Combos',
   ),
  Product(
    id: '38',
    name: 'BOWLS DE LA CASA',
    description: 'bowls de la Cocina de Claudia',
    price: 22000,
    imageUrl: 'assets/images/bowls.jpg',
    category: 'Combos',
  ),
  Product(
    id: '39',
    name: 'MAZORCADA DE LA CASA',
    description: 'mazorcada de la Cocina de Claudia',
    price: 20000,
    imageUrl: 'assets/images/mazzorcada.jpg',
    category: 'Combos',
  ),
  Product(
    id: '40',
    name: 'DESGRANADOS QUESUDOS',
    description: 'Desgranados quesudos de la Cocina de Claudia',
    price: 20000,
    imageUrl: 'assets/images/DESGRANADOS.jpeg',
    category: 'Combos',
  ),
   
  ];

// Lista de videos promocionales
final List<Map<String, dynamic>> promotionalVideos = [
  {
    'id': 'video1',
    'name': 'Video: NUESTROS TAMALES SE LES SALE LA CARNE',
    'description': 'Mira cómo preparamos nuestros deliciosos tamales',
    'videoUrl': 'assets/videos/tamal desbordado.mp4',
    'category': 'Videos',
  },
  {
    'id': 'video2',
    'name': 'Video: NUESTRO ARROZ PAISA',
    'description': 'Conoce nuestra cocina y nuestro proceso',
    'videoUrl': 'assets/videos/arroz paisa video.mp4',
    'category': 'Videos',
  },
];

// Función para obtener categorías únicas
List<String> getCategories() {
  final categories = mockProducts.map((product) => product.category).toSet().toList();
  categories.sort();
  return ['Todos', ...categories];
}

// Función para filtrar productos por categoría
List<Product> getProductsByCategory(String category) {
  if (category == 'Todos') {
    return mockProducts;
  }
  return mockProducts.where((product) => product.category == category).toList();
}

// Función para buscar productos
List<Product> searchProducts(String query) {
  if (query.isEmpty) {
    return mockProducts;
  }
  
  return mockProducts.where((product) {
    return product.name.toLowerCase().contains(query.toLowerCase()) ||
           product.description.toLowerCase().contains(query.toLowerCase()) ||
           product.category.toLowerCase().contains(query.toLowerCase());
  }).toList();
}

