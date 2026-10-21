import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:currency_converter/domain/currency.dart';
import 'package:currency_converter/domain/converter.dart';

void main() {
  test('converts 17 USD to 50.92 BYN at rate 2.9950', () {
    final usd = Currency(
      code: 'USD',
      scale: 1,
      name: 'Доллар США',
      rate: Decimal.parse('2.9950'),
    );

    final byn = Currency.byn;

    expect(
      convert(Decimal.parse('17'), from: usd, to: byn),
      Decimal.parse('50.92'),
    );
  });

  test('converts 17 BYN to 5.68 USD at rate 2.9950', () {
    final usd = Currency(
      code: 'USD',
      scale: 1,
      name: 'Доллар США',
      rate: Decimal.parse('2.9950'),
    );

    final byn = Currency.byn;

    expect(
      convert(Decimal.parse('17'), from: byn, to: usd),
      Decimal.parse('5.68'),
    );
  });
}
