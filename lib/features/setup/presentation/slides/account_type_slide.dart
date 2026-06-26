import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../capital/domain/account_type.dart';
import '../../../capital/domain/allocation.dart';
import '../../../capital/presentation/capital_controller.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 2: tipo de cuenta (equity / options). Deshabilita los tipos ya
/// configurados para el broker elegido (combinación broker+tipo única).
class AccountTypeSlide extends ConsumerWidget {
  const AccountTypeSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(wizardControllerProvider(mode)).data;
    final overview = ref.watch(capitalControllerProvider).value;

    final allocations = overview?.allocations ?? const <Allocation>[];
    final configured = <AccountType>{
      for (final a in allocations)
        if (a.brokerId == data.brokerId) a.accountType,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.accountTypeTitle,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        SegmentedButton<AccountType>(
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(
              value: AccountType.equity,
              label: Text(l10n.accountTypeEquity),
              enabled: !configured.contains(AccountType.equity),
            ),
            ButtonSegment(
              value: AccountType.options,
              label: Text(l10n.accountTypeOptions),
              enabled: !configured.contains(AccountType.options),
            ),
          ],
          selected: {?data.accountType},
          onSelectionChanged: (sel) {
            if (sel.isEmpty) return;
            ref
                .read(wizardControllerProvider(mode).notifier)
                .setAccountType(sel.first);
          },
        ),
      ],
    );
  }
}
