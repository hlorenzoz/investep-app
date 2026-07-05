import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_theme.dart';
import '../../../shared/format/money.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../domain/operation.dart';
import 'operations_controller.dart';

/// Pantalla de detalle de una operación (trade) con sus estadísticas completas.
///
/// Muestra los datos de compra y, si la operación está cerrada, las estadísticas
/// de venta: precio de venta, total de venta, ganancia/pérdida y su porcentaje.
class OperationDetailScreen extends ConsumerWidget {
  const OperationDetailScreen({
    super.key,
    required this.allocationId,
    required this.operationId,
  });

  final String allocationId;
  final String operationId;

  Allocation? _findAllocation(WidgetRef ref) {
    final overview = ref.watch(capitalControllerProvider).value;
    if (overview == null) return null;
    for (final a in overview.allocations) {
      if (a.id == allocationId) return a;
    }
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final allocation = _findAllocation(ref);
    final operationsAsync = ref.watch(operationsControllerProvider(allocationId));

    Operation? op;
    for (final o in operationsAsync.value ?? const <Operation>[]) {
      if (o.id == operationId) {
        op = o;
        break;
      }
    }

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Detalle del Trade'),
          actions: [
            if (op != null)
              IconButton(
                icon: Icon(LucideIcons.pencil, color: glassTheme.textSecondary),
                tooltip: 'Editar',
                onPressed: () => context.push(
                  '/account/$allocationId/operations/$operationId/edit',
                ),
              ),
          ],
        ),
        body: SafeArea(
          child: _buildBody(context, allocation, op, glassTheme),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Allocation? allocation,
    Operation? op,
    GlassThemeExtension glassTheme,
  ) {
    if (allocation == null || op == null) {
      return Center(
        child: Text(
          'Operación no encontrada',
          style: TextStyle(color: glassTheme.textSecondary),
        ),
      );
    }

    final theme = Theme.of(context);
    final currency = allocation.currency;
    final isOption = op.accountType == AccountType.options;

    return Center(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isDesktop = constraints.maxWidth >= 600;
          final targetWidth =
              isDesktop ? constraints.maxWidth * 0.8 : double.infinity;

          return ConstrainedBox(
            constraints: BoxConstraints(maxWidth: targetWidth),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(op, isOption, glassTheme, theme),
                      const SizedBox(height: 20),

                      // Datos de compra
                      _sectionTitle('Compra', glassTheme),
                      const SizedBox(height: 8),
                      _statRow('Fecha de compra', _formatDate(op.openedAt),
                          glassTheme),
                      _statRow('Cantidad', _formatQty(op.quantity), glassTheme),
                      _statRow(
                        isOption ? 'Prima' : 'Precio de compra',
                        formatMoney(op.buyPrice, currency),
                        glassTheme,
                      ),
                      if (isOption) ...[
                        _statRow('Strike',
                            op.strike != null ? formatMoney(op.strike!, currency) : '—',
                            glassTheme),
                        _statRow(
                            'Vencimiento', op.expirationDate ?? '—', glassTheme),
                        if (op.contractType != null)
                          _statRow('Tipo de contrato',
                              op.contractType!.toUpperCase(), glassTheme),
                      ],
                      if (op.limitPrice != null)
                        _statRow('Precio límite',
                            formatMoney(op.limitPrice!, currency), glassTheme),
                      _statRow(
                        'Total invertido',
                        formatMoney(op.totalInvested, currency),
                        glassTheme,
                        emphasize: true,
                      ),
                    ],
                  ),
                ),

                // Sección de venta (solo si está cerrada)
                if (op.isClosed) ...[
                  const SizedBox(height: 16),
                  _buildSaleCard(op, currency, glassTheme),
                ],

                // Estrategia y notas
                if ((op.strategy != null && op.strategy!.isNotEmpty) ||
                    (op.notes != null && op.notes!.isNotEmpty)) ...[
                  const SizedBox(height: 16),
                  GlassCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Notas', glassTheme),
                        const SizedBox(height: 8),
                        if (op.strategy != null && op.strategy!.isNotEmpty)
                          _statRow('Estrategia', op.strategy!, glassTheme),
                        if (op.notes != null && op.notes!.isNotEmpty)
                          _statRow('Notas', op.notes!, glassTheme),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(
    Operation op,
    bool isOption,
    GlassThemeExtension glassTheme,
    ThemeData theme,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: glassTheme.textPrimary.withValues(alpha: 0.05),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isOption ? LucideIcons.layers : LucideIcons.activity,
            color: theme.colorScheme.primary,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                op.ticker,
                style: TextStyle(
                  color: glassTheme.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 4),
              _statusBadge(op, glassTheme),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusBadge(Operation op, GlassThemeExtension glassTheme) {
    final color = op.isOpen ? glassTheme.positive : glassTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        op.isOpen ? 'Abierta' : 'Cerrada',
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildSaleCard(
    Operation op,
    String currency,
    GlassThemeExtension glassTheme,
  ) {
    final hasGain = op.gainAmount != null;
    final isPositive = (op.gainAmount ?? 0) >= 0;
    final gainColor = isPositive ? glassTheme.positive : glassTheme.negative;
    final sign = isPositive ? '+' : '';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('Venta', glassTheme),
          const SizedBox(height: 8),
          if (op.soldAt != null)
            _statRow('Fecha de venta', _formatDate(op.soldAt!), glassTheme),
          if (op.sellPrice != null)
            _statRow('Precio de venta',
                formatMoney(op.sellPrice!, currency), glassTheme),
          _statRow(
            'Total de venta',
            formatMoney(op.totalSale ?? 0, currency),
            glassTheme,
            emphasize: true,
          ),
          if (hasGain) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: gainColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: gainColor.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isPositive
                            ? LucideIcons.trendingUp
                            : LucideIcons.trendingDown,
                        color: gainColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isPositive ? 'Ganancia' : 'Pérdida',
                        style: TextStyle(
                          color: gainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$sign${formatMoney(op.gainAmount!, currency)}',
                        style: TextStyle(
                          color: gainColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (op.gainPct != null)
                        Text(
                          '$sign${op.gainPct!.toStringAsFixed(2)}%',
                          style: TextStyle(
                            color: gainColor,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, GlassThemeExtension glassTheme) {
    return Text(
      title,
      style: TextStyle(
        color: glassTheme.textPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 15,
      ),
    );
  }

  Widget _statRow(
    String label,
    String value,
    GlassThemeExtension glassTheme, {
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: glassTheme.textPrimary,
              fontSize: 13,
              fontWeight: emphasize ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  String _formatQty(double qty) {
    return qty == qty.roundToDouble()
        ? qty.toInt().toString()
        : qty.toString();
  }
}
