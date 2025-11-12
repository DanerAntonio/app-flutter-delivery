import 'dart:io';
import 'dart:convert';

class ProjectScanner {
  final String projectPath;
  
  ProjectScanner(this.projectPath);
  
  // Escanear estructura de archivos
  Map<String, dynamic> scanProjectStructure() {
    final libDir = Directory('$projectPath/lib');
    final files = _scanDirectory(libDir);
    
    return {
      'project_name': _getProjectName(),
      'scan_date': DateTime.now().toString(),
      'total_files': files.length,
      'structure': _organizeFiles(files),
      'features_detected': _detectFeatures(files),
      'pending_tasks': _detectPendingTasks(files),
    };
  }
  
  List<String> _scanDirectory(Directory dir) {
    final files = <String>[];
    
    if (!dir.existsSync()) return files;
    
    final entities = dir.listSync(recursive: true);
    
    for (final entity in entities) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity.path.replaceAll('$projectPath/', ''));
      }
    }
    
    return files;
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
  
  Map<String, dynamic> _organizeFiles(List<String> files) {
    final structure = <String, List<String>>{};
    
    for (final file in files) {
      final parts = file.split('/');
      final category = parts.length > 2 ? parts[1] : 'root';
      
      if (!structure.containsKey(category)) {
        structure[category] = [];
      }
      
      structure[category]!.add(parts.last);
    }
    
    return structure;
  }
  
  Map<String, dynamic> _detectFeatures(List<String> files) {
    final features = <String, List<String>>{};
    
    // Detectar características basadas en nombres de archivos
    for (final file in files) {
      if (file.contains('auth') || file.contains('login')) {
        features['authentication'] = [...?features['authentication'], file];
      }
      if (file.contains('admin') || file.contains('metrics')) {
        features['admin_panel'] = [...?features['admin_panel'], file];
      }
      if (file.contains('cart') || file.contains('order')) {
        features['shopping_cart'] = [...?features['shopping_cart'], file];
      }
      if (file.contains('driver') || file.contains('courier')) {
        features['delivery_system'] = [...?features['delivery_system'], file];
      }
      if (file.contains('product') || file.contains('inventory')) {
        features['product_management'] = [...?features['product_management'], file];
      }
    }
    
    return features;
  }
  
  Map<String, dynamic> _detectPendingTasks(List<String> files) {
    final pendingTasks = <String, List<String>>{};
    
    for (final file in files) {
      final content = File('$projectPath/$file').readAsStringSync();
      
      // Detectar TODOs y FIXMEs
      final todoMatches = RegExp(r'//\s*TODO:\s*(.+)').allMatches(content);
      final fixmeMatches = RegExp(r'//\s*FIXME:\s*(.+)').allMatches(content);
      
      if (todoMatches.isNotEmpty) {
        pendingTasks[file] = [
          ...?pendingTasks[file],
          ...todoMatches.map((m) => 'TODO: ${m.group(1)}')
        ];
      }
      
      if (fixmeMatches.isNotEmpty) {
        pendingTasks[file] = [
          ...?pendingTasks[file],
          ...fixmeMatches.map((m) => 'FIXME: ${m.group(1)}')
        ];
      }
    }
    
    return pendingTasks;
  }
}

class DocumentationGenerator {
  final Map<String, dynamic> projectData;
  
  DocumentationGenerator(this.projectData);
  
  void generateAllDocumentation() {
    _generateReadme();
    _generateProjectStructureDoc();
    _generateFeaturesDoc();
    _generateTodoList();
    _generateUserStories();
  }
  
  void _generateReadme() {
    final content = '''
# ${projectData['project_name']}

*Documentación generada automáticamente - ${projectData['scan_date']}*

## 📊 Resumen del Proyecto

- **Total de archivos Dart:** ${projectData['total_files']}
- **Características detectadas:** ${projectData['features_detected'].length}
- **Tareas pendientes:** ${_countPendingTasks()}

## 🚀 Características Implementadas

${_generateFeaturesList()}

## 📁 Estructura del Proyecto

\`\`\`
${_generateStructureTree()}
\`\`\`

## 🔧 Próximos Pasos Sugeridos

${_generateNextSteps()}

---

*Este documento se genera automáticamente. Ejecuta \`dart doc_generator.dart\` para actualizar.*
''';
    
    _writeFile('README_AUTO.md', content);
  }
  
  void _generateProjectStructureDoc() {
    final structure = projectData['structure'] as Map<String, dynamic>;
    
    final content = '''
# Estructura del Proyecto - ${projectData['project_name']}

## 📁 Arquitectura Detectada

${structure.entries.map((entry) => '''
### 📂 ${entry.key.toUpperCase()}
${(entry.value as List).map((file) => '- `$file`').join('\n')}
''').join('\n')}

## 📊 Estadísticas

- **Total de categorías:** ${structure.length}
- **Archivos por categoría:**
${structure.entries.map((e) => '- ${e.key}: ${(e.value as List).length} archivos').join('\n')}

*Generado: ${projectData['scan_date']}*
''';
    
    _writeFile('DOC_ESTRUCTURA.md', content);
  }
  
  void _generateFeaturesDoc() {
    final features = projectData['features_detected'] as Map<String, dynamic>;
    
    final content = '''
# Características Detectadas - ${projectData['project_name']}

## 🎯 Módulos Implementados

${features.entries.map((entry) => '''
### ✅ ${_capitalize(entry.key.replaceAll('_', ' '))}
**Archivos relacionados:**
${(entry.value as List).map((file) => '- `$file`').join('\n')}

**Estado:** 🟡 Implementado
''').join('\n')}

## 📈 Progreso de Desarrollo

- **Módulos detectados:** ${features.length}
- **Cobertura estimada:** ${_calculateCoverage(features)}%

*Análisis realizado: ${projectData['scan_date']}*
''';
    
    _writeFile('DOC_FEATURES.md', content);
  }
  
