# 🗂️ MATRIZ DE CARACTERÍSTICAS

## 📋 Resumen de Funcionalidades por Pantalla

### 🖥️ lib\main.dart
**Tipo:** general_screen
**Rol:** 👤 Cliente

**✨ Características:**
- Sistema domicilios

**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- State management

---

### 🖥️ lib\screens\admin_home_screen.dart
**Tipo:** auth_login
**Rol:** 👨‍💼 Administrador

**✨ Características:**
- Autenticacion usuario
- Base datos firestore
- Gestion pedidos
- Sistema domicilios
- Control inventario
- Metricas estadisticas

**🎯 Acciones del Usuario:**
- Cerrar sesion
- Navegar pantalla

**🔗 Navegación:**
- `Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context)`

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- State management

---

### 🖥️ lib\screens\admin_metrics_screen.dart
**Tipo:** admin_panel
**Rol:** 👨‍💼 Administrador

**✨ Características:**
- Base datos firestore
- Gestion pedidos
- Metricas estadisticas

**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database

---

### 🖥️ lib\screens\admin_orders_screen.dart
**Tipo:** admin_panel
**Rol:** 👨‍💼 Administrador

**✨ Características:**
- Base datos firestore
- Gestion pedidos
- Control inventario

**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- State management

---

### 🖥️ lib\screens\auth_gate.dart
**Tipo:** auth_login
**Rol:** 👨‍💼 Administrador

**✨ Características:**
- Autenticacion usuario
- Base datos firestore
- Seguimiento pedidos

**🎯 Acciones del Usuario:**
- Iniciar sesion

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- State management

---

### 🖥️ lib\screens\custom_order_screen.dart
**Tipo:** shopping_cart
**Rol:** 👤 Cliente

**✨ Características:**
- Agregar productos carrito
- Gestion pedidos

**🎯 Acciones del Usuario:**
- Agregar producto carrito
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- State management

---

### 🖥️ lib\screens\delivery_config_screen.dart
**Tipo:** general_screen
**Rol:** 👨‍💼 Administrador

**✨ Características:**
- Base datos firestore
- Sistema domicilios

**🎯 Acciones del Usuario:**
- Confirmar pedido

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database

---

### 🖥️ lib\screens\driver_home_screen.dart
**Tipo:** auth_login
**Rol:** 🚗 Domiciliario

**✨ Características:**
- Autenticacion usuario
- Base datos firestore
- Gestion pedidos
- Sistema domicilios

**🎯 Acciones del Usuario:**
- Cerrar sesion
- Navegar pantalla

**🔗 Navegación:**
- `Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context)`

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- State management

---

### 🖥️ lib\screens\driver_order_detail_screen.dart
**Tipo:** driver_panel
**Rol:** 🚗 Domiciliario

**✨ Características:**
- Base datos firestore
- Gestion pedidos
- Sistema domicilios
- Sistema pagos

**🎯 Acciones del Usuario:**
- Confirmar pedido
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- State management

---

### 🖥️ lib\screens\driver_register_screen.dart
**Tipo:** auth_login
**Rol:** 🚗 Domiciliario

**✨ Características:**
- Autenticacion usuario
- Base datos firestore
- Gestion pedidos
- Sistema domicilios

**🎯 Acciones del Usuario:**
- Registrar usuario
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- State management

---

### 🖥️ lib\screens\home_screen.dart
**Tipo:** auth_login
**Rol:** 👨‍💼 Administrador

**✨ Características:**
- Autenticacion usuario
- Base datos firestore
- Seguimiento pedidos

**🎯 Acciones del Usuario:**
- Iniciar sesion
- Cerrar sesion
- Navegar pantalla

**🔗 Navegación:**
- `Navigator.push(
      context,
      MaterialPageRoute(builder: (_)`
- `Navigator.push(
        context,
        MaterialPageRoute(builder: (_)`
- `Navigator.push(context, MaterialPageRoute(builder: (_)`
- `Navigator.push(
                context,
                MaterialPageRoute(builder: (context)`

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- Datos mock
- State management

---

### 🖥️ lib\screens\inventory_screen.dart
**Tipo:** product_catalog
**Rol:** 👤 Cliente

**✨ Características:**
- Base datos firestore
- Control inventario

