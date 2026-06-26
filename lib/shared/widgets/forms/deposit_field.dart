import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
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
    final initial = d.mode == DepositMode.percentOfCapital ? d.pct : d.amount;
    _input = TextEditingController(text: initial != null ? '$initial' : '');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _write({DepositMode? mode, String? raw}) {
    final cur = widget.value;
    final m = mode ?? cur.mode;
    var pct = cur.pct;
    var amount = cur.amount;
    // Sólo cuando el usuario tipea (`raw != null`) reescribimos el campo activo,
    // incluso a null si borró el campo (un campo vacío NO debe conservar el
    // valor anterior). Al togglear de modo (`raw == null`) se preservan ambos.
    if (raw != null) {
      final value = num.tryParse(raw.replaceAll(',', '.'));
      if (m == DepositMode.percentOfCapital) {
        pct = value;
      } else {
        amount = value;
      }
    }
    widget.onChanged(DepositInput(mode: m, pct: pct, amount: amount));
  }

  /// Sincroniza el TextField al valor almacenado del modo dado (al togglear).
  void _syncInput(DepositMode mode) {
    final v = mode == DepositMode.percentOfCapital
        ? widget.value.pct
        : widget.value.amount;
    final text = v != null ? '$v' : '';
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
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
    final isPercent = data.mode == DepositMode.percentOfCapital;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.depositTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${l10n.depositAvailable}: '
          '${formatMoney(widget.available, widget.currency)}',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 20),
        SegmentedButton<DepositMode>(
          segments: [
            ButtonSegment(
              value: DepositMode.percentOfCapital,
              label: Text(l10n.depositModePercent),
            ),
            ButtonSegment(
              value: DepositMode.amount,
              label: Text(l10n.depositModeAmount),
            ),
          ],
          selected: {data.mode},
          onSelectionChanged: (s) {
            _write(mode: s.first);
            _syncInput(s.first);
          },
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _input,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: (raw) => _write(raw: raw),
          decoration: InputDecoration(
            labelText: isPercent ? l10n.depositModePercent : l10n.amountLabel,
            border: const OutlineInputBorder(),
            suffixText: isPercent ? '%' : widget.currency,
          ),
        ),
        const SizedBox(height: 12),
        if (isPercent)
          Text(
            '= ${formatMoney(resolved, widget.currency)}',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
        if (!isValid && resolved > 0) ...[
          const SizedBox(height: 8),
          Text(
            l10n.depositInvalid,
            style: const TextStyle(color: AppColors.negative, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
