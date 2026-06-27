import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/format/money.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/theme_selector.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/domain/capital_overview.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../setup/presentation/setup_deferred_provider.dart';
import '../../setup/presentation/setup_mode.dart';

/// Dashboard de capital. Consume `GET /capital`:
/// - sin capital → empty-state con CTA al wizard (initialSetup) + banner si se
///   pospuso la configuración.
/// - con capital sin cuentas → CTA para agregar la primera cuenta.
/// - con allocations → lista (broker, tipo, plan, depósito, % del capital) +
///   total asignado/disponible, y FAB para agregar otra cuenta (addBroker).
class PortfolioScreen extends ConsumerWidget {
  const PortfolioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final capitalAsync = ref.watch(capitalControllerProvider);
    final overview = capitalAsync.value;
    final showFab = overview != null && overview.hasCapital;
    final glassTheme = context.glass;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.wallet, size: 22),
              const SizedBox(width: 10),
              Text(l10n.dashboardTitle),
            ],
          ),
          actions: const [
            ThemeSelector(),
            SizedBox(width: 16),
          ],
        ),
        floatingActionButton: showFab
            ? FloatingActionButton.extended(
                onPressed: () =>
                    context.go('/setup', extra: SetupMode.addBroker),
                icon: const Icon(LucideIcons.plus),
                label: Text(l10n.addBrokerAccount),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: capitalAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => _ErrorState(message: l10n.dashboardLoadError),
                data: (overview) => _Content(overview: overview),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.overview});

  final CapitalOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!overview.hasCapital) {
      final deferred = ref.watch(setupDeferredProvider);
      return _EmptyState(showBanner: deferred);
    }
    if (!overview.hasAllocations) {
      return const _EmptyAllocations();
    }
    return _CapitalList(overview: overview);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showBanner});

  final bool showBanner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (showBanner) ...[
          _Banner(text: l10n.completeSetupBanner),
          const SizedBox(height: 16),
        ],
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.pieChart,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dashboardEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: glassTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.dashboardEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: glassTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go('/setup', extra: SetupMode.initialSetup),
                icon: const Icon(LucideIcons.settings, size: 18),
                label: Text(l10n.configureCapitalCta),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyAllocations extends StatelessWidget {
  const _EmptyAllocations();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.building2,
                size: 48,
                color: theme.colorScheme.secondary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.dashboardEmptySubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(color: glassTheme.textSecondary),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () =>
                    context.go('/setup', extra: SetupMode.addBroker),
                icon: const Icon(LucideIcons.plus, size: 18),
                label: Text(l10n.addBrokerAccount),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CapitalList extends StatelessWidget {
  const _CapitalList({required this.overview});

  final CapitalOverview overview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currency = overview.capital!.currency;
    final glassTheme = context.glass;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      children: [
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _summaryRow(
                context,
                l10n.capitalTotalLabel,
                formatMoney(overview.capital!.totalCapital, currency),
                emphasized: true,
              ),
              Divider(height: 24, color: glassTheme.glassBorder),
              _summaryRow(
                context,
                l10n.allocatedLabel,
                formatMoney(overview.totalAllocated, currency),
              ),
              const SizedBox(height: 8),
              _summaryRow(
                context,
                l10n.availableLabel,
                formatMoney(overview.available, currency),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final a in overview.allocations)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _AllocationTile(
              allocation: a,
              totalCapital: overview.capital!.totalCapital,
            ),
          ),
      ],
    );
  }

  Widget _summaryRow(BuildContext context, String label, String value, {bool emphasized = false}) {
    final glassTheme = context.glass;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(color: glassTheme.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            color: glassTheme.textPrimary,
            fontSize: emphasized ? 20 : 15,
            fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _AllocationTile extends StatelessWidget {
  const _AllocationTile({required this.allocation, required this.totalCapital});

  final Allocation allocation;
  final num totalCapital;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    final pct = totalCapital > 0
        ? (allocation.initialDeposit / totalCapital * 100)
        : 0;
    final typeLabel = allocation.accountType == AccountType.equity
        ? l10n.accountTypeEquity
        : l10n.accountTypeOptions;

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/account/${allocation.id}'),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  LucideIcons.building2,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  allocation.brokerSlug,
                  style: TextStyle(
                    color: glassTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    typeLabel,
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.planTargetMonthly}: ${allocation.targetMonthlyPct}%',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.planTargetDaily}: ${(allocation.targetMonthlyPct / 30).toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${pct.toStringAsFixed(1)}% ${l10n.ofCapital}',
                  style: TextStyle(
                    color: glassTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              formatMoney(allocation.initialDeposit, allocation.currency),
              style: TextStyle(
                color: glassTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: glassTheme.glassBorder),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.info, color: theme.colorScheme.secondary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: glassTheme.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glassTheme = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.serverCrash,
              color: glassTheme.negative,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: glassTheme.textPrimary),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => ref.invalidate(capitalControllerProvider),
              icon: const Icon(LucideIcons.refreshCw, size: 18),
              label: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }
}
