import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/format/money.dart';
import '../../../capital/presentation/capital_controller.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';
import '../wizard_data.dart';

/// Slide 4: depósito inicial. Toggle "% del capital" / "monto". En `%` calcula
/// `totalCapital * pct/100` en vivo. Valida `0 < monto <= available`.
class DepositSlide extends ConsumerStatefulWidget {
  const DepositSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  ConsumerState<DepositSlide> createState() => _DepositSlideState();
}

class _DepositSlideState extends ConsumerState<DepositSlide> {
  late final TextEditingController _input;

  @override
  void initState() {
    super.initState();
    final d = ref.read(wizardControllerProvider(widget.mode)).data.deposit;
    final initial = d.mode == DepositMode.percentOfCapital ? d.pct : d.amount;
    _input = TextEditingController(text: initial != null ? '$initial' : '');
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  DepositInput get _current =>
      ref.read(wizardControllerProvider(widget.mode)).data.deposit;

  void _write({DepositMode? mode, String? raw}) {
    final cur = _current;
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
    ref
        .read(wizardControllerProvider(widget.mode).notifier)
        .setDeposit(DepositInput(mode: m, pct: pct, amount: amount));
  }

  /// Sincroniza el TextField al valor almacenado del modo dado (al togglear).
  void _syncInput(DepositMode mode) {
    final v = mode == DepositMode.percentOfCapital
        ? _current.pct
        : _current.amount;
    final text = v != null ? '$v' : '';
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(wizardControllerProvider(widget.mode)).data;
    final available =
        ref.watch(capitalControllerProvider).value?.available ??
        data.totalCapital ??
        0;
    final resolved = data.resolvedDeposit;
    final isValid = data.depositIsValid(available);
    final isPercent = data.deposit.mode == DepositMode.percentOfCapital;

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
          '${l10n.depositAvailable}: ${formatMoney(available, data.currency)}',
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
          selected: {data.deposit.mode},
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
            suffixText: isPercent ? '%' : data.currency,
          ),
        ),
        const SizedBox(height: 12),
        if (isPercent)
          Text(
            '= ${formatMoney(resolved, data.currency)}',
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
