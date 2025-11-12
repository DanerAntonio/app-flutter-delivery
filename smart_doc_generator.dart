import 'dart:io';
import 'dart:convert';

class CodeAnalyzer {
  final String projectPath;
  
  CodeAnalyzer(this.projectPath);
  
  // Analizar el contenido de los archivos para entender funcionalidades
  Map<String, dynamic> analyzeProject() {
    final libDir = Directory('$projectPath/lib');
    final files = _scanDartFiles(libDir);
    
    final screenAnalysis = _analyzeScreens(files);
    final userFlows = _detectUserFlows(screenAnalysis);
    final userStories = _generateUserStories(screenAnalysis);
    
    return {
      'project_name': _getProjectName(),
      'analysis_date': DateTime.now().toString(),
      'screens_analyzed': screenAnalysis.length,
      'screen_analysis': screenAnalysis,
      'user_flows': userFlows,
      'user_stories': userStories,
      'detected_roles': _detectUserRoles(screenAnalysis),
    };
  }
  
  List<String> _scanDartFiles(Directory dir) {
    final files = <String>[];
    
    if (!dir.existsSync()) return files;
    
    final entities = dir.listSync(recursive: true);
    
    for (final entity in entities) {
      if (entity is File && 
          entity.path.endsWith('.dart') &&
          !entity.path.contains('.g.dart') &&
          !entity.path.contains('test')) {
        files.add(entity.path.replaceAll('$projectPath/', ''));
      }
    }
    
    return files;
  }
  
  Map<String, dynamic> _analyzeScreens(List<String> files) {
    final analysis = <String, dynamic>{};
    
    for (final file in files) {
      final content = File('$projectPath/$file').readAsStringSync();
      final screenInfo = _analyzeScreenContent(file, content);
      
      if (screenInfo['is_screen']) {
        analysis[file] = screenInfo;
      }
    }
    
    return analysis;
  }
  
  Map<String, dynamic> _analyzeScreenContent(String filename, String content) {
    final screenInfo = <String, dynamic>{
      'is_screen': false,
      'screen_type': 'unknown',
      'user_role': 'unknown',
      'features': [],
      'actions': [],
      'navigation': [],
      'data_sources': [],
    };
    
    // Detectar si es una pantalla
    if (filename.contains('screen') || 
        filename.contains('page') ||
        content.contains('extends StatefulWidget') ||
        content.contains('extends StatelessWidget') ||
        content.contains('Scaffold') ||
        content.contains('Navigator')) {
      screenInfo['is_screen'] = true;
    }
    
    // Determinar tipo de pantalla y rol de usuario
    screenInfo['screen_type'] = _detectScreenType(filename, content);
    screenInfo['user_role'] = _detectUserRole(filename, content);
    
    // Analizar funcionalidades
    screenInfo['features'] = _detectFeatures(content);
    screenInfo['actions'] = _detectActions(content);
    screenInfo['navigation'] = _detectNavigation(content);
    screenInfo['data_sources'] = _detectDataSources(content);
    
    return screenInfo;
  }
  
  String _detectScreenType(String filename, String content) {
    if (filename.contains('login') || content.contains('FirebaseAuth') || content.contains('signIn')) {
      return 'auth_login';
    } else if (filename.contains('home') || content.contains('HomeScreen')) {
      return 'home_dashboard';
    } else if (filename.contains('admin') || content.contains('Admin')) {
      return 'admin_panel';
    } else if (filename.contains('driver') || content.contains('Driver') || content.contains('courier')) {
      return 'driver_panel';
    } else if (filename.contains('order') && filename.contains('summary')) {
      return 'order_summary';
    } else if (filename.contains('cart') || content.contains('Cart')) {
      return 'shopping_cart';
    } else if (filename.contains('product') || content.contains('Product')) {
      return 'product_catalog';
    } else if (filename.contains('menu')) {
      return 'menu_display';
    } else if (filename.contains('tracking')) {
      return 'order_tracking';
    } else if (filename.contains('register')) {
      return 'auth_register';
    }
    
    return 'general_screen';
  }
  
