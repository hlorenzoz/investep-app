import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../capital/domain/account_type.dart';
import '../../../plans/presentation/plans_provider.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 3: lista de planes para el tipo de cuenta elegido. La selección define
/// `investmentPlanId` (obligatoria para avanzar).
class PlanSlide extends ConsumerWidget {
  const PlanSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(wizardControllerProvider(mode)).data;
    final accountType = data.accountType ?? AccountType.equity;
    final plansAsync = ref.watch(plansProvider(accountType));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.planTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 20),
        plansAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text(
              '$e',
              style: const TextStyle(color: AppColors.negative),
            ),
          ),
          data: (plans) {
            if (plans.isEmpty) {
              return Text(
                l10n.plansEmpty,
                style: const TextStyle(color: AppColors.textSecondary),
              );
            }
            return Column(
              children: [
                for (final plan in plans)
                  Card(
                    color: data.investmentPlanId == plan.id
                        ? AppColors.accent.withValues(alpha: 0.25)
                        : Colors.white.withValues(alpha: 0.04),
                    child: ListTile(
                      title: Text(plan.label ?? 'Plan ${plan.id}'),
                      subtitle: Text(
                        '${l10n.planTargetMonthly}: ${plan.targetMonthlyPct}%',
                      ),
                      trailing: data.investmentPlanId == plan.id
                          ? const Icon(
                              LucideIcons.circleCheck,
                              color: AppColors.accent,
                            )
                          : null,
                      onTap: () => ref
                          .read(wizardControllerProvider(mode).notifier)
                          .setPlan(plan.id),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
