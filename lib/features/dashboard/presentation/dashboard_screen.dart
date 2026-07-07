import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/format/money.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/capital_overview.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../setup/presentation/setup_mode.dart';
import 'dashboard_providers.dart';
import 'widgets/dashboard_charts.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final capitalAsync = ref.watch(capitalControllerProvider);

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.chartPie, size: 22),
              const SizedBox(width: 10),
              Text(l10n.navDashboard),
            ],
          ),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
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
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    if (!overview.hasCapital) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: GlassCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                LucideIcons.pieChart,
                size: 64,
                color: Theme.of(context).colorScheme.secondary,
              ),
              const SizedBox(height: 24),
              Text(
                l10n.dashboardEmptyTitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: glassTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Definí tu capital inicial y vinculá tus cuentas de bróker para empezar a monitorear tu portfolio.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: glassTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => context.go('/setup', extra: SetupMode.initialSetup),
                icon: const Icon(LucideIcons.settings, size: 20),
                label: Text(l10n.configureCapitalCta),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final gateState = ref.watch(authGateProvider);
    final user = gateState is GateAuthenticated ? gateState.user : null;
    final assetsCountAsync = ref.watch(dashboardAssetsCountProvider);

    // Calcular el capital acumulado simulado (6% de rendimiento acumulado sobre depósito inicial)
    double totalMarketValue = 0;
    for (final a in overview.allocations) {
      totalMarketValue += a.initialDeposit * 1.06;
    }
    // Si no hay allocations, el capital de mercado es el capital inicial
    if (overview.allocations.isEmpty) {
      totalMarketValue = (overview.capital?.totalCapital ?? 0).toDouble();
    }

    final currency = overview.capital?.currency ?? 'USD';

    // Agrupar saldos por Broker
    final Map<String, double> brokerSaldos = {};
    for (final a in overview.allocations) {
      final double currentBalance = a.initialDeposit * 1.06;
      brokerSaldos[a.brokerSlug] = (brokerSaldos[a.brokerSlug] ?? 0) + currentBalance;
    }

    final List<ChartSegment> brokerSegments = [];
    final List<Color> palette = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF8B5CF6), // Purple
    ];
    int colorIdx = 0;

    brokerSaldos.forEach((broker, saldo) {
      Color color;
      final slug = broker.toLowerCase();
      if (slug.contains('ibkr') || slug.contains('interactive')) {
        color = const Color(0xFF3B82F6); // Blue
      } else if (slug.contains('tasty') || slug.contains('tastytrade')) {
        color = const Color(0xFFF97316); // Orange
      } else if (slug.contains('etrade')) {
        color = const Color(0xFF10B981); // Emerald
      } else {
        color = palette[colorIdx % palette.length];
        colorIdx++;
      }

      brokerSegments.add(ChartSegment(
        label: broker.toUpperCase(),
        value: saldo,
        color: color,
      ));
    });

    // Agrupar saldos por Tipo de Cuenta (Acciones vs Opciones)
    double totalEquity = 0;
    double totalOptions = 0;
    for (final a in overview.allocations) {
      final double currentBalance = a.initialDeposit * 1.06;
      if (a.accountType == AccountType.equity) {
        totalEquity += currentBalance;
      } else {
        totalOptions += currentBalance;
      }
    }

    final List<ChartSegment> accountTypeSegments = [];
    if (totalEquity > 0) {
      accountTypeSegments.add(ChartSegment(
        label: l10n.accountTypeEquity,
        value: totalEquity,
        color: const Color(0xFF14B8A6), // Teal
      ));
    }
    if (totalOptions > 0) {
      accountTypeSegments.add(ChartSegment(
        label: l10n.accountTypeOptions,
        value: totalOptions,
        color: const Color(0xFF6366F1), // Indigo
      ));
    }

    final String planName = user?.planSlug != null
        ? user!.planSlug!.toUpperCase()
        : (user?.role == 'admin' || user?.role == 'manager' ? 'PLATINUM' : 'BRONZE');

    return ListView(
      padding: const EdgeInsets.all(20.0),
      children: [
        // 1. Tarjeta Resumen de Membresía y Activos
        GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SALDO TOTAL ESTIMADO',
                        style: TextStyle(
                          color: glassTheme.textSecondary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        formatMoney(totalMarketValue, currency),
                        style: TextStyle(
                          color: glassTheme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.shieldCheck, size: 14, color: Color(0xFFF59E0B)),
                        const SizedBox(width: 6),
                        Text(
                          planName,
                          style: TextStyle(
                            color: glassTheme.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Divider(height: 24, color: glassTheme.glassBorder),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(LucideIcons.activity, color: glassTheme.positive, size: 16),
                      const SizedBox(width: 8),
                      assetsCountAsync.when(
                        data: (count) => Text(
                          '$count activos habilitados en tu plan',
                          style: TextStyle(
                            color: glassTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        loading: () => Text(
                          'Cargando activos...',
                          style: TextStyle(
                            color: glassTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        error: (_, __) => Text(
                          'Activos ilimitados',
                          style: TextStyle(
                            color: glassTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => context.go('/relations'),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Row(
                        children: [
                          Text(
                            'Ver activos',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                          const Icon(LucideIcons.chevronRight, size: 14),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (overview.hasAllocations) ...[
          // 2. Gráficos de Distribución por Broker
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Distribución por Bróker',
                  style: TextStyle(
                    color: glassTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DoughnutChart(
                  segments: brokerSegments,
                  centerTitle: formatMoney(totalMarketValue, currency),
                  centerSubtitle: 'Total Cartera',
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 3. Gráficos de Distribución por Tipo de Cuenta (Acciones vs Opciones)
          GlassCard(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de Cuenta (Consolidado)',
                  style: TextStyle(
                    color: glassTheme.textPrimary,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                DistributionProgressBar(
                  segments: accountTypeSegments,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // 4. Desglose detallado por Bróker y Tipo de Cuenta
          Text(
            'Detalle por Bróker',
            style: TextStyle(
              color: glassTheme.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...brokerSegments.map((brokerSeg) {
            // Filtrar las allocations asociadas a este broker
            final brokerAllocations = overview.allocations.where(
              (a) => a.brokerSlug.toUpperCase() == brokerSeg.label,
            );

            double brokerEquity = 0;
            double brokerOptions = 0;
            for (final a in brokerAllocations) {
              final double val = a.initialDeposit * 1.06;
              if (a.accountType == AccountType.equity) {
                brokerEquity += val;
              } else {
                brokerOptions += val;
              }
            }

            final List<ChartSegment> brokerTypeSegments = [];
            if (brokerEquity > 0) {
              brokerTypeSegments.add(ChartSegment(
                label: l10n.accountTypeEquity,
                value: brokerEquity,
                color: const Color(0xFF14B8A6),
              ));
            }
            if (brokerOptions > 0) {
              brokerTypeSegments.add(ChartSegment(
                label: l10n.accountTypeOptions,
                value: brokerOptions,
                color: const Color(0xFF6366F1),
              ));
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: GlassCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: brokerSeg.color,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              brokerSeg.label,
                              style: TextStyle(
                                color: glassTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formatMoney(brokerSeg.value, currency),
                          style: TextStyle(
                            color: glassTheme.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    if (brokerTypeSegments.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      DistributionProgressBar(
                        segments: brokerTypeSegments,
                        height: 8,
                      ),
                    ],
                  ],
                ),
              ),
            );
          }),
        ] else ...[
          GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Icon(LucideIcons.building2, size: 44, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(height: 16),
                Text(
                  'No tenés cuentas de bróker configuradas',
                  style: TextStyle(
                    color: glassTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Vinculá tu primer bróker para visualizar la distribución de tu capital.',
                  style: TextStyle(
                    color: glassTheme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => context.go('/setup', extra: SetupMode.addBroker),
                  icon: const Icon(LucideIcons.plus, size: 18),
                  label: Text(l10n.addBrokerAccount),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ErrorState extends ConsumerWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.serverCrash, color: glassTheme.negative, size: 48),
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
