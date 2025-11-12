// Importamos el paquete base de Flutter que contiene todos los widgets de Material Design.
import 'package:flutter/material.dart';

// Punto de entrada principal de la aplicación.
// "runApp" inicia la app y recibe un widget raíz.
void main() {
  runApp(ShopApp());
}

// Este es el widget raíz de nuestra app.
// Extiende de StatelessWidget porque su contenido no cambia (no tiene estado).
class ShopApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // MaterialApp es el widget base de una app Flutter estilo Material Design.
    // Configura rutas, temas, título, y cuál pantalla mostrar primero.
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Oculta el banner de "debug".
      title: 'Flutter Store', // Título interno de la app.
      theme: ThemeData(primarySwatch: Colors.teal), // Tema principal (colores).
      home: ProductListScreen(), // Pantalla principal (home).
    );
  }
}

// Este widget muestra la lista de productos en forma de tarjetas.
class ProductListScreen extends StatelessWidget {
  // Creamos una lista de productos. Cada producto es un mapa con nombre, precio e imagen.
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Camiseta Deportiva',
      'price': 75.000,
      'image': 'https://i.imgur.com/DbjV2hO.png'
    },
    {
      'name': 'Zapatos Running',
      'price': 180.000,
      'image': 'https://i.imgur.com/6KOFnZC.png'
    },
    {
      'name': 'Chaqueta Casual',
      'price': 120.000,
      'image': 'https://i.imgur.com/XhQe3ZP.png'
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Scaffold es la estructura base de una pantalla en Flutter.
    // Contiene el AppBar, el cuerpo (body), el Drawer, el FloatingButton, etc.
    return Scaffold(
      appBar: AppBar( // AppBar es la barra superior de la app.
        title: Text('Catálogo de Productos'), // Texto que aparece en el AppBar.
      ),
      // El cuerpo principal (body) de la pantalla:
      body: ListView.builder( // ListView muestra listas desplazables.
        padding: EdgeInsets.all(10), // Márgenes alrededor del contenido.
        itemCount: products.length, // Cuántos elementos tendrá la lista.
        itemBuilder: (context, index) {
          // "itemBuilder" se ejecuta por cada producto de la lista.
          final product = products[index]; // Obtenemos el producto actual.
          
          // Card es un contenedor con diseño de tarjeta (sombra, bordes redondeados, etc.)
          return Card(
            elevation: 5, // Nivel de sombra.
            margin: EdgeInsets.symmetric(vertical: 8), // Separación entre tarjetas.
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), // Bordes redondeados.
            ),
            // ListTile es un widget que organiza contenido en una sola fila (título, subtítulo, icono).
            child: ListTile(
              leading: Image.network(product['image'], height: 50), // Imagen del producto (a la izquierda).
              title: Text( // Título principal del item.
                product['name'],
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Precio: \$${product['price']}'), // Texto pequeño debajo del título.
              trailing: Icon( // Icono al final (a la derecha).
                Icons.shopping_cart_outlined, // Icono de carrito.
                color: Colors.teal,
              ),
              // Al tocar la tarjeta, se navega a la pantalla de detalles.
              onTap: () {
                Navigator.push( // Navigator permite moverse entre pantallas.
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductDetailScreen(product: product),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// Pantalla que muestra los detalles del producto seleccionado.
class ProductDetailScreen extends StatelessWidget {
  // Recibe el producto como parámetro.
  final Map<String, dynamic> product;

  // Constructor con parámetro requerido.
  const ProductDetailScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold( // De nuevo, Scaffold estructura la pantalla.
      appBar: AppBar(title: Text(product['name'])), // Título = nombre del producto.
      body: Padding( // Padding añade espacio interno alrededor del contenido.
        padding: const EdgeInsets.all(16.0),
        child: Column( // Column organiza widgets verticalmente.
          crossAxisAlignment: CrossAxisAlignment.center, // Centra el contenido.
          children: [
            Image.network(product['image'], height: 200), // Imagen grande del producto.
            SizedBox(height: 20), // Espacio entre widgets.
            Text(
              product['name'], // Nombre del producto.
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Precio: \$${product['price']}',
              style: TextStyle(fontSize: 20, color: Colors.grey[800]),
            ),
            SizedBox(height: 30),
            ElevatedButton.icon( // Botón elevado con ícono y texto.
              onPressed: () {}, // Acción (por ahora vacía).
              icon: Icon(Icons.shopping_cart), // Ícono del botón.
              label: Text('Agregar al carrito'), // Texto del botón.
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal, // Color del botón.
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

🧩 Resumen rápido de los widgets más importantes:
Widget	Qué hace	Ejemplo de uso
Scaffold	Estructura base de una pantalla (appBar, body, etc.)	Crea la estructura principal
AppBar	Barra superior con título, íconos o botones	AppBar(title: Text('Inicio'))
ListView.builder	Lista que se genera dinámicamente	Muestra muchos elementos
Card	Tarjeta con sombra y bordes redondeados	Para mostrar info visualmente separada
ListTile	Fila con imagen, título y subtítulo	Ideal para listas de productos
Navigator.push	Mueve a otra pantalla	Navigator.push(context, route)
Column / Row	Organización vertical / horizontal	Diseñar estructuras
Padding	Espacio interior alrededor del contenido	Padding(padding: EdgeInsets.all(10))
SizedBox	Espacio entre widgets	SizedBox(height: 20)
ElevatedButton	Botón con relieve



import 'package:flutter/material.dart'; 
// 📦 Importa el paquete principal de Flutter que contiene todos los widgets visuales
// (como botones, textos, columnas, filas, etc.) y el sistema de diseño Material Design.

void main() {
  runApp(MyApp());
  // 🚀 Esta es la función principal de Dart (punto de inicio del programa).
  // `runApp()` toma un widget (en este caso `MyApp`) y lo muestra en pantalla.
}

class MyApp extends StatelessWidget {
  // 🧱 MyApp es un widget sin estado (StatelessWidget).
  // No cambia con el tiempo, ideal para la estructura inicial de la app.

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // 🌎 Es el widget principal de toda aplicación Flutter.
      // Configura el tema, rutas, título y pantalla inicial.

      title: 'Mi Primera App Flutter', // 🏷️ Título de la aplicación.
      theme: ThemeData(
        primarySwatch: Colors.blue, // 🎨 Define el color principal (azul).
      ),
      home: MyHomePage(), // 🏠 Define la pantalla principal.
    );
  }
}

class MyHomePage extends StatelessWidget {
  // 🧩 Este es el widget principal de la pantalla inicial.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🏗️ Scaffold es un widget que estructura la pantalla base.
      // Permite agregar AppBar, Body, FloatingButton, Drawer, etc.

      appBar: AppBar(
        // 📍 Parte superior de la app (barra de título)
        title: Text('Inicio'), // 📝 Texto que aparece en la barra superior.
        backgroundColor: Colors.blueAccent, // 🎨 Color de fondo del AppBar.
      ),

      body: Center(
        // 🎯 Centra su contenido en la pantalla.
        child: Column(
          // 📚 Organiza widgets en columna vertical.
          mainAxisAlignment: MainAxisAlignment.center, // Centra los hijos verticalmente.
          children: <Widget>[
            Text(
              '¡Bienvenido a Flutter!',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ), // 🖋️ Muestra texto estilizado.
            SizedBox(height: 20), // 📏 Espaciado vertical de 20 píxeles.
            ElevatedButton(
              onPressed: () {
                print("Botón presionado!");
              }, // ⚙️ Acción al presionar el botón.
              child: Text('Presióname'), // 🖱️ Texto dentro del botón.
            ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton(
        // ⚡ Botón flotante (normalmente abajo a la derecha).
        onPressed: () {
          print("Botón flotante presionado!");
        },
        child: Icon(Icons.add), // ➕ Ícono de suma.
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}



Resumen rápido:

Widget: todo en Flutter es un widget (texto, imagen, botón, pantalla, etc.).

StatelessWidget: no cambia con el tiempo (por ejemplo, un texto fijo).

StatefulWidget: cambia con el tiempo (por ejemplo, un contador).

Scaffold: estructura principal de una pantalla.

AppBar: la barra superior con título y acciones.

Body: el contenido principal de la pantalla.

FloatingActionButton: botón flotante de acción rápida.