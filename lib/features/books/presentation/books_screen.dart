import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../domain/recommended_book.dart';
import 'books_providers.dart';

class BooksScreen extends ConsumerWidget {
  const BooksScreen({super.key});

  Future<void> _launchBookUrl(BuildContext context, String urlString) async {
    if (urlString.isEmpty) return;
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
              content: Text('No se pudo abrir el enlace del libro.'),
              backgroundColor: AppColors.negative,
            ),
          );
        }
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El enlace no es válido o no se puede abrir.'),
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
    final booksAsync = ref.watch(publicBooksProvider);

    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    Widget bodyContent = booksAsync.when(
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
                'No se pudieron cargar los libros recomendados.',
                textAlign: TextAlign.center,
                style: TextStyle(color: glassTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(publicBooksProvider),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (books) {
        if (books.isEmpty) {
          return Center(
            child: Text(
              'No hay libros recomendados disponibles.',
              style: TextStyle(color: glassTheme.textSecondary),
            ),
          );
        }

        // Ordenar items de forma ascendente por sortOrder
        final sortedBooks = List<RecommendedBook>.from(books)
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

        return LayoutBuilder(
          builder: (context, constraints) {
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
                childAspectRatio: crossAxisCount == 1 ? 2.2 : 0.72,
              ),
              itemCount: sortedBooks.length,
              itemBuilder: (context, index) {
                final book = sortedBooks[index];
                return _BookGridCard(
                  book: book,
                  onTapCard: () {
                    context.push('/books/${book.slug}', extra: book);
                  },
                  onTapButton: () => _launchBookUrl(context, book.url),
                );
              },
            );
          },
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
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(LucideIcons.library, size: 22),
              const SizedBox(width: 10),
              Text(l10n.navBooks),
            ],
          ),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(child: bodyContent),
      ),
    );
  }
}

class _BookGridCard extends StatelessWidget {
  const _BookGridCard({
    required this.book,
    required this.onTapCard,
    required this.onTapButton,
  });

  final RecommendedBook book;
  final VoidCallback onTapCard;
  final VoidCallback onTapButton;

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;

    return InkWell(
      onTap: onTapCard,
      borderRadius: BorderRadius.circular(16),
      child: GlassCard(
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isHorizontal = constraints.maxWidth > constraints.maxHeight;

            final imageWidget = AspectRatio(
              aspectRatio: isHorizontal ? 1.0 : 1.3,
              child: Container(
                color: Colors.black.withValues(alpha: 0.15),
                child: book.imageUrl.isNotEmpty
                    ? Image.network(
                        book.imageUrl,
                        fit: BoxFit.contain,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Center(
                          child: Icon(
                            LucideIcons.bookOpen,
                            size: 40,
                            color: glassTheme.textSecondary.withValues(
                              alpha: 0.5,
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Icon(
                          LucideIcons.bookOpen,
                          size: 40,
                          color: glassTheme.textSecondary.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
              ),
            );

            final detailsWidget = Padding(
              padding: EdgeInsets.all(isHorizontal ? 12 : 16),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (book.description.isNotEmpty)
                    Flexible(
                      child: Text(
                        book.description,
                        maxLines: isHorizontal ? 2 : 4,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: glassTheme.textSecondary,
                        ),
                      ),
                    ),
                  const Spacer(),
                  const SizedBox(height: 8),
                  Builder(
                    builder: (context) {
                      final urlLower = book.url.toLowerCase();
                      final isAmazon =
                          urlLower.contains('amazon.com') ||
                          urlLower.contains('amazon.');
                      final isYouTube =
                          urlLower.contains('youtube.com') ||
                          urlLower.contains('youtu.be');

                      return ElevatedButton(
                        onPressed: onTapButton,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isAmazon
                              ? const Color(0xFFFFCE12)
                              : isYouTube
                              ? const Color(0xFFE52D27)
                              : Theme.of(context).colorScheme.secondary,
                          foregroundColor: isAmazon
                              ? Colors.black
                              : Colors.white,
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                        ),
                        child: Text(
                          isAmazon
                              ? 'Adquiérelo en Amazon'
                              : isYouTube
                              ? 'Escucha el audio libro\nen YouTube'
                              : 'Ver libro',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
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
      ),
    );
  }
}
