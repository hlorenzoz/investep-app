import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/format/money.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../plans/domain/compound_interest_calculator.dart';
import '../../plans/presentation/widgets/plan_chart_painter.dart';
import 'account_detail_controller.dart';

/// Pantalla de detalle de una cuenta de broker (allocation) con simulaciones de planes.
class AccountDetailScreen extends ConsumerWidget {
  const AccountDetailScreen({super.key, required this.allocationId});

  final String allocationId;

  Allocation? _find(WidgetRef ref) {
    final overview = ref.watch(capitalControllerProvider).value;
    if (overview == null) return null;
    for (final a in overview.allocations) {
      if (a.id == allocationId) return a;
    }
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final glassTheme = context.glass;
    final allocation = _find(ref);

    if (allocation == null) {
      return Container(
        decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: const Text('Cuenta no encontrada')),
          body: Center(
            child: Text(
              'Cuenta no encontrada',
              style: TextStyle(color: glassTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final controller = ref.read(
      accountDetailControllerProvider(allocationId).notifier,
    );
    final state = ref.watch(accountDetailControllerProvider(allocationId));
    final projections = controller.getProjections(allocation);

    // Simulamos el balance actual en el broker (un 6% por encima del depósito inicial para pruebas)
    final double currentBrokerAmount = allocation.initialDeposit * 1.06;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(allocation.brokerSlug),
          actions: [
            IconButton(
              tooltip: l10n.editAccount,
              icon: const Icon(LucideIcons.settings),
              onPressed: () => context.push('/account/$allocationId/edit'),
            ),
          ],
        ),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 600;
              final targetWidth = isDesktop
                  ? constraints.maxWidth * 0.8
                  : double.infinity;
              return Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: targetWidth),
                  child: Column(
                    children: [
                      // 1. Gráfico superior + Selector de período
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: GlassCard(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Desempeño vs Plan',
                                    style: TextStyle(
                                      color: glassTheme.textPrimary,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (state.drillDownDate != null)
                                    TextButton.icon(
                                      onPressed: controller.clearDrillDown,
                                      icon: const Icon(LucideIcons.x, size: 14),
                                      label: const Text('Volver'),
                                      style: TextButton.styleFrom(
                                        foregroundColor: Colors.amberAccent,
                                        padding: EdgeInsets.zero,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              PlanChart(
                                data: projections,
                                currentBrokerAmount: currentBrokerAmount,
                                currency: allocation.currency,
                                onTapPoint: (index) {
                                  if (index >= 0 &&
                                      index < projections.length) {
                                    final targetDate = projections[index].date;
                                    controller.handleDrillDown(targetDate);
                                  }
                                },
                              ),
                              const SizedBox(height: 12),
                              // Selector de período con diseño Glass
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: CompoundInterestGrouping.values.map((
                                  group,
                                ) {
                                  final isSelected = state.grouping == group;
                                  return MouseRegion(
                                    cursor: SystemMouseCursors.click,
                                    child: InkWell(
                                      onTap: () =>
                                          controller.setGrouping(group),
                                      borderRadius: BorderRadius.circular(12),
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 150,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? theme.colorScheme.primary
                                                    .withValues(alpha: 0.12)
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                      .withValues(alpha: 0.3)
                                                : Colors.transparent,
                                          ),
                                        ),
                                        child: Text(
                                          group.displayName,
                                          style: TextStyle(
                                            color: isSelected
                                                ? theme.colorScheme.primary
                                                : glassTheme.textSecondary,
                                            fontWeight: isSelected
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // 2. Tabs: Registros / Plan
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            _tabButton(
                              label: 'Registros',
                              isSelected: state.activeTab == 0,
                              onTap: () => controller.setTab(0),
                              glassTheme: glassTheme,
                            ),
                            const SizedBox(width: 8),
                            _tabButton(
                              label: 'Plan',
                              isSelected: state.activeTab == 1,
                              onTap: () => controller.setTab(1),
                              glassTheme: glassTheme,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // 3. Contenido de los Tabs
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: state.activeTab == 0
                              ? _buildRegistrosTab(glassTheme)
                              : _buildPlanTab(
                                  projections,
                                  allocation.currency,
                                  glassTheme,
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _tabButton({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required GlassThemeExtension glassTheme,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected
                ? glassTheme.textPrimary.withValues(alpha: 0.12)
                : glassTheme.textPrimary.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? glassTheme.glassBorder : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? glassTheme.textPrimary
                  : glassTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRegistrosTab(GlassThemeExtension glassTheme) {
    return GlassCard(
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.folderClosed,
                color: glassTheme.textSecondary.withValues(alpha: 0.4),
                size: 40,
              ),
              const SizedBox(height: 8),
              Text(
                'Próximamente',
                style: TextStyle(
                  color: glassTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Aquí se listarán las órdenes y transacciones históricas de la cuenta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: glassTheme.textSecondary.withValues(alpha: 0.7),
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlanTab(
    List<CompoundInterestPeriodResult> projections,
    String currency,
    GlassThemeExtension glassTheme,
  ) {
    if (projections.isEmpty) {
      return GlassCard(
        child: Center(
          child: Text(
            'Sin datos para el período seleccionado',
            style: TextStyle(color: glassTheme.textSecondary),
          ),
        ),
      );
    }

    return GlassCard(
      padding: EdgeInsets.zero,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            // Cabecera de la tabla
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: glassTheme.textPrimary.withValues(alpha: 0.05),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Período',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Saldo Inicial',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Rendimiento',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Saldo Final',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: glassTheme.glassBorder),
            // Cuerpo de la tabla
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: projections.length,
                separatorBuilder: (context, index) => Divider(
                  height: 1,
                  color: glassTheme.glassBorder.withValues(alpha: 0.5),
                ),
                itemBuilder: (context, index) {
                  final p = projections[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Text(
                            p.label,
                            style: TextStyle(
                              color: glassTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            formatMoney(p.startBalance, currency),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: glassTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            '+${formatMoney(p.yieldAmount, currency)}',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: glassTheme.positive,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            formatMoney(p.endBalance, currency),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              color: glassTheme.textPrimary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
