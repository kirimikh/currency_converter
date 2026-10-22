import 'package:currency_converter/domain/currency.dart';
import 'package:currency_converter/ui/converter_state.dart';
import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ConverterScreen extends StatelessWidget {
  const ConverterScreen({super.key, required this.state});

  final ConverterState state;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) => Scaffold(
        appBar: AppBar(
          title: const Text('Конвертер'),
          actions: [
            IconButton(
              tooltip: 'Обновить курсы',
              icon: const Icon(Icons.refresh),
              onPressed: state.isLoading ? null : state.load,
            ),
          ],
        ),
        body: _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    final error = state.error;
    if (error != null) {
      return _ErrorView(message: error, onRetry: state.load);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var row = 0; row < state.rows.length; row++)
          _CurrencyRow(
            key: ValueKey(state.rows[row].code),
            currency: state.rows[row],
            amount: state.amountFor(row),
            isSource: state.sourceRow == row,
            onAmountChanged: (text) => state.setAmount(row, text),
            onCurrencyTap: () => _changeCurrency(context, row),
            onDismissed: () => state.removeRow(row),
          ),
        _AddCurrencyButton(
          onPressed: state.availableCurrencies.isEmpty
              ? null
              : () => _addCurrency(context),
        ),
      ],
    );
  }

  Future<Currency?> _pickCurrency(BuildContext context) {
    return showModalBottomSheet<Currency>(
      context: context,
      showDragHandle: true,
      builder: (context) => ListView(
        children: [
          for (final currency in state.availableCurrencies)
            ListTile(
              leading: _CurrencyAvatar(code: currency.code),
              title: Text(currency.code),
              subtitle: Text(currency.name),
              onTap: () => Navigator.pop(context, currency),
            ),
        ],
      ),
    );
  }

  Future<void> _changeCurrency(BuildContext context, int row) async {
    final currency = await _pickCurrency(context);
    if (currency != null) {
      state.changeCurrency(row, currency);
    }
  }

  Future<void> _addCurrency(BuildContext context) async {
    final currency = await _pickCurrency(context);
    if (currency != null) {
      state.addCurrency(currency);
    }
  }
}

class _CurrencyRow extends StatefulWidget {
  const _CurrencyRow({
    super.key,
    required this.currency,
    required this.amount,
    required this.isSource,
    required this.onAmountChanged,
    required this.onCurrencyTap,
    required this.onDismissed,
  });

  final Currency currency;
  final Decimal? amount;
  final bool isSource;
  final ValueChanged<String> onAmountChanged;
  final VoidCallback onCurrencyTap;
  final VoidCallback onDismissed;

  @override
  State<_CurrencyRow> createState() => _CurrencyRowState();
}

class _CurrencyRowState extends State<_CurrencyRow> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = _format(widget.amount);
  }

  @override
  void didUpdateWidget(_CurrencyRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The row being typed in keeps the user's text; rewriting it would move
    // the cursor. The other rows show the freshly converted amount.
    if (!widget.isSource) {
      _controller.text = _format(widget.amount);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // The source row shows the amount as typed, the others with kopecks.
  String _format(Decimal? amount) {
    if (amount == null) {
      return '';
    }
    final text = widget.isSource
        ? amount.toString()
        : amount.toStringAsFixed(2);
    return text.replaceAll('.', ',');
  }

  void _selectAll() {
    _controller.selection = TextSelection(
      baseOffset: 0,
      extentOffset: _controller.text.length,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final shape = BorderRadius.circular(20);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Dismissible(
        key: ValueKey(widget.currency.code),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => widget.onDismissed(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 24),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: shape,
          ),
          child: Icon(Icons.delete_outline, color: colors.onErrorContainer),
        ),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
          decoration: BoxDecoration(
            color: colors.surfaceContainerLow,
            borderRadius: shape,
            border: Border.all(
              color: widget.isSource ? colors.primary : colors.outlineVariant,
              width: widget.isSource ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              _CurrencyAvatar(
                code: widget.currency.code,
                highlighted: widget.isSource,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: InkWell(
                  onTap: widget.onCurrencyTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              widget.currency.code,
                              overflow: TextOverflow.ellipsis,
                              style: textTheme.titleLarge,
                            ),
                          ),
                          const Icon(Icons.expand_more),
                        ],
                      ),
                      Text(
                        widget.currency.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _controller,
                  textAlign: TextAlign.end,
                  style: textTheme.headlineSmall,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '0',
                  ),
                  onTap: _selectAll,
                  onChanged: widget.onAmountChanged,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyAvatar extends StatelessWidget {
  const _CurrencyAvatar({required this.code, this.highlighted = false});

  final String code;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: 24,
      backgroundColor: highlighted
          ? colors.primaryContainer
          : colors.surfaceContainerHighest,
      foregroundColor: highlighted
          ? colors.onPrimaryContainer
          : colors.onSurfaceVariant,
      // ISO 4217 codes start with the country code: USD -> US, BYN -> BY.
      child: Text(code.substring(0, 2)),
    );
  }
}

class _AddCurrencyButton extends StatelessWidget {
  const _AddCurrencyButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.add),
      label: const Text('Добавить валюту'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(64),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Повторить')),
          ],
        ),
      ),
    );
  }
}
