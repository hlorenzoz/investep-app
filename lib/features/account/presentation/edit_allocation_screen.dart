import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/forms/deposit_field.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../plans/presentation/plan_selector.dart';
import 'edit_allocation_controller.dart';

/// Edición de una allocation existente: plan + depósito (los únicos campos que
/// admite `PATCH /capital/allocations/{id}`). El broker y el tipo de cuenta se
/// muestran read-only; la moneda queda fija (= la del capital).
///
/// Recibe el `id` y lee la allocation VIVA de [capitalControllerProvider]. El
/// formulario se gatea tras `when(data:)`, así el controlador de edición se
/// siembra del último valor guardado (sin carrera de primer frame ni datos
/// viejos al reentrar).
class EditAllocationScreen extends ConsumerWidget {
  const EditAllocationScreen({super.key, required this.allocationId});

  final String allocationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final overviewAsync = ref.watch(capitalControllerProvider);
    final glassTheme = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(l10n.editAccount),
          actions: [
            IconButton(
              icon: const Icon(LucideIcons.trash2, color: AppColors.negative),
              tooltip: l10n.deleteAccount,
              onPressed: () {
                final notifier = ref.read(
                  editAllocationControllerProvider(allocationId).notifier,
                );
                _showDeleteDialog(context, notifier);
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: overviewAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Text(
                    l10n.dashboardLoadError,
                    style: TextStyle(color: glassTheme.textPrimary),
                  ),
                ),
                data: (overview) {
                  Allocation? alloc;
                  for (final a in overview.allocations) {
                    if (a.id == allocationId) {
                      alloc = a;
                      break;
                    }
                  }
                  if (alloc == null) {
                    return Center(
                      child: Text(
                        l10n.accountNotFound,
                        style: TextStyle(color: glassTheme.textSecondary),
                      ),
                    );
                  }
                  return _EditForm(allocation: alloc);
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Formulario en sí. Se monta sólo cuando el capital ya está resuelto y la
/// allocation existe, de modo que el controlador siembra del valor vivo.
class _EditForm extends ConsumerWidget {
  const _EditForm({required this.allocation});

  final Allocation allocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final id = allocation.id;
    final editState = ref.watch(editAllocationControllerProvider(id));
    final notifier = ref.read(editAllocationControllerProvider(id).notifier);

    // Sólo dependemos de totalCapital + available, no de todo el overview.
    final (totalCapital, available) = ref.watch(
      capitalControllerProvider.select((a) {
        final o = a.value;
        return (o?.capital?.totalCapital ?? 0, o?.available ?? 0);
      }),
    );
    // El depósito actual de esta cuenta ya cuenta como asignado: al editarla se
    // "libera", así que el tope válido es el disponible + su depósito original.
    final maxAvailable = available + allocation.initialDeposit;

    final depositValid = editState.deposit.isValid(
      total: totalCapital,
      available: maxAvailable,
    );
    final submitting = editState is EditSubmitting;
    final canSave =
        editState.investmentPlanId != null && depositValid && !submitting;

    final typeLabel = allocation.accountType == AccountType.equity
        ? l10n.accountTypeEquity
        : l10n.accountTypeOptions;

    ref.listen(editAllocationControllerProvider(id), (prev, next) {
      if (next is EditCompleted && context.mounted) context.pop();
    });

    final glassTheme = context.glass;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      children: [
        // Broker + tipo de cuenta (read-only).
        Row(
          children: [
            Icon(
              LucideIcons.building2,
              color: Theme.of(context).colorScheme.secondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              allocation.brokerSlug,
              style: TextStyle(
                color: glassTheme.textPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              typeLabel,
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // Plan.
        Text(
          l10n.planTitle,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        PlanSelector(
          accountType: allocation.accountType,
          selectedPlanId: editState.investmentPlanId,
          onSelect: notifier.setPlan,
        ),
        const SizedBox(height: 24),

        // Depósito (título + disponible + toggle + input los aporta el widget).
        DepositField(
          value: editState.deposit,
          onChanged: notifier.setDeposit,
          totalCapital: totalCapital,
          available: maxAvailable,
          currency: allocation.currency,
        ),

        if (editState is EditError) ...[
          const SizedBox(height: 16),
          Text(
            editState.message,
            style: const TextStyle(color: AppColors.negative, fontSize: 13),
          ),
        ],

        const SizedBox(height: 28),
        ElevatedButton.icon(
          onPressed: canSave ? notifier.submit : null,
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(LucideIcons.check, size: 18),
          label: Text(l10n.save),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: glassTheme.negative,
            side: BorderSide(color: glassTheme.negative),
          ),
          onPressed: submitting
              ? null
              : () => _showDeleteDialog(context, notifier),
          icon: const Icon(LucideIcons.trash2, size: 18),
          label: Text(l10n.deleteAccount),
        ),
      ],
    );
  }
}

void _showDeleteDialog(
  BuildContext context,
  EditAllocationController notifier,
) {
  final l10n = AppLocalizations.of(context);
  final glassTheme = context.glass;

  showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      contentPadding: EdgeInsets.zero,
      content: GlassCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(LucideIcons.trash2, size: 40, color: glassTheme.negative),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountConfirmTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: glassTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              l10n.deleteAccountConfirmMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: glassTheme.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text(l10n.cancel),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: glassTheme.negative,
                    ),
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      notifier.delete();
                    },
                    child: Text(l10n.deleteAccount),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
