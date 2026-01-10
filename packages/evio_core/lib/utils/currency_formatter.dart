import 'package:intl/intl.dart';

/// Helper para formatear precios en formato argentino
class CurrencyFormatter {
  /// Formatea un precio en centavos a formato argentino
  /// Ejemplo: 2900000 → "$29.000"
  static String formatPrice(int? priceInCents, {bool includeDecimals = false}) {
    if (priceInCents == null || priceInCents == 0) {
      return includeDecimals ? '\$0,00' : '\$0';
    }
    
    final priceInPesos = priceInCents / 100;
    
    if (includeDecimals) {
      // Con decimales: $29.000,00
      final formatted = NumberFormat.currency(
        locale: 'es_AR',
        symbol: '',
        decimalDigits: 2,
      ).format(priceInPesos);
      return '\$$formatted';
    } else {
      // Sin decimales: $29.000
      final formatted = NumberFormat.currency(
        locale: 'es_AR',
        symbol: '',
        decimalDigits: 0,
      ).format(priceInPesos);
      return '\$$formatted';
    }
  }
  
  /// Formatea solo el número sin símbolo de moneda
  /// Ejemplo: 2900000 → "29.000"
  static String formatNumber(int? priceInCents) {
    if (priceInCents == null || priceInCents == 0) {
      return '0';
    }
    
    final priceInPesos = priceInCents / 100;
    final formatter = NumberFormat('#,##0', 'es_AR');
    return formatter.format(priceInPesos);
  }
}
