import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../domain/product.dart';
import 'store_providers.dart';

class AdminStoreScreen extends ConsumerWidget {
  const AdminStoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;
    final productsAsync = ref.watch(adminProductsProvider);

    // Escuchar el controlador admin para mostrar Snackbars de carga/error/éxito
    ref.listen<AsyncValue<void>>(storeAdminControllerProvider, (prev, next) {
      next.whenOrNull(
        error: (err, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $err'),
              backgroundColor: AppColors.negative,
            ),
          );
        },
      );
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    Widget bodyContent = productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorState(
        error: err,
        onRetry: () => ref.invalidate(adminProductsProvider),
      ),
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Text(
              'No hay productos registrados.',
              style: TextStyle(color: glassTheme.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AdminProductRow(product: product),
            );
          },
        );
      },
    );

    // Aplicar regla de viewport grande (máximo 80% del display y centrado)
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
              const Icon(LucideIcons.store, size: 22),
              const SizedBox(width: 10),
              Text(l10n.storeAdminTitle),
            ],
          ),
          actions: buildAppBarActions(
            context,
            extraActions: [
              IconButton(
                icon: const Icon(LucideIcons.plus),
                onPressed: () => context.push('/admin/store/new'),
                tooltip: 'Crear Producto',
              ),
            ],
          ),
        ),
        body: SafeArea(child: bodyContent),
      ),
    );
  }
}

class _AdminProductRow extends ConsumerWidget {
  const _AdminProductRow({required this.product});

  final Product product;

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900.withValues(alpha: 0.9),
          title: Row(
            children: [
              const Icon(LucideIcons.alertTriangle, color: AppColors.negative),
              const SizedBox(width: 10),
              Text(
                l10n.storeDeleteConfirmTitle,
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            l10n.storeDeleteConfirmMsg(product.name),
            style: TextStyle(color: glassTheme.textPrimary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.cancel,
                style: TextStyle(color: glassTheme.textSecondary),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.negative,
              ),
              onPressed: () async {
                Navigator.of(context).pop();
                final success = await ref
                    .read(storeAdminControllerProvider.notifier)
                    .deleteProduct(product.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(l10n.storeDeleteSuccess),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          // Imagen pequeña o Icono
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withValues(alpha: 0.15),
            ),
            child: product.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        _getCategoryIcon(product.category),
                        color: glassTheme.textSecondary,
                      ),
                    ),
                  )
                : Icon(
                    _getCategoryIcon(product.category),
                    color: glassTheme.textSecondary,
                  ),
          ),
          const SizedBox(width: 16),
          // Info del producto
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: glassTheme.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge de activo/inactivo
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.active
                            ? Colors.green.withValues(alpha: 0.15)
                            : Colors.red.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        product.active ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          color: product.active ? Colors.green : Colors.red,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Slug: ${product.slug}',
                  style: TextStyle(
                    fontSize: 11,
                    color: glassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      _getCategoryLabel(context, product.category),
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (product.price != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '| \$${product.price!.toStringAsFixed(2)} ${product.currency}',
                        style: TextStyle(
                          fontSize: 12,
                          color: glassTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Acciones
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: AppColors.accent),
            onPressed: () {
              context.push('/admin/store/edit/${product.id}', extra: product);
            },
            tooltip: 'Editar',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, color: AppColors.negative),
            onPressed: () => _showDeleteDialog(context, ref),
            tooltip: 'Eliminar',
          ),
        ],
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
              'No se pudo cargar la administración de la tienda.',
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
