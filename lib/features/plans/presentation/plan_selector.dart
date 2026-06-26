import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../capital/domain/account_type.dart';
import 'plans_provider.dart';

/// Lista seleccionable de planes para un tipo de cuenta. Observa
/// [plansProvider] y maneja loading/error/vacío. Reutilizado por el slide de
/// planes del wizard y por la edición de cuenta.
class PlanSelector extends ConsumerWidget {
  const PlanSelector({
    super.key,
    required this.accountType,
    required this.selectedPlanId,
    required this.onSelect,
  });

  final AccountType accountType;
  final int? selectedPlanId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final plansAsync = ref.watch(plansProvider(accountType));

    return plansAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('$e', style: const TextStyle(color: AppColors.negative)),
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
                color: selectedPlanId == plan.id
                    ? AppColors.accent.withValues(alpha: 0.25)
                    : Colors.white.withValues(alpha: 0.04),
                child: ListTile(
                  title: Text(plan.label ?? 'Plan ${plan.id}'),
                  subtitle: Text(
                    '${l10n.planTargetMonthly}: ${plan.targetMonthlyPct}%',
                  ),
                  trailing: selectedPlanId == plan.id
                      ? const Icon(
                          LucideIcons.circleCheck,
                          color: AppColors.accent,
                        )
                      : null,
                  onTap: () => onSelect(plan.id),
                ),
              ),
          ],
        );
      },
    );
  }
}
