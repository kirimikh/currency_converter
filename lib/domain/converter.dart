import 'package:decimal/decimal.dart';
import 'currency.dart';

Decimal convert(
  Decimal amount, {
  required Currency from,
  required Currency to,
}) {
  final fromValue = amount * ratePerUnit(currency: from);
  final toValue = fromValue / ratePerUnit(currency: to);
  // Keep one digit past the cents: it alone decides which way round() goes.
  // With only 2 digits the result would be truncated instead of rounded.
  return toValue.toDecimal(scaleOnInfinitePrecision: 3).round(scale: 2);
}

Decimal ratePerUnit({required Currency currency}) {
  return (currency.rate / currency.scale.toDecimal()).toDecimal();
}
