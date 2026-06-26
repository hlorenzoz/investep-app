import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/forms/deposit_field.dart';
import '../../../capital/presentation/capital_controller.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 4: depósito inicial. Delega la UI y la sincronización %/monto en el
/// widget compartido [DepositField]; este slide sólo cablea el estado del
/// wizard (lectura de `data`/`available`, escritura vía `setDeposit`).
class DepositSlide extends ConsumerWidget {
  const DepositSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(wizardControllerProvider(mode)).data;
    final available =
        ref.watch(capitalControllerProvider).value?.available ??
        data.totalCapital ??
        0;

    return DepositField(
      value: data.deposit,
      onChanged: (d) =>
          ref.read(wizardControllerProvider(mode).notifier).setDeposit(d),
      totalCapital: data.totalCapital ?? 0,
      available: available,
      currency: data.currency,
    );
  }
}
