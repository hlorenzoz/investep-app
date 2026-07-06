import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/favorite_star_button.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../tickers/domain/ticker.dart';
import '../../tickers/presentation/favorites_controller.dart';
import '../domain/relations_overview.dart';
import 'relations_providers.dart';

/// Vista de referencia de relaciones entre activos.
///
/// Consume un único endpoint agregado y solo renderiza dos tablas:
/// - Activos: activo principal → ETFs (x2/x3) → activo inverso.
/// - Sectores: ETF sectorial → sector → activo inverso.
class RelationsScreen extends ConsumerWidget {
  const RelationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final overviewAsync = ref.watch(relationsOverviewProvider);

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.waypoints, size: 22),
              const SizedBox(width: 10),
              Text(l10n.relationsTitle),
            ],
          ),
        ),
        body: SafeArea(
          child: overviewAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _ErrorState(
              error: err,
              onRetry: () => ref.invalidate(relationsOverviewProvider),
            ),
            data: (overview) => _RelationsContent(overview: overview),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  /// Detalle legible de la causa. `ApiException.toString()` ya rinde
  /// "ApiException(status, code): message" — no oculta el motivo real.
  String? get _detail => error?.toString();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    return Center(
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
              l10n.relationsError,
              textAlign: TextAlign.center,
              style: TextStyle(color: glassTheme.textPrimary),
            ),
            if (_detail != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  _detail!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: glassTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: Text(l10n.relationsRetry),
            ),
          ],
        ),
      ),
    );
  }
}

class _RelationsContent extends StatefulWidget {
  const _RelationsContent({required this.overview});

  final RelationsOverview overview;

  @override
  State<_RelationsContent> createState() => _RelationsContentState();
}

class _RelationsContentState extends State<_RelationsContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// Filtra los activos por símbolo/nombre del principal o símbolo de cualquier
  /// ETF relacionado (long o inverso).
  List<AssetRelation> get _filteredAssets {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.overview.assets;
    return widget.overview.assets.where((a) {
      if (a.symbol.toLowerCase().contains(q)) return true;
      if (a.name.toLowerCase().contains(q)) return true;
      return a.longEtfs.any((l) => l.symbol.toLowerCase().contains(q)) ||
          a.inverseEtfs.any((l) => l.symbol.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final assets = _filteredAssets;

    final content = SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sección "Favoritos" fija por encima del listado (se auto-oculta si vacía).
          const _FavoritesSection(),
          _SectionHeader(
            icon: LucideIcons.trendingUp,
            title: l10n.relationsAssetsSection,
          ),
          const SizedBox(height: 12),
          // Filtro por encima del listado de activos.
          _AssetSearchField(
            controller: _searchController,
            hint: l10n.relationsSearchHint,
            onChanged: (value) => setState(() => _query = value),
            onClear: () => setState(() {
              _searchController.clear();
              _query = '';
            }),
          ),
          const SizedBox(height: 12),
          if (widget.overview.assets.isEmpty)
            _EmptySection(message: l10n.relationsAssetsEmpty)
          else if (assets.isEmpty)
            _EmptySection(message: l10n.relationsNoResults)
          else
            ...assets.map(
              (asset) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _AssetCard(asset: asset),
              ),
            ),
          const SizedBox(height: 32),
          _SectionHeader(
            icon: LucideIcons.layers,
            title: l10n.relationsSectorsSection,
          ),
          const SizedBox(height: 12),
          if (widget.overview.sectors.isEmpty)
            _EmptySection(message: l10n.relationsSectorsEmpty)
          else
            ...widget.overview.sectors.map(
              (sector) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _SectorCard(sector: sector),
              ),
            ),
        ],
      ),
    );

    // Ancho limitado al 80% en tablet/desktop (>= 600dp); full en mobile.
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) return content;
        return Center(
          child: SizedBox(width: constraints.maxWidth * 0.8, child: content),
        );
      },
    );
  }
}

