import 'package:currency_converter/data/nbrb_repository.dart';
import 'package:currency_converter/domain/converter.dart';
import 'package:currency_converter/domain/currency.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

class ConverterState extends ChangeNotifier {
  ConverterState(this._repository);

  final NbrbRepository _repository;
  Decimal? _sourceAmount;
  bool _isLoading = false;
  String? _error;
  List<Currency> _rows = [];
  List<Currency> _currencies = [];
  int? _sourceRow;

  bool get isLoading => _isLoading;

  /// Message to show instead of the rows; null when there is no error.
  String? get error => _error;

  /// The currencies shown on screen, one per row.
  List<Currency> get rows => _rows;

  /// Currencies the picker offers: the ones not on screen yet.
  List<Currency> get availableCurrencies {
    return _currencies
        .where((c) => !_rows.any((r) => r.code == c.code))
        .toList();
  }

  /// Index of the row the user is typing in; null while nothing is entered.
  int? get sourceRow => _sourceRow;

  Future<void> load() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currencies = await _repository.fetchRates();

      final List<String> codes;

      if (_rows.isEmpty) {
        codes = ['BYN', 'USD', 'EUR'];
        _sourceRow = 0;
        _sourceAmount = Decimal.fromInt(100);
      } else {
        codes = _rows.map((c) => c.code).toList();
      }

      final newRows = <Currency>[];
      for (final code in codes) {
        final found = _currencies.where((c) => c.code == code).firstOrNull;
        if (found != null) {
          newRows.add(found);
        }
      }
      _rows = newRows;
    } on RatesException catch (e) {
      _error = e.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setAmount(int row, String text) {
    _sourceRow = row;
    _sourceAmount = Decimal.tryParse(text.replaceAll(',', '.'));
    notifyListeners();
  }

  void changeCurrency(int row, Currency currency) {
    _rows[row] = currency;
    notifyListeners();
  }

  void addCurrency(Currency currency) {
    _rows.add(currency);
    notifyListeners();
  }

  void removeRow(int row) {
    final source = _sourceRow;
    if (row == source) {
      _sourceRow = null;
      _sourceAmount = null;
    } else if (source != null && row < source) {
      _sourceRow = source - 1;
    }
    _rows.removeAt(row);
    notifyListeners();
  }

  /// Amount for [row]: what the user typed in the source row, the converted
  /// amount in the others, null while nothing valid is entered.
  Decimal? amountFor(int row) {
    final source = _sourceRow;
    final amount = _sourceAmount;
    if (source == null || amount == null) {
      return null;
    } else if (row == source) {
      return amount;
    } else {
      return convert(amount, from: _rows[source], to: _rows[row]);
    }
  }
}
