import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:currency_converter/domain/currency.dart';
import 'package:currency_converter/domain/converter.dart';

void main() {
  final byn = Currency.byn;

  final usd = Currency(
    code: 'USD',
    scale: 1,
    name: 'Доллар США',
    rate: Decimal.parse('2.9950'),
  );

  final rub = Currency(
    code: 'RUB',
    scale: 100,
    name: 'Российский рубль',
    rate: Decimal.parse('3.6127'),
  );

  final eur = Currency(
    code: 'EUR',
    scale: 1,
    name: 'Евро',
    rate: Decimal.parse('3.3565'),
  );

  test('converts 17 USD to 50.92 BYN at rate 2.9950', () {
    expect(
      convert(Decimal.parse('17'), from: usd, to: byn),
      Decimal.parse('50.92'),
    );
  });

  test('converts 17 BYN to 5.68 USD at rate 2.9950', () {
    expect(
      convert(Decimal.parse('17'), from: byn, to: usd),
      Decimal.parse('5.68'),
    );
  });

  test('converts 1000 RUB to 36.13 BYN at rate 3.6127', () {
    expect(
      convert(Decimal.parse('1000'), from: rub, to: byn),
      Decimal.parse('36.13'),
    );
  });

  test('converts 15 USD at rate 2.9950 to 13.38 EUR at rate 3.3565', () {
    expect(
      convert(Decimal.parse('15'), from: usd, to: eur),
      Decimal.parse('13.38'),
    );
  });

  test('converts 17 USD to 17 USD at rate 2.9950', () {
    expect(
      convert(Decimal.parse('17'), from: usd, to: usd),
      Decimal.parse('17'),
    );
  });

  test('converts 0 BYN to 0 USD at rate 2.9950', () {
    expect(convert(Decimal.parse('0'), from: byn, to: usd), Decimal.parse('0'));
  });
}
