import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/format/money.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../operations/domain/operation.dart';
import '../../operations/presentation/operations_controller.dart';
import '../../operations/presentation/register_sale_dialog.dart';
import '../../../core/network/api_exception.dart';
import '../../plans/domain/compound_interest_calculator.dart';
import '../../plans/presentation/widgets/plan_chart_painter.dart';
import 'account_detail_controller.dart';
import 'package:url_launcher/url_launcher.dart';

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
    final projectionAsync = ref.watch(accountProjectionProvider(allocationId));

    // Simulamos el balance actual en el broker (un 6% por encima del depósito inicial para pruebas)
    final double currentBrokerAmount = allocation.initialDeposit * 1.06;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(allocation.brokerSlug),
          actions: buildAppBarActions(
            context,
            extraActions: [
              IconButton(
                tooltip: l10n.editAccount,
                icon: const Icon(LucideIcons.settings),
                onPressed: () => context.push('/account/$allocationId/edit'),
              ),
            ],
          ),
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
                              projectionAsync.when(
                                loading: () => const SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                ),
                                error: (err, stack) => SizedBox(
                                  height: 220,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          LucideIcons.alertTriangle,
                                          color: glassTheme.negative,
                                          size: 36,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          err is ApiException
                                              ? err.message
                                              : 'Error al cargar proyección',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: glassTheme.textPrimary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                data: (projections) => PlanChart(
                                  data: projections,
                                  currentBrokerAmount: currentBrokerAmount,
                                  currency: allocation.currency,
                                  onTapPoint: (index) {
                                    if (index >= 0 &&
                                        index < projections.length) {
                                      final targetDate =
                                          projections[index].date;
                                      controller.handleDrillDown(targetDate);
                                    }
                                  },
                                ),
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
                              ? _buildRegistrosTab(
                                  context,
                                  ref,
                                  allocation,
                                  glassTheme,
                                )
                              : projectionAsync.when(
                                  loading: () => const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                  error: (err, stack) => Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            LucideIcons.alertCircle,
                                            color: glassTheme.negative,
                                            size: 36,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            err is ApiException
                                                ? err.message
                                                : 'Error al cargar plan',
                                            style: TextStyle(
                                              color: glassTheme.textPrimary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(height: 12),
                                          OutlinedButton(
                                            onPressed: () => ref.invalidate(
                                              accountProjectionProvider(
                                                allocationId,
                                              ),
                                            ),
                                            child: const Text('Reintentar'),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  data: (projections) => _buildPlanTab(
                                    projections,
                                    allocation.currency,
                                    glassTheme,
                                  ),
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

  Widget _buildRegistrosTab(
    BuildContext context,
    WidgetRef ref,
    Allocation allocation,
    GlassThemeExtension glassTheme,
  ) {
    final operationsAsync = ref.watch(
      operationsControllerProvider(allocation.id),
    );

    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          // Header / Action Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Registro de Trades',
                  style: TextStyle(
                    color: glassTheme.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () =>
                      context.push('/account/${allocation.id}/operations/new'),
                  icon: const Icon(LucideIcons.plus, size: 14),
                  label: const Text(
                    'Nuevo Trade',
                    style: TextStyle(fontSize: 12),
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: glassTheme.glassBorder),
          // Content
          Expanded(
            child: operationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        color: glassTheme.negative,
                        size: 36,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Error al cargar operaciones',
                        style: TextStyle(
                          color: glassTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        err.toString(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: glassTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref
                            .read(
                              operationsControllerProvider(
                                allocation.id,
                              ).notifier,
                            )
                            .refresh(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (operations) {
                if (operations.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.folderOpen,
                              color: glassTheme.textSecondary.withValues(
                                alpha: 0.3,
                              ),
                              size: 40,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Sin operaciones registradas',
                              style: TextStyle(
                                color: glassTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Aún no registraste ninguna operación de trading en esta cuenta.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: glassTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  itemCount: operations.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    color: glassTheme.glassBorder.withValues(alpha: 0.5),
                  ),
                  itemBuilder: (context, index) {
                    final op = operations[index];
                    return _buildOperationTile(
                      context,
                      ref,
                      allocation,
                      op,
                      glassTheme,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOperationTile(
    BuildContext context,
    WidgetRef ref,
    Allocation allocation,
    Operation op,
    GlassThemeExtension glassTheme,
  ) {
    final theme = Theme.of(context);
    final isOption = op.accountType == AccountType.options;

    // Formatear ganancia si está cerrada
    Widget? gainWidget;
    if (op.isClosed && op.gainAmount != null && op.gainPct != null) {
      final isPositive = op.gainAmount! >= 0;
      final gainColor = isPositive ? glassTheme.positive : glassTheme.negative;
      final sign = isPositive ? '+' : '';
      gainWidget = Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: gainColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          '$sign${formatMoney(op.gainAmount!, allocation.currency)} (${op.gainPct!.toStringAsFixed(2)}%)',
          style: TextStyle(
            color: gainColor,
            fontSize: 11,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return InkWell(
      onTap: () =>
          context.push('/account/${allocation.id}/operations/${op.id}'),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono según tipo (Equity vs Option) e indicador de Gain si está cerrado
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: glassTheme.textPrimary.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isOption ? LucideIcons.layers : LucideIcons.activity,
                color: theme.colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            // Detalles de la operación
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        op.ticker,
                        style: TextStyle(
                          color: glassTheme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge del tipo si es opción
                      if (isOption && op.contractType != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color:
                                (op.contractType == 'call'
                                        ? Colors.blue
                                        : Colors.purple)
                                    .withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color:
                                  (op.contractType == 'call'
                                          ? Colors.blue
                                          : Colors.purple)
                                      .withValues(alpha: 0.4),
                            ),
                          ),
                          child: Text(
                            op.contractType!.toUpperCase(),
                            style: TextStyle(
                              color: op.contractType == 'call'
                                  ? Colors.blue
                                  : Colors.purple,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      const SizedBox(width: 8),
                      // Badge de estado (Abierto/Cerrado)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (op.isOpen
                                      ? glassTheme.positive
                                      : glassTheme.textSecondary)
                                  .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          op.isOpen ? 'Abierta' : 'Cerrada',
                          style: TextStyle(
                            color: op.isOpen
                                ? glassTheme.positive
                                : glassTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Detalles de la compra/contrato
                  Text(
                    isOption
                        ? 'Strike: ${op.strike} | Exp: ${op.expirationDate} | Qty: ${op.quantity.toInt()}'
                        : 'Qty: ${op.quantity} @ ${formatMoney(op.buyPrice, allocation.currency)}',
                    style: TextStyle(
                      color: glassTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  if (isOption)
                    Text(
                      'Prima: ${formatMoney(op.buyPrice, allocation.currency)} | Total: ${formatMoney(op.totalInvested, allocation.currency)}',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontSize: 11,
                      ),
                    )
                  else
                    Text(
                      'Total Invertido: ${formatMoney(op.totalInvested, allocation.currency)}',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),

                  if (op.strategy != null && op.strategy!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Estrategia: ${op.strategy}',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],

                  // Detalles del cierre (si aplica)
                  if (op.isClosed) ...[
                    const SizedBox(height: 6),
                    Divider(
                      height: 1,
                      color: glassTheme.glassBorder.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Venta: ${_formatDate(op.soldAt!)} @ ${formatMoney(op.sellPrice ?? 0, allocation.currency)}',
                      style: TextStyle(
                        color: glassTheme.textPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Total Venta: ${formatMoney(op.totalSale ?? 0, allocation.currency)}',
                      style: TextStyle(
                        color: glassTheme.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Lado derecho: Ganancia + Menú de acciones
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (gainWidget != null) ...[
                  gainWidget,
                  const SizedBox(height: 8),
                ],
                PopupMenuButton<String>(
                  icon: Icon(
                    LucideIcons.moreVertical,
                    color: glassTheme.textSecondary,
                    size: 18,
                  ),
                  color: theme.scaffoldBackgroundColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) =>
                      _handleAction(context, ref, value, allocation, op),
                  itemBuilder: (context) => [
                    if (op.isOpen)
                      const PopupMenuItem(
                        value: 'sell',
                        child: Row(
                          children: [
                            Icon(LucideIcons.banknote, size: 16),
                            SizedBox(width: 8),
                            Text('Registrar Venta'),
                          ],
                        ),
                      )
                    else
                      const PopupMenuItem(
                        value: 'reopen',
                        child: Row(
                          children: [
                            Icon(LucideIcons.rotateCcw, size: 16),
                            SizedBox(width: 8),
                            Text('Reabrir Operación'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(LucideIcons.pencil, size: 16),
                          SizedBox(width: 8),
                          Text('Editar'),
                        ],
                      ),
                    ),
                    if (op.url != null && op.url!.isNotEmpty)
                      const PopupMenuItem(
                        value: 'url',
                        child: Row(
                          children: [
                            Icon(LucideIcons.externalLink, size: 16),
                            SizedBox(width: 8),
                            Text('Ver Referencia'),
                          ],
                        ),
                      ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.trash2,
                            size: 16,
                            color: glassTheme.negative,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Eliminar',
                            style: TextStyle(color: glassTheme.negative),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    Allocation allocation,
    Operation op,
  ) {
    if (action == 'edit') {
      context.push('/account/${allocation.id}/operations/${op.id}/edit');
    } else if (action == 'delete') {
      _showDeleteDialogForOperation(context, ref, allocation.id, op.id);
    } else if (action == 'reopen') {
      ref
          .read(operationsControllerProvider(allocation.id).notifier)
          .reopenOperation(op.id);
    } else if (action == 'sell') {
      _showRegisterSaleDialog(context, ref, allocation.id, op.id);
    } else if (action == 'url') {
      final uri = Uri.tryParse(op.url ?? '');
      if (uri != null) {
        launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  void _showDeleteDialogForOperation(
    BuildContext context,
    WidgetRef ref,
    String allocationId,
    String operationId,
  ) {
    final glassTheme = context.glass;
    final l10n = AppLocalizations.of(context);

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
                '¿Eliminar operación?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: glassTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '¿Estás seguro de que querés eliminar esta operación permanentemente?',
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
                        ref
                            .read(
                              operationsControllerProvider(
                                allocationId,
                              ).notifier,
                            )
                            .delete(operationId);
                      },
                      child: const Text('Eliminar'),
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

  void _showRegisterSaleDialog(
    BuildContext context,
    WidgetRef ref,
    String allocationId,
    String operationId,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => RegisterSaleDialog(
        onConfirm: (soldAt, sellPrice) {
          ref
              .read(operationsControllerProvider(allocationId).notifier)
              .registerSale(operationId, soldAt: soldAt, sellPrice: sellPrice);
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
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
