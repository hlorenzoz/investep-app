import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../core/network/api_exception.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../academy/presentation/providers/academy_providers.dart';
import '../../tickers/data/ticker_repository.dart';
import '../../tickers/domain/ticker.dart';
import '../../tickers/presentation/tickers_provider.dart';

/// Pantalla administrativa para la gestión de Activos (Tickers).
class AdminTickersScreen extends ConsumerWidget {
  const AdminTickersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final tickersAsync = ref.watch(tickersListProvider);
    final page = ref.watch(tickerPageProvider);
    final selectedAssetClass = ref.watch(tickerAssetClassFilterProvider);
    final selectedSector = ref.watch(tickerSectorFilterProvider);

    // Sectores comunes predefinidos para el filtro rápido
    final sectors = [
      'Technology',
      'Financial Services',
      'Consumer Cyclical',
      'Healthcare',
      'Industrials',
      'Energy',
      'Utilities',
      'Real Estate',
      'Basic Materials',
      'Communication Services',
    ];

    final listContent = Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(LucideIcons.candlestickChart, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Gestión de Activos',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Barra de búsqueda y Filtros Rápidos
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: GlassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(LucideIcons.search, size: 18),
                        hintText: 'Buscar por símbolo o nombre...',
                        hintStyle: TextStyle(
                          color: glassTheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                      ),
                      style: TextStyle(color: glassTheme.textPrimary),
                      onChanged: (val) {
                        ref.read(tickerPageProvider.notifier).setPage(1);
                        ref
                            .read(tickerSearchQueryProvider.notifier)
                            .search(val);
                      },
                    ),
                    const Divider(color: Colors.white10),
                    Row(
                      children: [
                        // Filtro Asset Class
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: selectedAssetClass,
                              hint: Text(
                                'Clase de Activo',
                                style: TextStyle(
                                  color: glassTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              dropdownColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              style: TextStyle(
                                color: glassTheme.textPrimary,
                                fontSize: 13,
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Todas las clases'),
                                ),
                                ...[
                                  'stock',
                                  'etf',
                                  'index',
                                  'crypto',
                                  'commodity',
                                  'currency',
                                ].map(
                                  (type) => DropdownMenuItem(
                                    value: type,
                                    child: Text(type.toUpperCase()),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                    .read(tickerPageProvider.notifier)
                                    .setPage(1);
                                ref
                                    .read(
                                      tickerAssetClassFilterProvider.notifier,
                                    )
                                    .setFilter(val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Filtro Sector
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              isExpanded: true,
                              value: selectedSector,
                              hint: Text(
                                'Sector',
                                style: TextStyle(
                                  color: glassTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              dropdownColor: Theme.of(
                                context,
                              ).colorScheme.surface,
                              style: TextStyle(
                                color: glassTheme.textPrimary,
                                fontSize: 13,
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('Todos los sectores'),
                                ),
                                ...sectors.map(
                                  (sector) => DropdownMenuItem(
                                    value: sector,
                                    child: Text(sector),
                                  ),
                                ),
                              ],
                              onChanged: (val) {
                                ref
                                    .read(tickerPageProvider.notifier)
                                    .setPage(1);
                                ref
                                    .read(tickerSectorFilterProvider.notifier)
                                    .setFilter(val);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Listado de Tickers
            Expanded(
              child: tickersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          LucideIcons.alertTriangle,
                          size: 48,
                          color: AppColors.negative,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error al cargar activos: $err',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: glassTheme.textPrimary),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => ref.invalidate(tickersListProvider),
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (paginated) {
                  final tickers = paginated.tickers;
                  if (tickers.isEmpty) {
                    return Center(
                      child: Text(
                        'No se encontraron activos.',
                        style: TextStyle(color: glassTheme.textSecondary),
                      ),
                    );
                  }

                  final totalPages = (paginated.total / paginated.limit).ceil();

                  return Column(
                    children: [
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: () async =>
                              ref.invalidate(tickersListProvider),
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            itemCount: tickers.length,
                            itemBuilder: (context, index) {
                              final ticker = tickers[index];
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TickerCard(ticker: ticker),
                              );
                            },
                          ),
                        ),
                      ),
                      // Controles de Paginación
                      if (totalPages > 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 20,
                          ),
                          child: GlassCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  icon: const Icon(LucideIcons.chevronLeft),
                                  onPressed: page > 1
                                      ? () => ref
                                            .read(tickerPageProvider.notifier)
                                            .decrement()
                                      : null,
                                ),
                                Text(
                                  'Página $page de $totalPages (Total: ${paginated.total})',
                                  style: TextStyle(
                                    color: glassTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.chevronRight),
                                  onPressed: page < totalPages
                                      ? () => ref
                                            .read(tickerPageProvider.notifier)
                                            .increment()
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showTickerForm(context, ref),
        child: const Icon(LucideIcons.plus),
      ),
    );

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isLarge = constraints.maxWidth >= 600;
          if (isLarge) {
            return Center(
              child: SizedBox(
                width: constraints.maxWidth * 0.8,
                child: listContent,
              ),
            );
          }
          return listContent;
        },
      ),
    );
  }

  void _showTickerForm(BuildContext context, WidgetRef ref, {Ticker? ticker}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => _TickerFormDialog(ticker: ticker),
    ).then((_) {
      ref.invalidate(tickersListProvider);
    });
  }
}

class _TickerCard extends ConsumerWidget {
  const _TickerCard({required this.ticker});

  final Ticker ticker;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final change = ticker.changePct ?? 0.0;
    final isPositive = change >= 0;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      ticker.symbol,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: glassTheme.textPrimary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        ticker.assetClass.toUpperCase(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  ticker.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    color: glassTheme.textSecondary,
                  ),
                ),
                if (ticker.sector != null || ticker.exchange != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${ticker.exchange ?? ""} · ${ticker.sector ?? ""}',
                    style: TextStyle(
                      fontSize: 11,
                      color: glassTheme.textSecondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Precio e indicadores financieros rápidos
          if (ticker.price != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '\$${ticker.price!.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${isPositive ? "+" : ""}${change.toStringAsFixed(2)}%',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? AppColors.positive : AppColors.negative,
                  ),
                ),
              ],
            ),
          const SizedBox(width: 16),
          IconButton(
            icon: Icon(
              LucideIcons.edit3,
              color: glassTheme.textSecondary,
              size: 20,
            ),
            onPressed: () {
              showDialog<void>(
                context: context,
                barrierDismissible: false,
                builder: (context) => _TickerFormDialog(ticker: ticker),
              ).then((_) {
                ref.invalidate(tickersListProvider);
              });
            },
            tooltip: 'Editar Activo',
          ),
          IconButton(
            icon: const Icon(
              LucideIcons.trash2,
              color: AppColors.negative,
              size: 20,
            ),
            onPressed: () => _confirmDelete(context, ref),
            tooltip: 'Eliminar Activo',
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.glass.glassFill,
        title: Text(
          'Eliminar Activo',
          style: TextStyle(color: context.glass.textPrimary),
        ),
        content: Text(
          '¿Estás seguro de que querés eliminar a ${ticker.symbol} (${ticker.name})? '
          'Esta acción es destructiva e irreversible.',
          style: TextStyle(color: context.glass.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancelar',
              style: TextStyle(color: context.glass.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref
                    .read(adminTickersProvider.notifier)
                    .deleteTicker(ticker.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activo eliminado con éxito.'),
                      backgroundColor: AppColors.positive,
                    ),
                  );
                }
              } on ApiException catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error al eliminar: ${e.message}'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Ocurrió un error inesperado: $e'),
                      backgroundColor: AppColors.negative,
                    ),
                  );
                }
              }
            },
            child: const Text(
              'Eliminar',
              style: TextStyle(color: AppColors.negative),
            ),
          ),
        ],
      ),
    );
  }
}

