import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../capital/domain/account_type.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

class AccountTypeSlide extends ConsumerWidget {
  const AccountTypeSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final data = ref.watch(wizardControllerProvider(mode)).data;
    final glassTheme = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.accountTypeTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 24),
        SegmentedButton<AccountType>(
          emptySelectionAllowed: true,
          segments: [
            ButtonSegment(
              value: AccountType.equity,
              label: Text(l10n.accountTypeEquity),
            ),
            ButtonSegment(
              value: AccountType.options,
              label: Text(l10n.accountTypeOptions),
            ),
          ],
          selected: {if (data.accountType != null) data.accountType!},
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
