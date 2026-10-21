import 'dart:async';
import 'dart:convert';
import 'package:currency_converter/domain/currency.dart';
import 'package:decimal/decimal.dart';
import 'package:http/http.dart' as http;

class NbrbRepository {
  NbrbRepository(this._client);

  // Client is needed for tests,
  // because http.get(url) goes straight to the real network.
  final http.Client _client;

  Future<List<Currency>> fetchRates() async {
    final url = Uri.parse('https://api.nbrb.by/exrates/rates?periodicity=0');

    try {
      final response = await _client
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body);
        return jsonResponse.map((item) => _parseCurrency(item)).toList();
      } else {
        throw RatesException.badStatus(response.statusCode);
      }
    } on TimeoutException {
      throw RatesException.timeout();
    } on http.ClientException {
      throw RatesException.noConnection();
    } on FormatException {
      throw RatesException.badFormat();
    } on TypeError {
      throw RatesException.badFormat();
    }
  }
}

Currency _parseCurrency(Map<String, dynamic> json) {
  return Currency(
    code: json['Cur_Abbreviation'],
    scale: json['Cur_Scale'],
    name: json['Cur_Name'],
    rate: Decimal.parse(json['Cur_OfficialRate'].toString()),
  );
}

class RatesException implements Exception {
  RatesException.noConnection() : message = 'Нет соединения с интернетом';
  RatesException.timeout() : message = 'Сервер НБРБ не отвечает';
  RatesException.badStatus(int code)
    : message = 'Сервер НБРБ вернул ошибку $code';
  RatesException.badFormat() : message = 'Неожиданный ответ сервера';

  final String message;

  @override
  String toString() => message;
}