class _TickerFormDialog extends ConsumerStatefulWidget {
  const _TickerFormDialog({this.ticker});

  final Ticker? ticker;

  @override
  ConsumerState<_TickerFormDialog> createState() => _TickerFormDialogState();
}

class _TickerFormDialogState extends ConsumerState<_TickerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _symbolController = TextEditingController();
  final _nameController = TextEditingController();
  final _exchangeController = TextEditingController();
  final _sectorController = TextEditingController();
  final _industryController = TextEditingController();
  final _countryController = TextEditingController();

  // Campos financieros
  final _priceController = TextEditingController();
  final _changePctController = TextEditingController();
  final _prevCloseController = TextEditingController();
  final _volumeController = TextEditingController();
  final _avgVolumeController = TextEditingController();
  final _fiftyTwoWHighController = TextEditingController();
  final _fiftyTwoWLowController = TextEditingController();
  final _marketCapController = TextEditingController();
  final _peRatioController = TextEditingController();
  final _forwardPeController = TextEditingController();
  final _pegRatioController = TextEditingController();
  final _psRatioController = TextEditingController();
  final _pbRatioController = TextEditingController();
  final _dividendYieldController = TextEditingController();
  final _financialsController = TextEditingController();

  // Relación inline Form
  final _relatedSymbolController = TextEditingController();
  final _multiplierController = TextEditingController();
  String _selectedRelationType = 'leveraged_long';
  bool _searchingRelated = false;
  Ticker? _foundRelatedTicker;
  String? _relationError;

  String _selectedAssetClass = 'stock';
  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEditing => widget.ticker != null;

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final t = widget.ticker!;
      _symbolController.text = t.symbol;
      _nameController.text = t.name;
      _selectedAssetClass = t.assetClass;
      _exchangeController.text = t.exchange ?? '';
      _sectorController.text = t.sector ?? '';
      _industryController.text = t.industry ?? '';
      _countryController.text = t.country ?? '';
      _priceController.text = t.price?.toString() ?? '';
      _changePctController.text = t.changePct?.toString() ?? '';
      _prevCloseController.text = t.prevClose?.toString() ?? '';
      _volumeController.text = t.volume?.toString() ?? '';
      _avgVolumeController.text = t.avgVolume?.toString() ?? '';
      _fiftyTwoWHighController.text = t.fiftyTwoWHigh?.toString() ?? '';
      _fiftyTwoWLowController.text = t.fiftyTwoWLow?.toString() ?? '';
      _marketCapController.text = t.marketCap?.toString() ?? '';
      _peRatioController.text = t.peRatio?.toString() ?? '';
      _forwardPeController.text = t.forwardPe?.toString() ?? '';
      _pegRatioController.text = t.pegRatio?.toString() ?? '';
      _psRatioController.text = t.psRatio?.toString() ?? '';
      _pbRatioController.text = t.pbRatio?.toString() ?? '';
      _dividendYieldController.text = t.dividendYield?.toString() ?? '';
      _financialsController.text = const JsonEncoder.withIndent(
        '  ',
      ).convert(t.financials);
    }
  }

  @override
  void dispose() {
    _symbolController.dispose();
    _nameController.dispose();
    _exchangeController.dispose();
    _sectorController.dispose();
    _industryController.dispose();
    _countryController.dispose();
    _priceController.dispose();
    _changePctController.dispose();
    _prevCloseController.dispose();
    _volumeController.dispose();
    _avgVolumeController.dispose();
    _fiftyTwoWHighController.dispose();
    _fiftyTwoWLowController.dispose();
    _marketCapController.dispose();
    _peRatioController.dispose();
    _forwardPeController.dispose();
    _pegRatioController.dispose();
    _psRatioController.dispose();
    _pbRatioController.dispose();
    _dividendYieldController.dispose();
    _financialsController.dispose();

    _relatedSymbolController.dispose();
    _multiplierController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    Map<String, dynamic> rawFinancials = {};
    if (_financialsController.text.trim().isNotEmpty) {
      try {
        rawFinancials =
            jsonDecode(_financialsController.text.trim())
                as Map<String, dynamic>;
      } catch (e) {
        setState(() {
          _errorMessage = 'Formato de JSON financiero inválido: $e';
          _isLoading = false;
        });
        return;
      }
    }

    final data = <String, dynamic>{
      'symbol': _symbolController.text.trim().toUpperCase(),
      'name': _nameController.text.trim(),
      'assetClass': _selectedAssetClass,
      'exchange': _exchangeController.text.trim().isEmpty
          ? null
          : _exchangeController.text.trim(),
      'sector': _sectorController.text.trim().isEmpty
          ? null
          : _sectorController.text.trim(),
      'industry': _industryController.text.trim().isEmpty
          ? null
          : _industryController.text.trim(),
      'country': _countryController.text.trim().isEmpty
          ? null
          : _countryController.text.trim(),
      'price': double.tryParse(_priceController.text),
      'changePct': double.tryParse(_changePctController.text),
      'prevClose': double.tryParse(_prevCloseController.text),
      'volume': int.tryParse(_volumeController.text),
      'avgVolume': int.tryParse(_avgVolumeController.text),
      'fiftyTwoWHigh': double.tryParse(_fiftyTwoWHighController.text),
      'fiftyTwoWLow': double.tryParse(_fiftyTwoWLowController.text),
      'marketCap': double.tryParse(_marketCapController.text),
      'peRatio': double.tryParse(_peRatioController.text),
      'forwardPe': double.tryParse(_forwardPeController.text),
      'pegRatio': double.tryParse(_pegRatioController.text),
      'psRatio': double.tryParse(_psRatioController.text),
      'pbRatio': double.tryParse(_pbRatioController.text),
      'dividendYield': double.tryParse(_dividendYieldController.text),
      'financials': rawFinancials,
    };

    try {
      if (_isEditing) {
        await ref
            .read(adminTickersProvider.notifier)
            .updateTicker(widget.ticker!.id, data, widget.ticker!.symbol);
      } else {
        await ref.read(adminTickersProvider.notifier).createTicker(data);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'Activo actualizado con éxito.'
                  : 'Activo creado con éxito.',
            ),
            backgroundColor: AppColors.positive,
          ),
        );
      }
    } on ApiException catch (e) {
      setState(() {
        _errorMessage = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Ocurrió un error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchRelated() async {
    final query = _relatedSymbolController.text.trim().toUpperCase();
    if (query.isEmpty) return;

    setState(() {
      _searchingRelated = true;
      _foundRelatedTicker = null;
      _relationError = null;
    });

    try {
      final res = await ref
          .read(tickerRepositoryProvider)
          .getTickers(q: query, limit: 100);
      Ticker? match;
      for (final t in res.tickers) {
        if (t.symbol.toUpperCase() == query) {
          match = t;
          break;
        }
      }
      if (match != null) {
        setState(() {
          _foundRelatedTicker = match;
          _searchingRelated = false;
        });
      } else {
        setState(() {
          _relationError = 'Activo subyacente no encontrado.';
          _searchingRelated = false;
        });
      }
    } catch (e) {
      setState(() {
        _relationError = 'Error al buscar activo: $e';
        _searchingRelated = false;
      });
    }
  }

  Future<void> _addRelation() async {
    if (_foundRelatedTicker == null) {
      setState(() {
        _relationError = 'Buscá y confirmá un activo válido primero.';
      });
      return;
    }

    final multiplierText = _multiplierController.text.trim();
    final multiplier = double.tryParse(multiplierText);

    if (multiplier == null || multiplier == 0) {
      setState(() {
        _relationError =
            'El multiplicador no puede ser cero y debe ser numérico.';
      });
      return;
    }

    // Validación lógica de signos
    if ((_selectedRelationType == 'inverse' ||
            _selectedRelationType == 'leveraged_short') &&
        multiplier >= 0) {
      setState(() {
        _relationError =
            'El multiplicador debe ser negativo para relaciones inversas/cortas.';
      });
      return;
    }

    if (_selectedRelationType == 'leveraged_long' && multiplier <= 0) {
      setState(() {
        _relationError =
            'El multiplicador debe ser positivo para relaciones largas.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _relationError = null;
    });

    try {
      await ref
          .read(adminTickersProvider.notifier)
          .addRelation(
            widget.ticker!.id,
            relatedTickerId: _foundRelatedTicker!.id,
            relationType: _selectedRelationType,
            multiplier: multiplier,
            symbolForInvalidate: widget.ticker!.symbol,
          );

      setState(() {
        _foundRelatedTicker = null;
        _relatedSymbolController.clear();
        _multiplierController.clear();
        _isLoading = false;
      });
    } on ApiException catch (e) {
      setState(() {
        _relationError = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _relationError = 'Error inesperado: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteRelation(TickerRelationInfo rel) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Necesitamos buscar el id de la relación por su símbolo
      final res = await ref
          .read(tickerRepositoryProvider)
          .getTickers(q: rel.symbol, limit: 100);
      Ticker? match;
      for (final t in res.tickers) {
        if (t.symbol.toUpperCase() == rel.symbol.toUpperCase()) {
          match = t;
          break;
        }
      }
      if (match != null) {
        await ref
            .read(adminTickersProvider.notifier)
            .deleteRelation(
              widget.ticker!.id,
              relatedTickerId: match.id,
              relationType: rel.relationType,
              symbolForInvalidate: widget.ticker!.symbol,
            );
      } else {
        setState(() {
          _errorMessage =
              'No se pudo encontrar el ID del activo relacionado para remover.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al remover relación: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _togglePlan(String slug, int planId, bool associated) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (associated) {
        await ref
            .read(adminTickersProvider.notifier)
            .deletePlan(widget.ticker!.id, planId, widget.ticker!.symbol);
      } else {
        await ref
            .read(adminTickersProvider.notifier)
            .addPlan(widget.ticker!.id, planId, widget.ticker!.symbol);
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error al actualizar asociación de plan: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    final width = MediaQuery.of(context).size.width;
    final isLarge = width >= 600;

    return DefaultTabController(
      length: _isEditing ? 3 : 1,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SizedBox(
          width: isLarge ? width * 0.8 : null,
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Título principal
                  Row(
                    children: [
                      Icon(
                        _isEditing ? LucideIcons.edit3 : LucideIcons.plusCircle,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _isEditing ? 'Editar Activo' : 'Crear Activo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: glassTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Tabs para separar la configuración de edición
                  if (_isEditing)
                    TabBar(
                      labelColor: Theme.of(context).colorScheme.primary,
                      unselectedLabelColor: glassTheme.textSecondary,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(text: 'Datos Básicos'),
                        Tab(text: 'Planes'),
                        Tab(text: 'Relaciones'),
                      ],
                    ),
                  const SizedBox(height: 16),

                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.negative.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.negative.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.alertCircle,
                            color: AppColors.negative,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                color: AppColors.negative,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Contenido de Tabs / Formularios
                  Flexible(
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: TabBarView(
                        physics:
                            const NeverScrollableScrollPhysics(), // Evitar jank
                        children: [
                          // Tab 1: Datos Básicos
                          _buildBasicTab(glassTheme),

                          // Tab 2: Planes
                          if (_isEditing) _buildPlansTab(glassTheme),

                          // Tab 3: Relaciones
                          if (_isEditing) _buildRelationsTab(glassTheme),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pop(context),
                        child: Text(
                          'Cerrar',
                          style: TextStyle(color: glassTheme.textSecondary),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submit,
                        child: _isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _isEditing ? 'Guardar Cambios' : 'Crear Activo',
                              ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicTab(GlassThemeExtension glassTheme) {
    return ListView(
      shrinkWrap: true,
      children: [
        // Símbolo y Nombre
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _symbolController,
                enabled:
                    !_isLoading &&
                    !_isEditing, // Símbolo es único y PK, no mutable al editar
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Símbolo',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                  hintText: 'ej. TSLA',
                ),
                style: TextStyle(color: glassTheme.textPrimary),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El símbolo es requerido.';
                  }
                  final regExp = RegExp(r'^[A-Z0-9.\-]+$');
                  if (!regExp.hasMatch(value.trim().toUpperCase())) {
                    return 'Símbolo inválido (solo letras, números, puntos y guiones).';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedAssetClass,
                decoration: InputDecoration(
                  labelText: 'Clase de Activo',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                dropdownColor: Theme.of(context).colorScheme.surface,
                style: TextStyle(color: glassTheme.textPrimary),
                items:
                    ['stock', 'etf', 'index', 'crypto', 'commodity', 'currency']
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.toUpperCase()),
                          ),
                        )
                        .toList(),
                onChanged: _isLoading
                    ? null
                    : (val) {
                        if (val != null) {
                          setState(() {
                            _selectedAssetClass = val;
                          });
                        }
                      },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _nameController,
          enabled: !_isLoading,
          decoration: InputDecoration(
            labelText: 'Nombre',
            labelStyle: TextStyle(color: glassTheme.textSecondary),
            hintText: 'ej. Tesla, Inc.',
          ),
          style: TextStyle(color: glassTheme.textPrimary),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'El nombre es requerido.';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        // Exchange y Sector
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _exchangeController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Mercado / Exchange',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                  hintText: 'ej. NASDAQ',
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _sectorController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Sector',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                  hintText: 'ej. Technology',
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Industria y País
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _industryController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'Industria',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                  hintText: 'ej. Auto Manufacturers',
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _countryController,
                enabled: !_isLoading,
                decoration: InputDecoration(
                  labelText: 'País',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                  hintText: 'ej. USA',
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const Divider(height: 32, color: Colors.white24),
        Text(
          'Métricas Financieras (Opcional)',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 12),
        // Precio y Cambio
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _priceController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Precio',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _changePctController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Cambio %',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Prev Close y Dividend Yield
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _prevCloseController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Cierre Prev.',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _dividendYieldController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Rend. Dividendo %',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Volúmenes
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _volumeController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Volumen',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _avgVolumeController,
                enabled: !_isLoading,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Volumen Promedio',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Rangos de precio 52 semanas
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _fiftyTwoWHighController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Máx. 52 Semanas',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _fiftyTwoWLowController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Mín. 52 Semanas',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Market Cap
        TextFormField(
          controller: _marketCapController,
          enabled: !_isLoading,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Capitalización de Mercado (USD)',
            labelStyle: TextStyle(color: glassTheme.textSecondary),
          ),
          style: TextStyle(color: glassTheme.textPrimary),
        ),
        const SizedBox(height: 12),
        // PE ratios
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _peRatioController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'PE Ratio',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextFormField(
                controller: _forwardPeController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Forward PE',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Ratios PEG, PS, PB
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _pegRatioController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'PEG Ratio',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _psRatioController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'PS Ratio',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _pbRatioController,
                enabled: !_isLoading,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'PB Ratio',
                  labelStyle: TextStyle(color: glassTheme.textSecondary),
                ),
                style: TextStyle(color: glassTheme.textPrimary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // RAW JSON Financials
        TextFormField(
          controller: _financialsController,
          enabled: !_isLoading,
          maxLines: 6,
          minLines: 3,
          decoration: InputDecoration(
            labelText: 'JSON Financiero Raw (Yahoo Finance/Finviz dump)',
            labelStyle: TextStyle(color: glassTheme.textSecondary),
            hintText: '{\n  "pe_ratio": 389.77,\n  "forward_pe": 176.09\n}',
          ),
          style: TextStyle(
            color: glassTheme.textPrimary,
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansTab(GlassThemeExtension glassTheme) {
    final detailAsync = ref.watch(tickerDetailProvider(widget.ticker!.symbol));
    final academyPlansAsync = ref.watch(academyPlansProvider);

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error al cargar detalle del activo: $err')),
      data: (detail) {
        return academyPlansAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) =>
              Center(child: Text('Error al cargar planes de membresía: $err')),
          data: (allPlans) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Planes de Membresía Vinculados',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Seleccioná los planes donde este activo estará disponible.',
                  style: TextStyle(
                    fontSize: 12,
                    color: glassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: allPlans.isEmpty
                      ? Center(
                          child: Text(
                            'No hay planes disponibles.',
                            style: TextStyle(color: glassTheme.textSecondary),
                          ),
                        )
                      : Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: allPlans.map((plan) {
                            final associated = detail.plans.contains(plan.slug);
                            return FilterChip(
                              label: Text(
                                plan.name ?? plan.slug.toUpperCase(),
                                style: TextStyle(
                                  color: associated
                                      ? Colors.white
                                      : glassTheme.textPrimary.withValues(
                                          alpha: 0.8,
                                        ),
                                  fontWeight: associated
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              selected: associated,
                              selectedColor: Theme.of(
                                context,
                              ).colorScheme.primary,
                              checkmarkColor: Colors.white,
                              onSelected: _isLoading
                                  ? null
                                  : (selected) {
                                      _togglePlan(
                                        plan.slug,
                                        plan.id,
                                        associated,
                                      );
                                    },
                            );
                          }).toList(),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildRelationsTab(GlassThemeExtension glassTheme) {
    final detailAsync = ref.watch(tickerDetailProvider(widget.ticker!.symbol));

    return detailAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) =>
          Center(child: Text('Error al cargar relaciones: $err')),
      data: (detail) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relaciones Financieras',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            // Formulario inline para agregar relación
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _relatedSymbolController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            labelText: 'Activo Relacionado',
                            labelStyle: TextStyle(
                              color: glassTheme.textSecondary,
                              fontSize: 12,
                            ),
                            hintText: 'ej. TSLL',
                            suffixIcon: _searchingRelated
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : IconButton(
                                    icon: const Icon(
                                      LucideIcons.search,
                                      size: 16,
                                    ),
                                    onPressed: _searchRelated,
                                  ),
                          ),
                          style: TextStyle(
                            color: glassTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          isExpanded: true,
                          value: _selectedRelationType,
                          decoration: InputDecoration(
                            labelText: 'Tipo Relación',
                            labelStyle: TextStyle(
                              color: glassTheme.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          style: TextStyle(
                            color: glassTheme.textPrimary,
                            fontSize: 13,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'leveraged_long',
                              child: Text('Long Apalanc.'),
                            ),
                            DropdownMenuItem(
                              value: 'leveraged_short',
                              child: Text('Short Apalanc.'),
                            ),
                            DropdownMenuItem(
                              value: 'inverse',
                              child: Text('Inverso'),
                            ),
                            DropdownMenuItem(
                              value: 'underlying',
                              child: Text('Subyacente'),
                            ),
                            DropdownMenuItem(
                              value: 'peer',
                              child: Text('Par (Peer)'),
                            ),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _selectedRelationType = val;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: _multiplierController,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Multiplicador',
                            labelStyle: TextStyle(
                              color: glassTheme.textSecondary,
                              fontSize: 12,
                            ),
                            hintText: 'ej. 2.0 o -1.0',
                          ),
                          style: TextStyle(
                            color: glassTheme.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (_foundRelatedTicker != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Subyacente encontrado: ${_foundRelatedTicker!.name}',
                      style: const TextStyle(
                        color: AppColors.positive,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (_relationError != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _relationError!,
                      style: const TextStyle(
                        color: AppColors.negative,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _foundRelatedTicker != null && !_isLoading
                        ? _addRelation
                        : null,
                    icon: const Icon(LucideIcons.plus, size: 14),
                    label: const Text(
                      'Asociar Relación',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Listado de relaciones asociadas
            Expanded(
              child: detail.relations.isEmpty
                  ? Center(
                      child: Text(
                        'No hay relaciones financieras configuradas.',
                        style: TextStyle(
                          color: glassTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: detail.relations.length,
                      itemBuilder: (context, index) {
                        final rel = detail.relations[index];
                        return Card(
                          color: Colors.white.withValues(alpha: 0.03),
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            dense: true,
                            title: Text(
                              '${rel.symbol} (${rel.relationType})',
                              style: TextStyle(
                                color: glassTheme.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Multiplicador: ${rel.multiplier} · ${rel.name}',
                              style: TextStyle(color: glassTheme.textSecondary),
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                LucideIcons.trash2,
                                color: AppColors.negative,
                                size: 16,
                              ),
                              onPressed: _isLoading
                                  ? null
                                  : () => _deleteRelation(rel),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