/// Campo de búsqueda de activos con estilo glass e ícono de limpiar.
class _AssetSearchField extends StatelessWidget {
  const _AssetSearchField({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: glassTheme.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: glassTheme.textSecondary, fontSize: 14),
        prefixIcon: Icon(
          LucideIcons.search,
          size: 18,
          color: glassTheme.textSecondary,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: glassTheme.textSecondary,
                ),
                onPressed: onClear,
              ),
        filled: true,
        fillColor: glassTheme.glassFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassTheme.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: glassTheme.glassBorder),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return Row(
      children: [
        Icon(icon, size: 20, color: glassTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: glassTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  const _EmptySection({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Icon(LucideIcons.inbox, size: 20, color: glassTheme.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sección "Favoritos" fija por encima del listado. Se alimenta de
/// `GET /tickers?favorite=true` y aplica el overlay optimista: se auto-oculta si
/// no queda ningún favorito visible.
class _FavoritesSection extends ConsumerWidget {
  const _FavoritesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final favoritesAsync = ref.watch(favoriteTickersProvider);
    final override = ref.watch(favoritesOverrideProvider);

    return favoritesAsync.maybeWhen(
      data: (tickers) {
        final visible = tickers
            .where((t) => override[t.symbol] ?? t.isFavorite)
            .toList();
        if (visible.isEmpty) return const SizedBox.shrink();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SectionHeader(
              icon: Icons.star_rounded,
              title: l10n.relationsFavorites,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: visible.map((t) => _FavoriteTile(ticker: t)).toList(),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

/// Tile compacto para la sección Favoritos (símbolo + estrella).
class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.ticker});

  final Ticker ticker;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return GlassCard(
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      borderRadius: 12,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            ticker.symbol,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: glassTheme.textPrimary,
            ),
          ),
          FavoriteStarButton(
            symbol: ticker.symbol,
            isFavorite: ticker.isFavorite,
            size: 18,
          ),
        ],
      ),
    );
  }
}

/// Fila de la tabla de activos. Responsive: en ancho grande las dos columnas de
/// ETFs van lado a lado; en mobile se apilan.
class _AssetCard extends StatelessWidget {
  const _AssetCard({required this.asset});

  final AssetRelation asset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    final longGroup = _RelationGroup(
      label: l10n.relationsColEtfs,
      links: asset.longEtfs,
      accent: AppColors.positive,
    );
    final inverseGroup = _RelationGroup(
      label: l10n.relationsColInverse,
      links: asset.inverseEtfs,
      accent: AppColors.negative,
    );

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: activo principal + nombre + clase.
          Row(
            children: [
              _SymbolBadge(symbol: asset.symbol),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.relationsColPrincipal,
                      style: TextStyle(
                        fontSize: 11,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                    if (asset.name.isNotEmpty)
                      Text(
                        asset.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: glassTheme.textPrimary,
                        ),
                      ),
                  ],
                ),
              ),
              FavoriteStarButton(
                symbol: asset.symbol,
                isFavorite: asset.isFavorite,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 520) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: longGroup),
                    const SizedBox(width: 16),
                    Expanded(child: inverseGroup),
                  ],
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [longGroup, const SizedBox(height: 12), inverseGroup],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectorCard extends StatelessWidget {
  const _SectorCard({required this.sector});

  final SectorRelation sector;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SymbolBadge(symbol: sector.etf),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.relationsColSector,
                      style: TextStyle(
                        fontSize: 11,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                    Text(
                      sector.sectorName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: glassTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              FavoriteStarButton(
                symbol: sector.etf,
                isFavorite: sector.isFavorite,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          _RelationGroup(
            label: l10n.relationsColInverse,
            links: sector.inverseEtfs,
            accent: AppColors.negative,
          ),
        ],
      ),
    );
  }
}

/// Columna etiquetada con los chips de ETFs relacionados.
class _RelationGroup extends StatelessWidget {
  const _RelationGroup({
    required this.label,
    required this.links,
    required this.accent,
  });

  final String label;
  final List<RelationLink> links;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: glassTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        if (links.isEmpty)
          Text(
            '—',
            style: TextStyle(color: glassTheme.textSecondary, fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: links
                .map((link) => _RelationChip(link: link, accent: accent))
                .toList(),
          ),
      ],
    );
  }
}

class _RelationChip extends StatelessWidget {
  const _RelationChip({required this.link, required this.accent});

  final RelationLink link;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            link.symbol,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: glassTheme.textPrimary,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            _formatMultiplier(link.multiplier),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
          ),
          const SizedBox(width: 2),
          FavoriteStarButton(
            symbol: link.symbol,
            isFavorite: link.isFavorite,
            size: 15,
          ),
        ],
      ),
    );
  }
}

class _SymbolBadge extends StatelessWidget {
  const _SymbolBadge({required this.symbol});

  final String symbol;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.5)),
      ),
      child: Text(
        symbol,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
          color: glassTheme.textPrimary,
        ),
      ),
    );
  }
}

/// Muestra el multiplicador con signo de forma compacta: 2.0 → "x2",
/// -1.0 → "-1x", 1.5 → "1.5x".
String _formatMultiplier(double m) {
  final isWhole = m == m.roundToDouble();
  final num value = isWhole ? m.toInt() : m;
  return m < 0 ? '${value}x' : 'x$value';
}