  String _detectUserRole(String filename, String content) {
    if (filename.contains('admin') || content.contains('Admin') || content.contains('administrador')) {
      return 'admin';
    } else if (filename.contains('driver') || content.contains('Driver') || content.contains('domiciliario') || content.contains('courier')) {
      return 'driver';
    } else if (content.contains('FirebaseAuth') || content.contains('login') || content.contains('cliente')) {
      return 'client';
    }
    
    return 'client'; // Por defecto
  }
  
  List<String> _detectFeatures(String content) {
    final features = <String>[];
    
    // Detectar funcionalidades basadas en código
    if (content.contains('addToCart') || content.contains('CartProvider')) {
      features.add('agregar_productos_carrito');
    }
    if (content.contains('FirebaseAuth') || content.contains('signIn') || content.contains('login')) {
      features.add('autenticacion_usuario');
    }
    if (content.contains('Firestore') || content.contains('collection(')) {
      features.add('base_datos_firestore');
    }
    if (content.contains('order') && content.contains('total')) {
      features.add('gestion_pedidos');
    }
    if (content.contains('delivery') || content.contains('domicilio') || content.contains('deliveryFee')) {
      features.add('sistema_domicilios');
    }
    if (content.contains('stock') || content.contains('inventory')) {
      features.add('control_inventario');
    }
    if (content.contains('payment') || content.contains('pago') || content.contains('pay')) {
      features.add('sistema_pagos');
    }
    if (content.contains('track') || content.contains('seguimiento')) {
      features.add('seguimiento_pedidos');
    }
    if (content.contains('metrics') || content.contains('analytics')) {
      features.add('metricas_estadisticas');
    }
    
    return features;
  }
  
  List<String> _detectActions(String content) {
    final actions = <String>[];
    
    // Detectar acciones del usuario
    if (content.contains('onPressed') || content.contains('onTap')) {
      if (content.contains('addToCart') || content.contains('agregar')) {
        actions.add('agregar_producto_carrito');
      }
      if (content.contains('login') || content.contains('signIn')) {
        actions.add('iniciar_sesion');
      }
      if (content.contains('register') || content.contains('crear_cuenta')) {
        actions.add('registrar_usuario');
      }
      if (content.contains('checkout') || content.contains('confirmar')) {
        actions.add('confirmar_pedido');
      }
      if (content.contains('logout') || content.contains('cerrar_sesion')) {
        actions.add('cerrar_sesion');
      }
      if (content.contains('navigate') || content.contains('push') || content.contains('Navigator')) {
        actions.add('navegar_pantalla');
      }
    }
    
    return actions;
  }
  
  List<String> _detectNavigation(String content) {
    final navigation = <String>[];
    
    // Detectar navegación entre pantallas
    final navMatches = RegExp(r'Navigator\.(push|pushNamed|pushReplacement)\([^)]+\)').allMatches(content);
    for (final match in navMatches) {
      navigation.add(match.group(0)!);
    }
    
    return navigation;
  }
  
  List<String> _detectDataSources(String content) {
    final dataSources = <String>[];
    
    // Detectar fuentes de datos
    if (content.contains('FirebaseFirestore')) {
      dataSources.add('firestore_database');
    }
    if (content.contains('FirebaseAuth')) {
      dataSources.add('firebase_auth');
    }
    if (content.contains('mock_products') || content.contains('mockData')) {
      dataSources.add('datos_mock');
    }
    if (content.contains('Provider') || content.contains('ChangeNotifier')) {
      dataSources.add('state_management');
    }
    
    return dataSources;
  }
  
  Map<String, dynamic> _detectUserFlows(Map<String, dynamic> screenAnalysis) {
    final flows = <String, dynamic>{
      'client_flow': [],
      'admin_flow': [],
      'driver_flow': [],
    };
    
    for (final entry in screenAnalysis.entries) {
      final screen = entry.value as Map<String, dynamic>;
      final role = screen['user_role'] as String;
      final screenType = screen['screen_type'] as String;
      
      if (role == 'client') {
        flows['client_flow']!.add({
          'screen': entry.key,
          'type': screenType,
          'features': screen['features'],
        });
      } else if (role == 'admin') {
        flows['admin_flow']!.add({
          'screen': entry.key,
          'type': screenType,
          'features': screen['features'],
        });
      } else if (role == 'driver') {
        flows['driver_flow']!.add({
          'screen': entry.key,
          'type': screenType,
          'features': screen['features'],
        });
      }
    }
    
    return flows;
  }
  
