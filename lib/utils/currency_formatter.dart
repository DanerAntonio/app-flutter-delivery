// lib/utils/currency_formatter.dart - VERSIÓN CORREGIDA
import 'package:intl/intl.dart';

class CurrencyFormatter {
  // Formateador con símbolo ANTES del número (estilo común en apps)
  static final NumberFormat _formatter = NumberFormat.currency(
    locale: 'es_CO',
    symbol: '\$',
    decimalDigits: 0,
    customPattern: '\u00A4#,##0', // Patrón: símbolo + número
  );

  // Formateador solo para números (sin símbolo)
  static final NumberFormat _numberFormatter = NumberFormat.decimalPattern('es_CO');

  /// Formatea un precio con símbolo ANTES: 25000 -> $25.000
  static String format(num price) {
    return _formatter.format(price);
  }

  /// Formatea solo el número con separador de miles: 25000 -> 25.000
  static String formatNumber(num price) {
    return _numberFormatter.format(price);
  }

  /// Formatea manualmente (alternativa si el patrón no funciona)
  static String formatManual(num price) {
    final numberPart = _numberFormatter.format(price);
    return '\$$numberPart';
  }
}

// Extensión para usar directamente en números
extension PriceExtension on num {
  /// Uso: 25000.toCOP() -> $25.000
  String toCOP() {
    // Formateo manual garantizado
    final formatted = NumberFormat('#,##0', 'es_CO').format(this);
    return '\$$formatted';
  }

  /// Uso: 25000.toFormattedNumber() -> 25.000
  String toFormattedNumber() {
    return NumberFormat('#,##0', 'es_CO').format(this);
  }
}

// ============================================
// EJEMPLOS DE USO
// ============================================

/*
// En cualquier widget:
Text(25000.toCOP())              // → $25.000 ✅
Text(18000.toCOP())              // → $18.000 ✅
Text(125500.toCOP())             // → $125.500 ✅

// Solo número sin símbolo:
Text(25000.toFormattedNumber())  // → 25.000

// Usando la clase directamente:
Text(CurrencyFormatter.format(25000))        // → $25.000
Text(CurrencyFormatter.formatNumber(25000))  // → 25.000
*/