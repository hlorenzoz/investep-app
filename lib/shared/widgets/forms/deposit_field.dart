import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../features/setup/presentation/wizard_data.dart';
import '../../format/money.dart';

/// Campo de depósito reutilizable: título + disponible + toggle "% del capital"
/// / "monto" + input + monto resuelto + mensaje de inválido.
///
/// Self-contained: maneja su propio [TextEditingController] sembrado de [value]
/// y emite cambios por [onChanged]. Lo usan el slide de depósito del wizard y la
/// edición de cuenta, para no duplicar la lógica de sincronización (con sus
/// casos borde: limpiar a null al tipear vacío, preservar ambos valores al
/// togglear, mantener el offset del cursor).
class DepositField extends StatefulWidget {
  const DepositField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.totalCapital,
    required this.available,
    required this.currency,
  });

  final DepositInput value;
  final ValueChanged<DepositInput> onChanged;

  /// Capital total, para resolver el monto cuando el modo es "% del capital".
  final num totalCapital;

  /// Tope válido del depósito (disponible).
  final num available;
  final String currency;

  @override
  State<DepositField> createState() => _DepositFieldState();
}

class _DepositFieldState extends State<DepositField> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    final d = widget.value;
    final initial = d.amount;
    _input = TextEditingController(text: initial != null ? '$initial' : '');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _write({String? raw}) {
    final cur = widget.value;
    var amount = cur.amount;
    if (raw != null) {
      amount = num.tryParse(raw.replaceAll(',', '.'));
    }
    widget.onChanged(DepositInput(mode: DepositMode.amount, amount: amount));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = widget.value;
    final resolved = data.resolved(widget.totalCapital);
    final isValid = data.isValid(
      total: widget.totalCapital,
      available: widget.available,
    );
    final glassTheme = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.depositTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.depositAvailable}: '
          '${formatMoney(widget.available, widget.currency)}',
          style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _input,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (raw) => _write(raw: raw),
          style: TextStyle(color: glassTheme.textPrimary),
          decoration: InputDecoration(
            labelText: l10n.amountLabel,
            labelStyle: TextStyle(color: glassTheme.textSecondary),
            suffixText: widget.currency,
            suffixStyle: TextStyle(color: glassTheme.textSecondary),
          ),
        ),
        if (!isValid && resolved > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.depositInvalid,
            style: TextStyle(color: glassTheme.negative, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
