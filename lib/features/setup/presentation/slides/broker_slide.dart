import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../brokers/domain/broker.dart';
import '../../../brokers/presentation/broker_logo.dart';
import '../../../brokers/presentation/brokers_provider.dart';
import '../../../capital/domain/account_type.dart';
import '../../../capital/domain/allocation.dart';
import '../../../capital/presentation/capital_controller.dart';
import '../setup_mode.dart';
import '../wizard_controller.dart';

/// Slide 1: elegir broker (lista desde `GET /brokers` con búsqueda).
///
/// PRE-REQUISITO: si `/brokers` falla (p. ej. 404), se muestra un estado de
/// error bloqueante con reintento. NUNCA se hardcodean brokers.
class BrokerSlide extends ConsumerStatefulWidget {
  const BrokerSlide({super.key, required this.mode});

  final SetupMode mode;

  @override
  ConsumerState<BrokerSlide> createState() => _BrokerSlideState();
}

class _BrokerSlideState extends ConsumerState<BrokerSlide> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brokersAsync = ref.watch(brokersProvider);
    final data = ref.watch(wizardControllerProvider(widget.mode)).data;
    final allocations =
        ref.watch(capitalControllerProvider).value?.allocations ??
        const <Allocation>[];
    final glassTheme = context.glass;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.brokerTitle,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: glassTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        brokersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => _BrokersError(message: l10n.brokersLoadError),
          data: (brokers) {
            final filtered = brokers
                .where(
                  (b) => b.name.toLowerCase().contains(_query.toLowerCase()),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  onChanged: (v) => setState(() => _query = v),
                  decoration: InputDecoration(
                    hintText: l10n.brokerSearchHint,
                    prefixIcon: const Icon(LucideIcons.search, size: 18),
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                for (final broker in filtered)
                  _BrokerTile(
                    broker: broker,
                    selected: data.brokerId == broker.id,
                    configuredTypes: _configuredTypes(allocations, broker.id),
                    onTap: () => ref
                        .read(wizardControllerProvider(widget.mode).notifier)
                        .setBroker(broker.id),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Set<AccountType> _configuredTypes(
    List<Allocation> allocations,
    int brokerId,
  ) {
    return {
      for (final a in allocations)
        if (a.brokerId == brokerId) a.accountType,
    };
  }
}

class _BrokerTile extends StatelessWidget {
  const _BrokerTile({
    required this.broker,
    required this.selected,
    required this.configuredTypes,
    required this.onTap,
  });

  final Broker broker;
  final bool selected;
  final Set<AccountType> configuredTypes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Deshabilitado sólo si TODAS las combinaciones (equity+options) ya existen.
    final fullyConfigured = configuredTypes.length >= AccountType.values.length;

    return Card(
      color: selected
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
        enabled: !fullyConfigured,
        leading: BrokerLogo(broker: broker),
        title: Text(
          broker.name,
          style: TextStyle(
            color: fullyConfigured
                ? glassTheme.textSecondary.withValues(alpha: 0.5)
                : glassTheme.textPrimary,
          ),
        ),
        subtitle: configuredTypes.isNotEmpty
            ? Text(
                l10n.alreadyConfigured,
                style: TextStyle(
                  color: fullyConfigured
                      ? glassTheme.textSecondary.withValues(alpha: 0.5)
                      : glassTheme.textSecondary,
                ),
              )
            : null,
        trailing: selected
            ? Icon(
                LucideIcons.circleCheck,
                color: isDark ? AppColors.accent : Colors.black,
              )
            : null,
        onTap: fullyConfigured ? null : onTap,
      ),
    );
  }
}

class _BrokersError extends ConsumerWidget {
  const _BrokersError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        children: [
          Icon(LucideIcons.serverCrash, color: glassTheme.negative, size: 48),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: glassTheme.textPrimary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () => ref.invalidate(brokersProvider),
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: Text(l10n.retry),
          ),
        ],
      ),
    );
  }
}