**🎯 Acciones del Usuario:**
- Agregar producto carrito
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database

---

### 🖥️ lib\screens\login_screen.dart
**Tipo:** auth_login
**Rol:** 🚗 Domiciliario

**✨ Características:**
- Autenticacion usuario
- Sistema domicilios

**🎯 Acciones del Usuario:**
- Iniciar sesion
- Registrar usuario
- Navegar pantalla

**🔗 Navegación:**
- `Navigator.push(
              context,
              MaterialPageRoute(builder: (context)`
- `Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context)`
- `Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context)`

**💾 Fuentes de Datos:**
- Firebase auth
- State management

---

### 🖥️ lib\screens\menu_screen.dart
**Tipo:** auth_login
**Rol:** 👤 Cliente

**✨ Características:**
- Agregar productos carrito
- Autenticacion usuario

**🎯 Acciones del Usuario:**
- Agregar producto carrito
- Iniciar sesion
- Navegar pantalla

**🔗 Navegación:**
- `Navigator.push(
                context,
                MaterialPageRoute(builder: (context)`
- `Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context)`
- `Navigator.push(
              context,
              MaterialPageRoute(builder: (context)`

**💾 Fuentes de Datos:**
- Firebase auth
- Datos mock
- State management

---

### 🖥️ lib\screens\migrate_products_to_firestore.dart
**Tipo:** product_catalog
**Rol:** 👤 Cliente

**✨ Características:**
- Base datos firestore
- Control inventario

**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- Datos mock

---

### 🖥️ lib\screens\order_history_screen.dart
**Tipo:** general_screen
**Rol:** 👤 Cliente

**✨ Características:**
- Base datos firestore
- Gestion pedidos

**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database

---

### 🖥️ lib\screens\order_summary_screen.dart
**Tipo:** auth_login
**Rol:** 👤 Cliente

**✨ Características:**
- Autenticacion usuario
- Base datos firestore
- Gestion pedidos
- Sistema domicilios
- Control inventario
- Sistema pagos

**🎯 Acciones del Usuario:**
- Confirmar pedido
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- State management

---

### 🖥️ lib\screens\order_tracking_screen.dart
**Tipo:** home_dashboard
**Rol:** 👤 Cliente

**✨ Características:**
- Base datos firestore
- Gestion pedidos
- Sistema pagos
- Seguimiento pedidos

**🎯 Acciones del Usuario:**
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- State management

---

### 🖥️ lib\screens\product_detail_screen.dart
**Tipo:** shopping_cart
**Rol:** 👤 Cliente

**✨ Características:**
- Agregar productos carrito

**🎯 Acciones del Usuario:**
- Agregar producto carrito
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- State management

---

### 🖥️ lib\screens\register_screen.dart
**Tipo:** auth_login
**Rol:** 👤 Cliente

**✨ Características:**
- Autenticacion usuario
- Base datos firestore

**🎯 Acciones del Usuario:**
- Iniciar sesion
- Registrar usuario
- Confirmar pedido
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firestore database
- Firebase auth
- State management

---

### 🖥️ lib\screens\reset_password_screen.dart
**Tipo:** auth_login
**Rol:** 👤 Cliente

**✨ Características:**
- Autenticacion usuario

**🎯 Acciones del Usuario:**
- Navegar pantalla

**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**
- Firebase auth

---

### 🖥️ lib\services\store_settings_screen.dart
**Tipo:** general_screen
**Rol:** 👤 Cliente

**✨ Características:**


**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**


---

### 🖥️ lib\widgets\product_card.dart
**Tipo:** shopping_cart
**Rol:** 👤 Cliente

**✨ Características:**
- Agregar productos carrito

**🎯 Acciones del Usuario:**
- Agregar producto carrito
- Navegar pantalla

**🔗 Navegación:**
- `Navigator.push(
                context,
                MaterialPageRoute(builder: (context)`
- `Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation)`

**💾 Fuentes de Datos:**
- State management

---

### 🖥️ lib\widgets\store_status_widget.dart
**Tipo:** admin_panel
**Rol:** 👨‍💼 Administrador

**✨ Características:**


**🎯 Acciones del Usuario:**


**🔗 Navegación:**
- No se detectó navegación explícita

**💾 Fuentes de Datos:**


---

