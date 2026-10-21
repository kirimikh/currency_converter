import 'package:decimal/decimal.dart';

class Currency {
  final String code;
  final int scale;
  final String name;
  final Decimal rate;

  Currency({
    required this.code,
    required this.scale,
    required this.name,
    required this.rate,
  });

  static final byn = Currency(
    code: 'BYN',
    scale: 1,
    name: 'Белорусский рубль',
    rate: Decimal.one,
  );
}
