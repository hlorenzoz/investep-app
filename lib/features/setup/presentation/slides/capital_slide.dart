import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 0 (solo initialSetup): capital inicial + moneda.
class CapitalSlide extends ConsumerStatefulWidget {
  const CapitalSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  ConsumerState<CapitalSlide> createState() => _CapitalSlideState();
}

class _CapitalSlideState extends ConsumerState<CapitalSlide> {
  static const _currencies = ['USD', 'EUR', 'ARS'];
  late final TextEditingController _amount;

  @override
  void initState() {
    super.initState();
    final data = ref.read(wizardControllerProvider(widget.mode)).data;
    _amount = TextEditingController(
      text: data.totalCapital != null ? '${data.totalCapital}' : '',
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  void _onAmountChanged(String raw) {
    final value = num.tryParse(raw.replaceAll(',', '.')) ?? 0;
    final currency = ref
        .read(wizardControllerProvider(widget.mode))
        .data
        .currency;
    ref
        .read(wizardControllerProvider(widget.mode).notifier)
        .setCapital(value, currency);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(wizardControllerProvider(widget.mode));
    final currency = state.data.currency;
    final error = state is WizardStepError && state.step == WizardStep.capital
        ? state.message
        : null;

    final glassTheme = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.capitalTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.capitalSubtitle,
          style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          onChanged: _onAmountChanged,
          decoration: InputDecoration(
            labelText: l10n.amountLabel,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: currency,
          decoration: InputDecoration(
            labelText: l10n.currencyLabel,
            border: const OutlineInputBorder(),
          ),
          items: [
            for (final c in _currencies)
              DropdownMenuItem(value: c, child: Text(c)),
          ],
          onChanged: (c) {
            if (c == null) return;
            final amount =
                ref
                    .read(wizardControllerProvider(widget.mode))
                    .data
                    .totalCapital ??
                0;
            ref
                .read(wizardControllerProvider(widget.mode).notifier)
                .setCapital(amount, c);
          },
        ),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error,
            style: TextStyle(color: glassTheme.negative, fontSize: 13),
          ),
        ],
      ],
    );
  }
}
