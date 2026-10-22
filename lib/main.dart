import 'package:currency_converter/data/nbrb_repository.dart';
import 'package:currency_converter/ui/converter_screen.dart';
import 'package:currency_converter/ui/converter_state.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  final state = ConverterState(NbrbRepository(http.Client()));
  state.load();

  runApp(
    MaterialApp(
      title: 'Конвертер валют',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.blue,
        brightness: Brightness.dark,
      ),
      home: ConverterScreen(state: state),
    ),
  );
}
