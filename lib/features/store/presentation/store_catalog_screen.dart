import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../domain/product.dart';
import 'store_providers.dart';

class StoreCatalogScreen extends ConsumerWidget {
  const StoreCatalogScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final productsAsync = ref.watch<AsyncValue<List<Product>>>(
      publicProductsProvider,
    );
    final activeFilter = ref.watch<ProductCategory?>(
      publicCategoryFilterProvider,
    );

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    Widget bodyContent = Column(
      children: [
        // Filtros de categoría (Pills premium)
        _CategoryFiltersRow(
          activeFilter: activeFilter,
          onFilterChanged: (filter) {
            ref.read(publicCategoryFilterProvider.notifier).setFilter(filter);
          },
        ),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, stack) => _ErrorState(
              error: err,
              onRetry: () => ref.invalidate(publicProductsProvider),
            ),
            data: (products) {
              if (products.isEmpty) {
                return Center(
                  child: Text(
                    l10n.storeEmpty,
                    style: TextStyle(color: glassTheme.textSecondary),
                  ),
                );
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  // Determinar número de columnas responsivo
                  final width = constraints.maxWidth;
                  final crossAxisCount = width < 600
                      ? 1
                      : width < 1000
                      ? 2
                      : 3;

                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: crossAxisCount == 1 ? 2.3 : 0.72,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _ProductGridCard(product: product);
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );

    if (isLargeScreen) {
      bodyContent = Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: screenWidth * 0.8),
          child: bodyContent,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(gradient: glassTheme.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.shoppingBag, size: 22),
              const SizedBox(width: 10),
              Text(l10n.storeTitle),
            ],
          ),
        ),
        body: SafeArea(child: bodyContent),
      ),
    );
  }
}

class _CategoryFiltersRow extends StatelessWidget {
  const _CategoryFiltersRow({
    required this.activeFilter,
    required this.onFilterChanged,
  });

  final ProductCategory? activeFilter;
  final ValueChanged<ProductCategory?> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    Widget buildPill(String label, ProductCategory? value) {
      final isSelected = activeFilter == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onFilterChanged(value),
          labelStyle: TextStyle(
            color: isSelected
                ? Theme.of(context).colorScheme.onSecondary
                : glassTheme.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
          selectedColor: Theme.of(context).colorScheme.secondary,
          backgroundColor: Colors.white.withValues(alpha: 0.05),
          side: BorderSide(
            color: isSelected
                ? Theme.of(context).colorScheme.secondary
                : glassTheme.glassBorder,
          ),
          showCheckmark: false,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          buildPill(l10n.storeCategoryAll, null),
          buildPill(l10n.storeCategoryBooks, ProductCategory.book),
          buildPill(l10n.storeCategoryTshirts, ProductCategory.tshirt),
          buildPill(l10n.storeCategoryCaps, ProductCategory.cap),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  const _ProductGridCard({required this.product});

  final Product product;

  Future<void> _handleAction(BuildContext context) async {
    if (product.amazonUrl != null && product.amazonUrl!.isNotEmpty) {
      try {
        final uri = Uri.parse(product.amazonUrl!.trim());
        if (await canLaunchUrl(uri)) {
          final success = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!success && context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('No se pudo abrir el enlace de Amazon.'),
                backgroundColor: AppColors.negative,
              ),
            );
          }
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'El enlace de Amazon no es válido o no se puede abrir.',
              ),
              backgroundColor: AppColors.negative,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocurrió un error al intentar abrir el enlace.'),
              backgroundColor: AppColors.negative,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    final hasPrice = product.price != null;
    final hasAmazonUrl =
        product.amazonUrl != null && product.amazonUrl!.isNotEmpty;

    return GlassCard(
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isHorizontal = constraints.maxWidth > constraints.maxHeight;

          final imageWidget = AspectRatio(
            aspectRatio: isHorizontal ? 1.0 : 1.4,
            child: Container(
              color: Colors.black.withValues(alpha: 0.15),
              child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(child: CircularProgressIndicator());
                      },
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Icon(
                          _getCategoryIcon(product.category),
                          size: 40,
                          color: glassTheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                    )
                  : Center(
                      child: Icon(
                        _getCategoryIcon(product.category),
                        size: 40,
                        color: glassTheme.textSecondary.withValues(alpha: 0.5),
                      ),
                    ),
            ),
          );

          final detailsWidget = Padding(
            padding: EdgeInsets.all(isHorizontal ? 12 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Categoría Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getCategoryLabel(context, product.category),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                // Título
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                // Descripción
                if (product.description != null)
                  Flexible(
                    child: Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                  ),
                const Spacer(),
                const SizedBox(height: 8),
                // Precio e info de compra
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (!hasAmazonUrl) ...[
                          if (hasPrice)
                            Text(
                              '\$${product.price!.toStringAsFixed(2)} ${product.currency}',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            )
                          else
                            Text(
                              '--',
                              style: TextStyle(
                                fontSize: 15,
                                color: glassTheme.textSecondary,
                              ),
                            ),
                        ],
                        if (product.category == ProductCategory.tshirt &&
                            (product.gender != null || product.theme != null))
                          Row(
                            children: [
                              if (product.gender != null)
                                Icon(
                                  product.gender == ProductGender.men
                                      ? LucideIcons.user
                                      : LucideIcons.user2,
                                  size: 14,
                                  color: glassTheme.textSecondary,
                                ),
                              const SizedBox(width: 4),
                              if (product.theme != null)
                                Icon(
                                  product.theme == ProductTheme.light
                                      ? LucideIcons.sun
                                      : LucideIcons.moon,
                                  size: 14,
                                  color: glassTheme.textSecondary,
                                ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (hasAmazonUrl)
                      ElevatedButton.icon(
                        onPressed: () => _handleAction(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber.shade700,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(LucideIcons.externalLink, size: 14),
                        label: Text(
                          l10n.storeBuyAmazon,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    else
                      ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          l10n.storeBuyNow,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );

          if (isHorizontal) {
            return Row(
              children: [
                imageWidget,
                Expanded(child: detailsWidget),
              ],
            );
          } else {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                imageWidget,
                Expanded(child: detailsWidget),
              ],
            );
          }
        },
      ),
    );
  }

  IconData _getCategoryIcon(ProductCategory cat) {
    switch (cat) {
      case ProductCategory.book:
        return LucideIcons.bookOpen;
      case ProductCategory.tshirt:
        return LucideIcons.shirt;
      case ProductCategory.cap:
        return LucideIcons.smile;
      default:
        return LucideIcons.shoppingBag;
    }
  }

  String _getCategoryLabel(BuildContext context, ProductCategory cat) {
    final l10n = AppLocalizations.of(context);
    switch (cat) {
      case ProductCategory.book:
        return l10n.storeCategoryBooks;
      case ProductCategory.tshirt:
        return l10n.storeCategoryTshirts;
      case ProductCategory.cap:
        return l10n.storeCategoryCaps;
      default:
        return '';
    }
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, this.error});

  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) {
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
              'No se pudieron cargar los productos.',
              textAlign: TextAlign.center,
              style: TextStyle(color: glassTheme.textPrimary),
            ),
            if (error != null) ...[
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Text(
                  error.toString(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: glassTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(LucideIcons.refreshCw, size: 16),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}