  void _generateTodoList() {
    final pendingTasks = projectData['pending_tasks'] as Map<String, dynamic>;
    
    if (pendingTasks.isEmpty) {
      _writeFile('DOC_TODOS.md', '# ✅ No hay tareas pendientes detectadas\n\n¡Excelente trabajo!');
      return;
    }
    
    final content = '''
# 📝 Tareas Pendientes - ${projectData['project_name']}

## 🔴 Items por Prioridad

${pendingTasks.entries.map((entry) => '''
### 📄 ${entry.key}
${(entry.value as List).map((task) => '- [ ] $task').join('\n')}
''').join('\n')}

## 📊 Resumen

- **Archivos con tareas pendientes:** ${pendingTasks.length}
- **Total de tareas:** ${_countAllTasks(pendingTasks)}

*Última revisión: ${projectData['scan_date']}*
''';
    
    _writeFile('DOC_TODOS.md', content);
  }
  
  void _generateUserStories() {
    final features = projectData['features_detected'] as Map<String, dynamic>;
    
    final content = '''
# 📋 Historias de Usuario - ${projectData['project_name']}

## 🎯 Historias Detectadas Automáticamente

${features.entries.map((entry) => '''
### [US-${_getFeatureNumber(entry.key)}] - ${_capitalize(entry.key.replaceAll('_', ' '))}
**Estado:** 🟡 En desarrollo
**Archivos relacionados:** ${(entry.value as List).length}

**Criterios de Aceptación:**
- [ ] Funcionalidad completa probada
- [ ] Integración con otros módulos
- [ ] Documentación actualizada
- [ ] Tests implementados

**Archivos:**
${(entry.value as List).map((file) => '- `$file`').join('\n')}

---
''').join('\n')}

## 📈 Métricas

- **Total de historias:** ${features.length}
- **Estado general:** En desarrollo
- **Última actualización:** ${projectData['scan_date']}

*Generado automáticamente basado en la estructura del proyecto*
''';
    
    _writeFile('DOC_HISTORIAS.md', content);
  }
  
  // Métodos auxiliares
  String _generateFeaturesList() {
    final features = projectData['features_detected'] as Map<String, dynamic>;
    return features.entries.map((e) => '- **${_capitalize(e.key.replaceAll('_', ' '))}** (${(e.value as List).length} archivos)').join('\n');
  }
  
  String _generateStructureTree() {
    final structure = projectData['structure'] as Map<String, dynamic>;
    final buffer = StringBuffer();
    
    buffer.writeln('lib/');
    for (final entry in structure.entries) {
      if (entry.key == 'root') {
        for (final file in entry.value as List<String>) {
          buffer.writeln('├── $file');
        }
      } else {
        buffer.writeln('├── ${entry.key}/');
        for (final file in entry.value as List<String>) {
          buffer.writeln('│   ├── $file');
        }
      }
    }
    
    return buffer.toString();
  }
  
  String _generateNextSteps() {
    final pendingTasks = projectData['pending_tasks'] as Map<String, dynamic>;
    
    if (pendingTasks.isEmpty) {
      return '- ✅ Todas las tareas detectadas están completadas\n- 🚀 Considera agregar nuevas funcionalidades';
    }
    
    return '- 🔴 Revisar y completar tareas pendientes\n- 📝 Actualizar documentación de módulos completados\n- 🧪 Implementar tests para funcionalidades existentes';
  }
  
  int _countPendingTasks() {
    final pendingTasks = projectData['pending_tasks'] as Map<String, dynamic>;
    return pendingTasks.values.fold(0, (sum, tasks) => sum + (tasks as List).length);
  }
  
  int _countAllTasks(Map<String, dynamic> pendingTasks) {
    return pendingTasks.values.fold(0, (sum, tasks) => sum + (tasks as List).length);
  }
  
  double _calculateCoverage(Map<String, dynamic> features) {
    // Cálculo simple basado en número de módulos
    final totalPossibleFeatures = 10; // Estimación
    return ((features.length / totalPossibleFeatures) * 100).roundToDouble();
  }
  
  String _capitalize(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
  
  String _getFeatureNumber(String feature) {
    final features = projectData['features_detected'] as Map<String, dynamic>;
    final index = features.keys.toList().indexOf(feature) + 1;
    return index.toString().padLeft(3, '0');
  }
  
  void _writeFile(String filename, String content) {
    File(filename).writeAsStringSync(content);
    print('📄 Generado: $filename');
  }
}

void main() {
  print('🔄 Escaneando proyecto Flutter...');
  
  final scanner = ProjectScanner('.');
  final projectData = scanner.scanProjectStructure();
  
  print('📊 Proyecto escaneado:');
  print('- Nombre: ${projectData['project_name']}');
  print('- Archivos: ${projectData['total_files']}');
  print('- Características: ${projectData['features_detected'].length}');
  
  final generator = DocumentationGenerator(projectData);
  generator.generateAllDocumentation();
  
  print('✅ Documentación generada automáticamente!');
  print('📁 Archivos creados:');
  print('  - README_AUTO.md');
  print('  - DOC_ESTRUCTURA.md');
  print('  - DOC_FEATURES.md');
  print('  - DOC_TODOS.md');
  print('  - DOC_HISTORIAS.md');
  print('\n🚀 Ejecuta de nuevo cuando agregues nuevos archivos!');
}