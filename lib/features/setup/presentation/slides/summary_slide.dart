import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/format/money.dart';
import '../../../brokers/domain/broker.dart';
import '../../../brokers/presentation/brokers_provider.dart';
import '../../../capital/domain/account_type.dart';
import '../../../capital/presentation/capital_controller.dart';
import '../../../plans/domain/investment_plan.dart';
import '../../../plans/presentation/plans_provider.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 5: resumen de la allocation antes de confirmar (`POST` lo dispara el
/// footer). Muestra el error mapeado (409/404/422) si la confirmación falla.
class SummarySlide extends ConsumerWidget {
  const SummarySlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final state = ref.watch(wizardControllerProvider(mode));
    final controller = ref.read(wizardControllerProvider(mode).notifier);
    final data = state.data;
    final accountType = data.accountType ?? AccountType.equity;

    final brokers = ref.watch(brokersProvider).value ?? const <Broker>[];
    Broker? broker;
    for (final b in brokers) {
      if (b.id == data.brokerId) {
        broker = b;
        break;
      }
    }
    final brokerName = broker?.name;

    final plans =
        ref.watch(plansProvider(accountType)).value ?? const <InvestmentPlan>[];
    InvestmentPlan? plan;
    for (final p in plans) {
      if (p.id == data.investmentPlanId) {
        plan = p;
        break;
      }
    }

    final available =
        ref.watch(capitalControllerProvider).value?.available ??
        data.totalCapital ??
        0;
    final remaining = available - data.resolvedDeposit;

    final error =
        state is WizardStepError && state.step == WizardStep.allocation
        ? state.message
        : null;

    final accountTypeLabel = accountType == AccountType.equity
        ? l10n.accountTypeEquity
        : l10n.accountTypeOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.summaryTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.summaryEditHint,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _row(
          l10n.summaryBroker,
          brokerName ?? '#${data.brokerId}',
          onTap: () => controller.goTo(WizardSlide.broker),
        ),
        _row(
          l10n.summaryAccountType,
          accountTypeLabel,
          onTap: () => controller.goTo(WizardSlide.accountType),
        ),
        _row(
          l10n.summaryPlan,
          plan != null
              ? '${plan.label ?? 'Plan ${plan.id}'} · ${plan.targetMonthlyPct}%'
              : '#${data.investmentPlanId}',
          onTap: () => controller.goTo(WizardSlide.plan),
        ),
        _row(
          l10n.summaryDeposit,
          formatMoney(data.resolvedDeposit, data.currency),
          onTap: () => controller.goTo(WizardSlide.deposit),
        ),
        // La moneda sólo se edita en initialSetup (en el slide de capital); en
        // addBroker viene fija del capital existente.
        _row(
          l10n.summaryCurrency,
          data.currency,
          onTap: mode == SetupMode.initialSetup
              ? () => controller.goTo(WizardSlide.capital)
              : null,
        ),
        _row(l10n.summaryRemaining, formatMoney(remaining, data.currency)),
        if (error != null) ...[
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: AppColors.negative, fontSize: 13),
          ),
        ],
      ],
    );
  }

  Widget _row(String label, String value, {VoidCallback? onTap}) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 8),
                  const Icon(
                    LucideIcons.pencil,
                    size: 15,
                    color: AppColors.accentSoft,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: row,
    );
  }
}