  Map<String, dynamic> _generateUserStories(Map<String, dynamic> screenAnalysis) {
    final userStories = <String, dynamic>{};
    int storyCount = 1;
    
    for (final entry in screenAnalysis.entries) {
      final screen = entry.value as Map<String, dynamic>;
      final role = screen['user_role'] as String;
      final features = screen['features'] as List<String>;
      
      for (final feature in features) {
        final storyId = 'US-${storyCount.toString().padLeft(3, '0')}';
        
        userStories[storyId] = {
          'title': _getFeatureTitle(feature),
          'role': role,
          'feature': feature,
          'screen': entry.key,
          'description': _generateStoryDescription(role, feature),
          'acceptance_criteria': _generateAcceptanceCriteria(feature),
        };
        
        storyCount++;
      }
    }
    
    return userStories;
  }
  
  Map<String, dynamic> _detectUserRoles(Map<String, dynamic> screenAnalysis) {
    final roles = <String, int>{
      'client': 0,
      'admin': 0,
      'driver': 0,
    };
    
    for (final screen in screenAnalysis.values) {
      final role = (screen as Map<String, dynamic>)['user_role'] as String;
      if (roles.containsKey(role)) {
        roles[role] = roles[role]! + 1;
      }
    }
    
    return roles;
  }
  
  String _getFeatureTitle(String feature) {
    final titles = {
      'agregar_productos_carrito': 'Agregar productos al carrito de compras',
      'autenticacion_usuario': 'Sistema de autenticación de usuarios',
      'base_datos_firestore': 'Integración con base de datos Firestore',
      'gestion_pedidos': 'Gestión y seguimiento de pedidos',
      'sistema_domicilios': 'Sistema de domicilios y repartidores',
      'control_inventario': 'Control de inventario y stock',
      'sistema_pagos': 'Sistema de procesamiento de pagos',
      'seguimiento_pedidos': 'Seguimiento en tiempo real de pedidos',
      'metricas_estadisticas': 'Métricas y estadísticas para administradores',
    };
    
    return titles[feature] ?? _capitalize(feature.replaceAll('_', ' '));
  }
  
  String _generateStoryDescription(String role, String feature) {
    final roleNames = {
      'client': 'cliente',
      'admin': 'administrador', 
      'driver': 'domiciliario',
    };
    
    final featureDescriptions = {
      'agregar_productos_carrito': 'poder agregar productos a mi carrito de compras',
      'autenticacion_usuario': 'iniciar sesión en mi cuenta de forma segura',
      'gestion_pedidos': 'realizar y gestionar mis pedidos de comida',
      'sistema_domicilios': 'solicitar domicilio a mi dirección',
      'control_inventario': 'gestionar el inventario de productos',
      'metricas_estadisticas': 'ver métricas de ventas y desempeño',
    };
    
    final roleName = roleNames[role] ?? 'usuario';
    final featureDesc = featureDescriptions[feature] ?? 'utilizar la funcionalidad de $feature';
    
    return 'Como $roleName quiero $featureDesc para mejorar mi experiencia en la aplicación';
  }
  
  List<String> _generateAcceptanceCriteria(String feature) {
    final criteria = {
      'agregar_productos_carrito': [
        'Debo poder ver los productos disponibles',
        'Debo poder seleccionar la cantidad deseada',
        'El carrito debe mostrar el total actualizado',
        'Debo poder proceder al checkout desde el carrito',
      ],
      'autenticacion_usuario': [
        'Debo poder ingresar con email y contraseña',
        'Debo recibir feedback claro de errores',
        'Debo poder recuperar mi contraseña si la olvido',
        'La sesión debe mantenerse entre reinicios de app',
      ],
      'gestion_pedidos': [
        'Debo poder ver el historial de mis pedidos',
        'Debo poder ver el estado actual de cada pedido',
        'Debo recibir notificaciones de cambios de estado',
        'Debo poder cancelar pedidos en estado pendiente',
      ],
      'sistema_domicilios': [
        'Debo poder ver el costo del domicilio antes de pedir',
        'Debo poder seguir al repartidor en tiempo real',
        'Debo poder calificar el servicio de domicilio',
        'El repartidor debe recibir la información completa del pedido',
      ],
    };
    
    return criteria[feature] ?? [
      'La funcionalidad debe estar completamente operativa',
      'La interfaz debe ser intuitiva y responsive',
      'Los datos deben persistir correctamente',
      'Debe manejar errores de forma elegante',
    ];
  }
  
