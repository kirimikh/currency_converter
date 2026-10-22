import 'package:currency_converter/data/nbrb_repository.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

NbrbRepository repositoryReturning(String body, int statusCode) {
  return NbrbRepository(
    MockClient((request) async {
      return http.Response(
        body,
        statusCode,
        headers: {
          'content-type': 'application/json; charset=utf-8',
        }, //headers is needed for russian encoding
      );
    }),
  );
}

Matcher throwsRatesException(String message) =>
    throwsA(isA<RatesException>().having((e) => e.message, 'message', message));

void main() {
  const sampleJson = '''
[
  {"Cur_ID": 431, "Cur_Code": "840", "Date": "2026-10-20T00:00:00", "Cur_Abbreviation": "USD", "Cur_Scale": 1, "Cur_Name": "Доллар США", "Cur_OfficialRate": 2.995},
  {"Cur_ID": 456, "Cur_Code": "643", "Date": "2026-10-20T00:00:00", "Cur_Abbreviation": "RUB", "Cur_Scale": 100, "Cur_Name": "Российских рублей", "Cur_OfficialRate": 3.6127}
]
''';

  test('parses USD and RUB from an NBRB response', () async {
    final repository = repositoryReturning(sampleJson, 200);
    final currencies = await repository.fetchRates();
    expect(currencies.length, 3);

    expect(currencies[0].code, 'BYN');
    expect(currencies[0].scale, 1);
    expect(currencies[0].name, 'Белорусский рубль');
    expect(currencies[0].rate, Decimal.one);

    expect(currencies[1].code, 'USD');
    expect(currencies[1].scale, 1);
    expect(currencies[1].name, 'Доллар США');
    expect(currencies[1].rate, Decimal.parse('2.995'));

    expect(currencies[2].code, 'RUB');
    expect(currencies[2].scale, 100);
    expect(currencies[2].name, 'Российских рублей');
    expect(currencies[2].rate, Decimal.parse('3.6127'));
  });
  test('throws on status 500', () {
    final repository = repositoryReturning('', 500);
    expect(
      repository.fetchRates(),
      throwsRatesException('Сервер НБРБ вернул ошибку 500'),
    );
  });
  test('throws when the body is not JSON', () {
    final repository = repositoryReturning('Сервис недоступен', 200);
    expect(
      repository.fetchRates(),
      throwsRatesException('Неожиданный ответ сервера'),
    );
  });
  test('throws when the JSON has an unexpected shape', () {
    final repository = repositoryReturning('{"error": "oops"}', 200);
    expect(
      repository.fetchRates(),
      throwsRatesException('Неожиданный ответ сервера'),
    );
  });
  test('throws when there is no connection', () {
    final repository = NbrbRepository(
      MockClient((request) async => throw http.ClientException('offline')),
    );
    expect(
      repository.fetchRates(),
      throwsRatesException('Нет соединения с интернетом'),
    );
  });
}
