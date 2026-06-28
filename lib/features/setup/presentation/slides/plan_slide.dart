import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../capital/domain/account_type.dart';
import '../../../plans/presentation/plan_selector.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 3: lista de planes para el tipo de cuenta elegido. La selección define
/// `investmentPlanId` (obligatoria para avanzar). Delega la lista en el widget
/// compartido [PlanSelector].
class PlanSlide extends ConsumerWidget {
  const PlanSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(wizardControllerProvider(mode)).data;
    final accountType = data.accountType ?? AccountType.equity;

    final glassTheme = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.planTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        PlanSelector(
          accountType: accountType,
          selectedPlanId: data.investmentPlanId,
          onSelect: (id) =>
              ref.read(wizardControllerProvider(mode).notifier).setPlan(id),
        ),
      ],
    );
  }
}
