import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../domain/product.dart';
import 'store_providers.dart';

class ProductDetailScreen extends ConsumerWidget {
  const ProductDetailScreen({super.key, required this.idOrSlug, this.product});

  final String idOrSlug;
  final Product? product;

  Future<void> _handleAction(BuildContext context, String? urlString) async {
    if (urlString == null || urlString.isEmpty) return;
    try {
      final uri = Uri.parse(urlString.trim());
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    final AsyncValue<Product> productAsyncValue = product != null
        ? AsyncValue<Product>.data(product!)
        : ref.watch(productDetailProvider(idOrSlug));

    Widget bodyContent = productAsyncValue.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(
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
                'No se pudo cargar el detalle del producto.',
                textAlign: TextAlign.center,
                style: TextStyle(color: glassTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () =>
                    ref.invalidate(productDetailProvider(idOrSlug)),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (loadedProduct) {
        final hasPrice = loadedProduct.price != null;
        final hasAmazonUrl =
            loadedProduct.amazonUrl != null &&
            loadedProduct.amazonUrl!.isNotEmpty;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      maxWidth: 300,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: loadedProduct.imageUrl.isNotEmpty
                            ? Image.network(
                                loadedProduct.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(
                                          loadedProduct.category,
                                        ),
                                        size: 80,
                                        color: glassTheme.textSecondary,
                                      ),
                                    ),
                              )
                            : Container(
                                color: Colors.black.withValues(alpha: 0.15),
                                child: Icon(
                                  _getCategoryIcon(loadedProduct.category),
                                  size: 80,
                                  color: glassTheme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Category Badge
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryLabel(context, loadedProduct.category),
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.secondary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Product Name
                Text(
                  loadedProduct.name,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Details (Gender and Theme if Shirt)
                if (loadedProduct.category == ProductCategory.tshirt &&
                    (loadedProduct.gender != null ||
                        loadedProduct.theme != null)) ...[
                  Row(
                    children: [
                      if (loadedProduct.gender != null) ...[
                        Icon(
                          loadedProduct.gender == ProductGender.men
                              ? LucideIcons.user
                              : LucideIcons.user2,
                          size: 16,
                          color: glassTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loadedProduct.gender == ProductGender.men
                              ? 'Hombre'
                              : 'Mujer',
                          style: TextStyle(
                            fontSize: 13,
                            color: glassTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 20),
                      ],
                      if (loadedProduct.theme != null) ...[
                        Icon(
                          loadedProduct.theme == ProductTheme.light
                              ? LucideIcons.sun
                              : LucideIcons.moon,
                          size: 16,
                          color: glassTheme.textSecondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          loadedProduct.theme == ProductTheme.light
                              ? 'Claro'
                              : 'Oscuro',
                          style: TextStyle(
                            fontSize: 13,
                            color: glassTheme.textSecondary,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 16),
                ],

                // Price
                if (hasPrice) ...[
                  Text(
                    '\$${loadedProduct.price!.toStringAsFixed(2)} ${loadedProduct.currency}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Description
                if (loadedProduct.description != null &&
                    loadedProduct.description!.isNotEmpty) ...[
                  Text(
                    'Descripción',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: glassTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    loadedProduct.description!,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: glassTheme.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // Action Button
                if (hasAmazonUrl)
                  ElevatedButton.icon(
                    onPressed: () =>
                        _handleAction(context, loadedProduct.amazonUrl),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    icon: const Icon(LucideIcons.externalLink, size: 16),
                    label: Text(
                      l10n.storeBuyAmazon,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                else
                  ElevatedButton(
                    onPressed: null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: Text(
                      l10n.storeBuyNow,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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
          title: const Text('Detalle del Producto'),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(child: bodyContent),
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
