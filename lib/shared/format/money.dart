import 'package:intl/intl.dart';

/// Formatea un monto con su moneda, p. ej. `USD 1.234,56`.
String formatMoney(num amount, String currency) {
  final f = NumberFormat.currency(name: '$currency ', decimalDigits: 2);
  return f.format(amount).trim();
}