  String _getProjectName() {
    final pubspecFile = File('$projectPath/pubspec.yaml');
    if (pubspecFile.existsSync()) {
      final content = pubspecFile.readAsStringSync();
      final match = RegExp(r'name:\s*(\S+)').firstMatch(content);
      return match?.group(1) ?? 'flutter_project';
    }
    return 'flutter_project';
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

class SmartDocumentationGenerator {
  final Map<String, dynamic> analysisData;
  
  SmartDocumentationGenerator(this.analysisData);
  
  void generateSmartDocumentation() {
    _generateUserStoriesDoc();
    _generateUserFlowsDoc();
    _generateRoleAnalysisDoc();
    _generateFeatureMatrixDoc();
  }
  
  void _generateUserStoriesDoc() {
    final userStories = analysisData['user_stories'] as Map<String, dynamic>;
    
    final content = '''
# 📋 HISTORIAS DE USUARIO INTELIGENTES

*Generadas automáticamente basado en análisis de código - ${analysisData['analysis_date']}*

## 🎯 Resumen por Rol de Usuario

${_generateRoleSummary()}

## 📖 Detalle de Historias de Usuario

${userStories.entries.map((entry) => '''
### ${entry.key} - ${(entry.value as Map<String, dynamic>)['title']}

**Rol:** ${_getRoleBadge((entry.value as Map<String, dynamic>)['role'])}
**Pantalla:** \`${(entry.value as Map<String, dynamic>)['screen']}\`

**Descripción:**  
${(entry.value as Map<String, dynamic>)['description']}

**✅ Criterios de Aceptación:**
${((entry.value as Map<String, dynamic>)['acceptance_criteria'] as List<String>).map((criteria) => '- [ ] $criteria').join('\n')}

**🔍 Detalles Técnicos:**
- **Funcionalidad:** ${(entry.value as Map<String, dynamic>)['feature']}
- **Estado:** 🟡 Detectado en código
- **Complejidad:** ${_estimateComplexity((entry.value as Map<String, dynamic>)['feature'])}

---
''').join('\n')}

## 📊 Métricas del Proyecto

- **Total de historias detectadas:** ${userStories.length}
- **Cobertura de roles:** ${_calculateRoleCoverage()}
- **Complejidad promedio:** ${_calculateAverageComplexity(userStories)}

*Documentación generada automáticamente - Ejecuta de nuevo al modificar el código*
''';
    
    _writeFile('HISTORIAS_INTELIGENTES.md', content);
  }
  
  void _generateUserFlowsDoc() {
    final userFlows = analysisData['user_flows'] as Map<String, dynamic>;
    
    final content = '''
# 🔄 FLUJOS DE USUARIO DETECTADOS

## 👤 FLUJO CLIENTE

${_generateFlowDiagram(userFlows['client_flow'] as List<dynamic>, 'Cliente')}

## 👨‍💼 FLUJO ADMINISTRADOR

${_generateFlowDiagram(userFlows['admin_flow'] as List<dynamic>, 'Administrador')}

## 🚗 FLUJO DOMICILIARIO

${_generateFlowDiagram(userFlows['driver_flow'] as List<dynamic>, 'Domiciliario')}

## 🎯 RESUMEN DE FLUJOS

${_generateFlowSummary(userFlows)}
''';
    
    _writeFile('FLUJOS_USUARIO.md', content);
  }
  
  void _generateRoleAnalysisDoc() {
    final roles = analysisData['detected_roles'] as Map<String, dynamic>;
    final screenAnalysis = analysisData['screen_analysis'] as Map<String, dynamic>;
    
    final content = '''
# 👥 ANÁLISIS DE ROLES DE USUARIO

## 📊 Distribución de Pantallas por Rol

${roles.entries.map((entry) => '- **${_capitalize(entry.key)}**: ${entry.value} pantallas detectadas').join('\n')}

## 🔍 Detalle por Rol

### 👤 CLIENTE
${_generateRoleDetail(screenAnalysis, 'client')}

### 👨‍💼 ADMINISTRADOR  
${_generateRoleDetail(screenAnalysis, 'admin')}

### 🚗 DOMICILIARIO
${_generateRoleDetail(screenAnalysis, 'driver')}

## 💡 RECOMENDACIONES

${_generateRoleRecommendations(roles)}
''';
    
    _writeFile('ANALISIS_ROLES.md', content);
  }
  
  void _generateFeatureMatrixDoc() {
    final screenAnalysis = analysisData['screen_analysis'] as Map<String, dynamic>;
    
    final content = '''
# 🗂️ MATRIZ DE CARACTERÍSTICAS

## 📋 Resumen de Funcionalidades por Pantalla

${screenAnalysis.entries.map((entry) => '''
### 🖥️ ${entry.key}
**Tipo:** ${(entry.value as Map<String, dynamic>)['screen_type']}
**Rol:** ${_getRoleBadge((entry.value as Map<String, dynamic>)['user_role'])}

**✨ Características:**
${((entry.value as Map<String, dynamic>)['features'] as List<String>).map((feature) => '- ${_capitalize(feature.replaceAll('_', ' '))}').join('\n')}

**🎯 Acciones del Usuario:**
${((entry.value as Map<String, dynamic>)['actions'] as List<String>).map((action) => '- ${_capitalize(action.replaceAll('_', ' '))}').join('\n')}

**🔗 Navegación:**
${((entry.value as Map<String, dynamic>)['navigation'] as List<String>).length > 0 ? 
  ((entry.value as Map<String, dynamic>)['navigation'] as List<String>).map((nav) => '- `$nav`').join('\n') : 
  '- No se detectó navegación explícita'}

**💾 Fuentes de Datos:**
${((entry.value as Map<String, dynamic>)['data_sources'] as List<String>).map((source) => '- ${_capitalize(source.replaceAll('_', ' '))}').join('\n')}

---
''').join('\n')}
''';
    
    _writeFile('MATRIZ_CARACTERISTICAS.md', content);
  }
  
  // Métodos auxiliares
  String _generateRoleSummary() {
    final roles = analysisData['detected_roles'] as Map<String, dynamic>;
    final userStories = analysisData['user_stories'] as Map<String, dynamic>;
    
    final roleStories = <String, int>{};
    for (final story in userStories.values) {
      final role = (story as Map<String, dynamic>)['role'] as String;
      roleStories[role] = (roleStories[role] ?? 0) + 1;
    }
    
    return roles.entries.map((entry) {
      final role = entry.key;
      final screens = entry.value;
      final stories = roleStories[role] ?? 0;
      return '- **${_capitalize(role)}**: $screens pantallas, $stories historias';
    }).join('\n');
  }
  
  String _getRoleBadge(String role) {
    final badges = {
      'client': '👤 Cliente',
      'admin': '👨‍💼 Administrador', 
      'driver': '🚗 Domiciliario',
    };
    return badges[role] ?? '❓ Desconocido';
  }
  
  String _estimateComplexity(String feature) {
    final complexFeatures = ['sistema_pagos', 'metricas_estadisticas', 'control_inventario'];
    final mediumFeatures = ['sistema_domicilios', 'gestion_pedidos', 'seguimiento_pedidos'];
    
    if (complexFeatures.contains(feature)) return 'Alta 🔴';
    if (mediumFeatures.contains(feature)) return 'Media 🟡';
    return 'Baja 🟢';
  }
  
  String _calculateRoleCoverage() {
    final roles = analysisData['detected_roles'] as Map<String, dynamic>;
    final expectedRoles = ['client', 'admin', 'driver'];
    final coveredRoles = roles.keys.where((role) => expectedRoles.contains(role)).length;
    
    return '${((coveredRoles / expectedRoles.length) * 100).toInt()}%';
  }
  
  String _calculateAverageComplexity(Map<String, dynamic> userStories) {
    int total = 0;
    int count = 0;
    
    for (final story in userStories.values) {
      final feature = (story as Map<String, dynamic>)['feature'] as String;
      final complexity = _estimateComplexity(feature);
      
      if (complexity.contains('Alta')) total += 3;
      else if (complexity.contains('Media')) total += 2;
      else total += 1;
      
      count++;
    }
    
    final average = count > 0 ? total / count : 0;
    if (average >= 2.5) return 'Alta 🔴';
    if (average >= 1.5) return 'Media 🟡';
    return 'Baja 🟢';
  }
  
  String _generateFlowDiagram(List<dynamic> flow, String role) {
    if (flow.isEmpty) return '*No se detectaron pantallas para este rol*';
    
    final buffer = StringBuffer();
    buffer.writeln('```');
    
    for (int i = 0; i < flow.length; i++) {
      final screen = flow[i] as Map<String, dynamic>;
      final prefix = i == 0 ? '🚀 ' : '   ';
      buffer.writeln('$prefix${screen['type']} → ${screen['screen']}');
      
      // Mostrar características principales
      final features = (screen['features'] as List<String>).take(2);
      if (features.isNotEmpty) {
        buffer.writeln('     📍 ${features.map((f) => _capitalize(f.replaceAll('_', ' '))).join(', ')}');
      }
    }
    
    buffer.writeln('```');
    return buffer.toString();
  }
  
  String _generateFlowSummary(Map<String, dynamic> userFlows) {
    final buffer = StringBuffer();
    
    for (final entry in userFlows.entries) {
      final role = _capitalize(entry.key.replaceAll('_flow', ''));
      final flow = entry.value as List<dynamic>;
      buffer.writeln('- **$role**: ${flow.length} pantallas en el flujo');
    }
    
    return buffer.toString();
  }
  
  String _generateRoleDetail(Map<String, dynamic> screenAnalysis, String role) {
    final roleScreens = screenAnalysis.entries.where((entry) => 
      (entry.value as Map<String, dynamic>)['user_role'] == role
    );
    
    if (roleScreens.isEmpty) return '*No se detectaron pantallas para este rol*';
    
    final buffer = StringBuffer();
    
    for (final entry in roleScreens) {
      final screen = entry.value as Map<String, dynamic>;
      buffer.writeln('- **${entry.key}**');
      buffer.writeln('  - Tipo: ${screen['screen_type']}');
      buffer.writeln('  - Características: ${(screen['features'] as List<String>).length}');
      buffer.writeln('  - Acciones: ${(screen['actions'] as List<String>).length}');
    }
    
    return buffer.toString();
  }
  
  String _generateRoleRecommendations(Map<String, dynamic> roles) {
    final recommendations = <String>[];
    
    if ((roles['client'] ?? 0) < 3) {
      recommendations.add('Considerar agregar más pantallas para clientes (catálogo, perfil, historial)');
    }
    
    if ((roles['admin'] ?? 0) < 2) {
      recommendations.add('El panel de administración podría necesitar más funcionalidades');
    }
    
    if ((roles['driver'] ?? 0) < 2) {
      recommendations.add('Los domiciliarios podrían beneficiarse de más herramientas de gestión');
    }
    
    return recommendations.isNotEmpty ? 
      recommendations.map((r) => '- $r').join('\n') : 
      '- La distribución de roles parece balanceada ✅';
  }
  
  void _writeFile(String filename, String content) {
    File(filename).writeAsStringSync(content);
    print('🧠 Generado: $filename - Documentación inteligente');
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}

void main() {
  print('🧠 Iniciando análisis inteligente del proyecto...');
  
  final analyzer = CodeAnalyzer('.');
  final analysisData = analyzer.analyzeProject();
  
  print('📊 Análisis completado:');
  print('- Pantallas analizadas: ${analysisData['screens_analyzed']}');
  print('- Roles detectados: ${analysisData['detected_roles']}');
  print('- Historias generadas: ${(analysisData['user_stories'] as Map<String, dynamic>).length}');
  
  final generator = SmartDocumentationGenerator(analysisData);
  generator.generateSmartDocumentation();
  
  print('✅ Documentación inteligente generada!');
  print('📁 Archivos creados:');
  print('  - HISTORIAS_INTELIGENTES.md (Historias de usuario reales)');
  print('  - FLUJOS_USUARIO.md (Flujos de cliente/admin/driver)');
  print('  - ANALISIS_ROLES.md (Análisis de roles)');
  print('  - MATRIZ_CARACTERISTICAS.md (Matriz de características)');
  print('\n🚀 El sistema ENTENDIÓ lo que hace tu app!');
}