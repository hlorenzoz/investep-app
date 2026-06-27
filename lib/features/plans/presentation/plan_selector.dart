import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
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
    final glassTheme = context.glass;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return plansAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text('$e', style: TextStyle(color: glassTheme.negative)),
      ),
      data: (plans) {
        if (plans.isEmpty) {
          return Text(
            l10n.plansEmpty,
            style: TextStyle(color: glassTheme.textSecondary),
          );
        }
        return Column(
          children: [
            for (final plan in plans)
              Card(
                color: selectedPlanId == plan.id
                    ? (isDark
                        ? AppColors.accent.withValues(alpha: 0.25)
                        : Colors.black.withValues(alpha: 0.08))
                    : glassTheme.glassFill,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: glassTheme.glassBorder),
                ),
                elevation: 0,
                child: ListTile(
                  title: Text(
                    plan.label ?? 'Plan ${plan.id}',
                    style: TextStyle(
                      color: glassTheme.textPrimary,
                      fontWeight: selectedPlanId == plan.id ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.planTargetMonthly}: ${plan.targetMonthlyPct}%',
                        style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${l10n.planTargetDaily}: ${plan.effectiveDailyPct}%',
                        style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
                      ),
                    ],
                  ),
                  trailing: selectedPlanId == plan.id
                      ? Icon(
                          LucideIcons.circleCheck,
                          color: isDark ? AppColors.accent : Colors.black,
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
