import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../domain/recommended_book.dart';
import 'books_providers.dart';

class AdminBooksScreen extends ConsumerWidget {
  const AdminBooksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final glassTheme = context.glass;
    final booksAsync = ref.watch(adminBooksProvider);

    // Escuchar el controlador admin para mostrar Snackbars de error
    ref.listen<AsyncValue<void>>(booksAdminControllerProvider, (prev, next) {
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

    Widget bodyContent = booksAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => _ErrorState(
        error: err,
        onRetry: () => ref.invalidate(adminBooksProvider),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Text(
              'No hay libros recomendados registrados.',
              style: TextStyle(color: glassTheme.textSecondary),
            ),
          );
        }

        // Ordenar items por sortOrder ascendente
        final sortedBooks = List<RecommendedBook>.from(books)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          itemCount: sortedBooks.length,
          itemBuilder: (context, index) {
            final book = sortedBooks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _AdminBookRow(book: book),
            );
          },
        );
      },
    );

    // Aplicar regla de viewport grande (ancho >= 600 dp ocupa máximo el 80% y centrado)
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
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.bookOpen, size: 22),
              SizedBox(width: 10),
              Text('Gestión de Libros'),
            ],
          ),
          actions: buildAppBarActions(
            context,
            extraActions: [
              IconButton(
                icon: const Icon(LucideIcons.plus),
                onPressed: () => context.push('/admin/books/new'),
                tooltip: 'Crear Libro',
              ),
            ],
          ),
        ),
        body: SafeArea(child: bodyContent),
      ),
    );
  }
}

class _AdminBookRow extends ConsumerWidget {
  const _AdminBookRow({required this.book});

  final RecommendedBook book;

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final glassTheme = context.glass;

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900.withValues(alpha: 0.9),
          title: const Row(
            children: [
              Icon(LucideIcons.alertTriangle, color: AppColors.negative),
              SizedBox(width: 10),
              Text(
                'Confirmar eliminación',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
          content: Text(
            '¿Estás seguro de que deseas eliminar el libro "${book.title}"?',
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
                    .read(booksAdminControllerProvider.notifier)
                    .deleteRecommendedBook(book.id);
                if (success && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Libro eliminado correctamente.'),
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
          // Imagen del libro
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: Colors.black.withValues(alpha: 0.15),
            ),
            child: book.imageUrl.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      book.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        LucideIcons.bookOpen,
                        color: glassTheme.textSecondary,
                      ),
                    ),
                  )
                : Icon(LucideIcons.bookOpen, color: glassTheme.textSecondary),
          ),
          const SizedBox(width: 16),
          // Info del libro
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  book.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Autor: ${book.author}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.secondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Slug: ${book.slug} | Orden: ${book.sortOrder}',
                  style: TextStyle(
                    fontSize: 11,
                    color: glassTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Acciones
          IconButton(
            icon: const Icon(LucideIcons.edit3, color: AppColors.accent),
            onPressed: () {
              context.push('/admin/books/edit/${book.id}', extra: book);
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
              'No se pudo cargar la administración de libros.',
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
