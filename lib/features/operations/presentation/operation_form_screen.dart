import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'dart:ui';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/auth/auth_gate.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../tickers/data/ticker_repository.dart';
import '../../tickers/domain/ticker.dart';
import 'operation_form_controller.dart';
import 'operations_controller.dart';

class OperationFormScreen extends ConsumerStatefulWidget {
  const OperationFormScreen({
    super.key,
    required this.allocationId,
    this.operationId,
  });

  final String allocationId;
  final String? operationId;

  @override
  ConsumerState<OperationFormScreen> createState() =>
      _OperationFormScreenState();
}

class _OperationFormScreenState extends ConsumerState<OperationFormScreen> {
  late final OperationFormParam _param;

  final _formKey = GlobalKey<FormState>();
  final _tickerController = TextEditingController();
  final _tickerFocusNode = FocusNode();
  final _qtyController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _limitPriceController = TextEditingController();
  final _strikeController = TextEditingController();
  final _expDateController = TextEditingController();
  final _strategyController = TextEditingController();
  final _notesController = TextEditingController();
  final _urlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _param = OperationFormParam(
      allocationId: widget.allocationId,
      operationId: widget.operationId,
    );
  }

  @override
  void dispose() {
    _tickerController.dispose();
    _tickerFocusNode.dispose();
    _qtyController.dispose();
    _buyPriceController.dispose();
    _limitPriceController.dispose();
    _strikeController.dispose();
    _expDateController.dispose();
    _strategyController.dispose();
    _notesController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDate(
    BuildContext context,
    DateTime initialDate,
    ValueChanged<DateTime> onDateSelected,
  ) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null && mounted) {
      onDateSelected(picked);
    }
  }

  Allocation? _getAllocation() {
    final overview = ref.read(capitalControllerProvider).value;
    if (overview == null) return null;
    for (final a in overview.allocations) {
      if (a.id == widget.allocationId) return a;
    }
    return null;
  }

  void _suggestYahooUrl() {
    final ticker = _tickerController.text.trim();
    if (ticker.isEmpty) return;

    final allocation = _getAllocation();
    if (allocation == null) return;

    final url = allocation.accountType == AccountType.options
        ? 'https://finance.yahoo.com/quote/${ticker.toUpperCase()}/options'
        : 'https://finance.yahoo.com/quote/${ticker.toUpperCase()}';

    _urlController.text = url;
    ref.read(operationFormControllerProvider(_param).notifier).setUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final theme = Theme.of(context);
    final state = ref.watch(operationFormControllerProvider(_param));
    final notifier = ref.read(operationFormControllerProvider(_param).notifier);

    final allocation = _getAllocation();

    final gateState = ref.watch(authGateProvider);
    final String? planSlug;
    if (gateState is GateAuthenticated) {
      final role = gateState.user.role.toLowerCase();
      if (const ['bronze', 'silver', 'gold', 'platinum'].contains(role)) {
        planSlug = role;
      } else if (role == 'admin') {
        planSlug = null;
      } else {
        planSlug = 'bronze';
      }
    } else {
      planSlug = 'bronze';
    }

    // Escuchamos el éxito para navegar hacia atrás y el cambio de carga para sembrar
    ref.listen<OperationFormState>(operationFormControllerProvider(_param), (
      prev,
      next,
    ) {
      if (next.isSuccess && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.operationSaved),
            backgroundColor: glassTheme.positive.withValues(alpha: 0.8),
          ),
        );
        context.pop();
      }

      if (prev != null && prev.isLoading && !next.isLoading) {
        _tickerController.text = next.ticker;
        _qtyController.text = next.quantity;
        _buyPriceController.text = next.buyPrice;
        _limitPriceController.text = next.limitPrice;
        _strikeController.text = next.strike;
        _expDateController.text = next.expirationDate;
        _strategyController.text = next.strategy;
        _notesController.text = next.notes;
        _urlController.text = next.url;
      }
    });

    if (allocation == null) {
      return Container(
        decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(title: Text(l10n.accountNotFound)),
          body: Center(
            child: Text(
              l10n.accountNotFound,
              style: TextStyle(color: glassTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final isOptions = allocation.accountType == AccountType.options;

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.operationId != null
                ? l10n.operationEditTitle
                : l10n.operationNewTitle,
          ),
          actions: buildAppBarActions(
            context,
            extraActions: [
              if (widget.operationId != null)
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    color: AppColors.negative,
                  ),
                  tooltip: l10n.operationDelete,
                  onPressed: () => _confirmDelete(context),
                ),
            ],
          ),
        ),
        body: SafeArea(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth >= 600;
                final targetWidth = isDesktop
                    ? constraints.maxWidth * 0.8
                    : double.infinity;

                if (state.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: targetWidth),
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.all(16.0),
                      children: [
                        GlassCard(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                '${l10n.summaryBroker}: ${allocation.brokerSlug} (${isOptions ? l10n.accountTypeOptions : l10n.accountTypeEquity})',
                                style: TextStyle(
                                  color: glassTheme.textSecondary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Ticker / Símbolo con Autocomplete según plan del usuario
                              Autocomplete<Ticker>(
                                textEditingController: _tickerController,
                                focusNode: _tickerFocusNode,
                                displayStringForOption: (Ticker option) =>
                                    option.symbol,
                                optionsBuilder:
                                    (TextEditingValue textEditingValue) async {
                                      if (textEditingValue.text
                                          .trim()
                                          .isEmpty) {
                                        return const Iterable<Ticker>.empty();
                                      }
                                      try {
                                        final results = await ref
                                            .read(tickerRepositoryProvider)
                                            .getTickers(
                                              q: textEditingValue.text.trim(),
                                              planSlug: planSlug,
                                              limit: 10,
                                            );
                                        return results.tickers;
                                      } catch (_) {
                                        return const Iterable<Ticker>.empty();
                                      }
                                    },
                                onSelected: (Ticker selection) {
                                  _tickerController.text = selection.symbol;
                                  notifier.setTicker(selection.symbol);
                                  _suggestYahooUrl();
                                },
                                fieldViewBuilder:
                                    (
                                      context,
                                      textEditingController,
                                      focusNode,
                                      onFieldSubmitted,
                                    ) {
                                      return TextFormField(
                                        controller: textEditingController,
                                        focusNode: focusNode,
                                        style: TextStyle(
                                          color: glassTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText: l10n.operationTicker,
                                          labelStyle: TextStyle(
                                            color: glassTheme.textSecondary,
                                          ),
                                          prefixIcon: Icon(
                                            LucideIcons.activity,
                                            color: glassTheme.textSecondary,
                                          ),
                                          errorText: state.tickerError,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: glassTheme.glassBorder,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        onChanged: (val) {
                                          notifier.setTicker(val);
                                          _suggestYahooUrl();
                                        },
                                        onFieldSubmitted: (val) {
                                          onFieldSubmitted();
                                        },
                                      );
                                    },
                                optionsViewBuilder: (context, onSelected, options) {
                                  final glassTheme = context.glass;
                                  final theme = Theme.of(context);
                                  return Align(
                                    alignment: Alignment.topLeft,
                                    child: Material(
                                      color: Colors.transparent,
                                      elevation: 4.0,
                                      child: Container(
                                        width: 320,
                                        constraints: const BoxConstraints(
                                          maxHeight: 250,
                                        ),
                                        margin: const EdgeInsets.only(top: 4.0),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.surface
                                              .withValues(alpha: 0.95),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: glassTheme.glassBorder,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          child: BackdropFilter(
                                            filter: ImageFilter.blur(
                                              sigmaX: 10,
                                              sigmaY: 10,
                                            ),
                                            child: ListView.separated(
                                              padding: EdgeInsets.zero,
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              separatorBuilder:
                                                  (context, index) => Divider(
                                                    height: 1,
                                                    color:
                                                        glassTheme.glassBorder,
                                                  ),
                                              itemBuilder:
                                                  (
                                                    BuildContext context,
                                                    int index,
                                                  ) {
                                                    final Ticker option =
                                                        options.elementAt(
                                                          index,
                                                        );
                                                    return InkWell(
                                                      onTap: () =>
                                                          onSelected(option),
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 12,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              option.symbol,
                                                              style: TextStyle(
                                                                color: glassTheme
                                                                    .textPrimary,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                fontSize: 15,
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                              height: 2,
                                                            ),
                                                            Text(
                                                              option.name,
                                                              maxLines: 1,
                                                              overflow:
                                                                  TextOverflow
                                                                      .ellipsis,
                                                              style: TextStyle(
                                                                color: glassTheme
                                                                    .textSecondary,
                                                                fontSize: 12,
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
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              // Fecha de Compra (openedAt)
                              InkWell(
                                onTap: () => _selectDate(
                                  context,
                                  state.openedAt,
                                  (date) => notifier.setOpenedAt(date),
                                ),
                                borderRadius: BorderRadius.circular(12),
                                child: InputDecorator(
                                  decoration: InputDecoration(
                                    labelText: l10n.operationOpenedAt,
                                    labelStyle: TextStyle(
                                      color: glassTheme.textSecondary,
                                    ),
                                    prefixIcon: Icon(
                                      LucideIcons.calendar,
                                      color: glassTheme.textSecondary,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide(
                                        color: glassTheme.glassBorder,
                                      ),
                                    ),
                                  ),
                                  child: Text(
                                    _formatDate(state.openedAt),
                                    style: TextStyle(
                                      color: glassTheme.textPrimary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Fila de Cantidad y Precio de Compra
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _qtyController,
                                      style: TextStyle(
                                        color: glassTheme.textPrimary,
                                      ),
                                      keyboardType:
                                          TextInputType.numberWithOptions(
                                            decimal: !isOptions,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: l10n.operationQty,
                                        labelStyle: TextStyle(
                                          color: glassTheme.textSecondary,
                                        ),
                                        errorText: state.quantityError,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: glassTheme.glassBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      onChanged: notifier.setQuantity,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _buyPriceController,
                                      style: TextStyle(
                                        color: glassTheme.textPrimary,
                                      ),
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: InputDecoration(
                                        labelText: l10n.operationBuyPrice,
                                        labelStyle: TextStyle(
                                          color: glassTheme.textSecondary,
                                        ),
                                        errorText: state.buyPriceError,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: glassTheme.glassBorder,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          borderSide: BorderSide(
                                            color: theme.colorScheme.primary,
                                          ),
                                        ),
                                      ),
                                      onChanged: notifier.setBuyPrice,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              // Precio Límite (Opcional)
                              TextFormField(
                                controller: _limitPriceController,
                                style: TextStyle(color: glassTheme.textPrimary),
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                decoration: InputDecoration(
                                  labelText: l10n.operationLimitPrice,
                                  labelStyle: TextStyle(
                                    color: glassTheme.textSecondary,
                                  ),
                                  prefixIcon: Icon(
                                    LucideIcons.target,
                                    color: glassTheme.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: glassTheme.glassBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onChanged: notifier.setLimitPrice,
                              ),

                              // Campos Exclusivos de Opciones
                              if (isOptions) ...[
                                const SizedBox(height: 24),
                                Divider(color: glassTheme.glassBorder),
                                const SizedBox(height: 12),
                                Text(
                                  'Datos del Contrato de Opción',
                                  style: TextStyle(
                                    color: glassTheme.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Tipo de Contrato (Call / Put)
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        l10n.operationContractType,
                                        style: TextStyle(
                                          color: glassTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    ToggleButtons(
                                      isSelected: [
                                        state.contractType == 'call',
                                        state.contractType == 'put',
                                      ],
                                      onPressed: (index) {
                                        notifier.setContractType(
                                          index == 0 ? 'call' : 'put',
                                        );
                                      },
                                      borderRadius: BorderRadius.circular(12),
                                      selectedBorderColor:
                                          theme.colorScheme.primary,
                                      selectedColor: Colors.white,
                                      fillColor: theme.colorScheme.primary
                                          .withValues(alpha: 0.2),
                                      color: glassTheme.textSecondary,
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text('CALL'),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text('PUT'),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Strike y Expiración
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _strikeController,
                                        style: TextStyle(
                                          color: glassTheme.textPrimary,
                                        ),
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                              decimal: true,
                                            ),
                                        decoration: InputDecoration(
                                          labelText: l10n.operationStrike,
                                          labelStyle: TextStyle(
                                            color: glassTheme.textSecondary,
                                          ),
                                          errorText: state.strikeError,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: glassTheme.glassBorder,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        onChanged: notifier.setStrike,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _expDateController,
                                        style: TextStyle(
                                          color: glassTheme.textPrimary,
                                        ),
                                        decoration: InputDecoration(
                                          labelText:
                                              l10n.operationExpirationDate,
                                          labelStyle: TextStyle(
                                            color: glassTheme.textSecondary,
                                          ),
                                          hintText: 'YYYY-MM-DD',
                                          errorText: state.expirationDateError,
                                          prefixIcon: IconButton(
                                            icon: const Icon(
                                              LucideIcons.calendar,
                                            ),
                                            onPressed: () {
                                              final initial =
                                                  DateTime.tryParse(
                                                    _expDateController.text,
                                                  ) ??
                                                  DateTime.now().add(
                                                    const Duration(days: 30),
                                                  );
                                              _selectDate(context, initial, (
                                                date,
                                              ) {
                                                final val = _formatDate(date);
                                                _expDateController.text = val;
                                                notifier.setExpirationDate(val);
                                              });
                                            },
                                          ),
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          enabledBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: glassTheme.glassBorder,
                                            ),
                                          ),
                                          focusedBorder: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            borderSide: BorderSide(
                                              color: theme.colorScheme.primary,
                                            ),
                                          ),
                                        ),
                                        onChanged: notifier.setExpirationDate,
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 24),
                              Divider(color: glassTheme.glassBorder),
                              const SizedBox(height: 12),
                              Text(
                                'Detalles del Trade (Opcionales)',
                                style: TextStyle(
                                  color: glassTheme.textPrimary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Estrategia
                              TextFormField(
                                controller: _strategyController,
                                style: TextStyle(color: glassTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: l10n.operationStrategy,
                                  labelStyle: TextStyle(
                                    color: glassTheme.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: glassTheme.glassBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onChanged: notifier.setStrategy,
                              ),
                              const SizedBox(height: 16),

                              // URL de referencia
                              TextFormField(
                                controller: _urlController,
                                style: TextStyle(color: glassTheme.textPrimary),
                                decoration: InputDecoration(
                                  labelText: l10n.operationUrl,
                                  labelStyle: TextStyle(
                                    color: glassTheme.textSecondary,
                                  ),
                                  suffixIcon: TextButton(
                                    onPressed: _suggestYahooUrl,
                                    child: Text(
                                      'Yahoo',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: glassTheme.glassBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onChanged: notifier.setUrl,
                              ),
                              const SizedBox(height: 16),

                              // Notas
                              TextFormField(
                                controller: _notesController,
                                style: TextStyle(color: glassTheme.textPrimary),
                                maxLines: 3,
                                decoration: InputDecoration(
                                  labelText: l10n.operationNotes,
                                  labelStyle: TextStyle(
                                    color: glassTheme.textSecondary,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: glassTheme.glassBorder,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                                onChanged: notifier.setNotes,
                              ),

                              if (state.errorMessage != null) ...[
                                const SizedBox(height: 16),
                                Text(
                                  state.errorMessage!,
                                  style: const TextStyle(
                                    color: AppColors.negative,
                                    fontSize: 13,
                                  ),
                                ),
                              ],

                              const SizedBox(height: 28),

                              ElevatedButton.icon(
                                onPressed: state.isSubmitting
                                    ? null
                                    : notifier.submit,
                                icon: state.isSubmitting
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Icon(LucideIcons.check, size: 18),
                                label: Text(l10n.operationSave),
                              ),
                            ],
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
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
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
                '¿Estás seguro de que querés eliminar este registro de operación permanentemente?',
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
                        final messenger = ScaffoldMessenger.of(context);
                        final snackBar = SnackBar(
                          content: Text(l10n.operationDeleted),
                          backgroundColor: glassTheme.positive.withValues(
                            alpha: 0.8,
                          ),
                        );
                        final router = GoRouter.of(context);

                        ref
                            .read(
                              operationsControllerProvider(
                                widget.allocationId,
                              ).notifier,
                            )
                            .delete(widget.operationId!)
                            .then((_) {
                              if (mounted) {
                                messenger.showSnackBar(snackBar);
                                router.pop();
                              }
                            });
                      },
                      child: Text(l10n.operationDelete),
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
}
