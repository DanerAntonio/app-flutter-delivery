# 🔄 FLUJOS DE USUARIO DETECTADOS

## 👤 FLUJO CLIENTE

```
🚀 general_screen → lib\main.dart
     📍 Sistema domicilios
   shopping_cart → lib\screens\custom_order_screen.dart
     📍 Agregar productos carrito, Gestion pedidos
   product_catalog → lib\screens\inventory_screen.dart
     📍 Base datos firestore, Control inventario
   auth_login → lib\screens\menu_screen.dart
     📍 Agregar productos carrito, Autenticacion usuario
   product_catalog → lib\screens\migrate_products_to_firestore.dart
     📍 Base datos firestore, Control inventario
   general_screen → lib\screens\order_history_screen.dart
     📍 Base datos firestore, Gestion pedidos
   auth_login → lib\screens\order_summary_screen.dart
     📍 Autenticacion usuario, Base datos firestore
   home_dashboard → lib\screens\order_tracking_screen.dart
     📍 Base datos firestore, Gestion pedidos
   shopping_cart → lib\screens\product_detail_screen.dart
     📍 Agregar productos carrito
   auth_login → lib\screens\register_screen.dart
     📍 Autenticacion usuario, Base datos firestore
   auth_login → lib\screens\reset_password_screen.dart
     📍 Autenticacion usuario
   general_screen → lib\services\store_settings_screen.dart
   shopping_cart → lib\widgets\product_card.dart
     📍 Agregar productos carrito
```


## 👨‍💼 FLUJO ADMINISTRADOR

```
🚀 auth_login → lib\screens\admin_home_screen.dart
     📍 Autenticacion usuario, Base datos firestore
   admin_panel → lib\screens\admin_metrics_screen.dart
     📍 Base datos firestore, Gestion pedidos
   admin_panel → lib\screens\admin_orders_screen.dart
     📍 Base datos firestore, Gestion pedidos
   auth_login → lib\screens\auth_gate.dart
     📍 Autenticacion usuario, Base datos firestore
   general_screen → lib\screens\delivery_config_screen.dart
     📍 Base datos firestore, Sistema domicilios
   auth_login → lib\screens\home_screen.dart
     📍 Autenticacion usuario, Base datos firestore
   admin_panel → lib\widgets\store_status_widget.dart
```


## 🚗 FLUJO DOMICILIARIO

```
🚀 auth_login → lib\screens\driver_home_screen.dart
     📍 Autenticacion usuario, Base datos firestore
   driver_panel → lib\screens\driver_order_detail_screen.dart
     📍 Base datos firestore, Gestion pedidos
   auth_login → lib\screens\driver_register_screen.dart
     📍 Autenticacion usuario, Base datos firestore
   auth_login → lib\screens\login_screen.dart
     📍 Autenticacion usuario, Sistema domicilios
```


## 🎯 RESUMEN DE FLUJOS

- **Client**: 13 pantallas en el flujo
- **Admin**: 7 pantallas en el flujo
- **Driver**: 4 pantallas en el flujo

