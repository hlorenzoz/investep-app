import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_theme.dart';
import '../../../shared/widgets/glass/glass_card.dart';
import '../../../shared/widgets/app_bar_actions.dart';
import '../domain/recommended_book.dart';
import 'books_providers.dart';

class BookDetailScreen extends ConsumerWidget {
  const BookDetailScreen({super.key, required this.idOrSlug, this.book});

  final String idOrSlug;
  final RecommendedBook? book;

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
    final glassTheme = context.glass;
    final screenWidth = MediaQuery.of(context).size.width;
    final isLargeScreen = screenWidth >= 600;

    final AsyncValue<RecommendedBook> bookAsyncValue = book != null
        ? AsyncValue<RecommendedBook>.data(book!)
        : ref.watch(bookDetailProvider(idOrSlug));

    Widget bodyContent = bookAsyncValue.when(
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
                'No se pudo cargar el detalle del libro.',
                textAlign: TextAlign.center,
                style: TextStyle(color: glassTheme.textPrimary),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => ref.invalidate(bookDetailProvider(idOrSlug)),
                icon: const Icon(LucideIcons.refreshCw, size: 16),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      ),
      data: (loadedBook) {
        final urlLower = loadedBook.url.toLowerCase();
        final isAmazon =
            urlLower.contains('amazon.com') || urlLower.contains('amazon.');
        final isYouTube =
            urlLower.contains('youtube.com') || urlLower.contains('youtu.be');

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: GlassCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Book Cover
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxHeight: 300,
                      maxWidth: 200,
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
                        child: loadedBook.imageUrl.isNotEmpty
                            ? Image.network(
                                loadedBook.imageUrl,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      color: Colors.black.withValues(
                                        alpha: 0.15,
                                      ),
                                      child: Icon(
                                        LucideIcons.bookOpen,
                                        size: 80,
                                        color: glassTheme.textSecondary,
                                      ),
                                    ),
                              )
                            : Container(
                                color: Colors.black.withValues(alpha: 0.15),
                                child: Icon(
                                  LucideIcons.bookOpen,
                                  size: 80,
                                  color: glassTheme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Title
                Text(
                  loadedBook.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Author
                Text(
                  'Autor: ${loadedBook.author}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Description Title
                Text(
                  'Descripción',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: glassTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),

                // Description Text
                Text(
                  loadedBook.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: glassTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 32),

                // Action Button
                ElevatedButton(
                  onPressed: () => _launchBookUrl(context, loadedBook.url),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isAmazon
                        ? const Color(0xFFFFCE12)
                        : isYouTube
                        ? const Color(0xFFE52D27)
                        : Theme.of(context).colorScheme.secondary,
                    foregroundColor: isAmazon ? Colors.black : Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    isAmazon
                        ? 'Adquiérelo en Amazon'
                        : isYouTube
                        ? 'Escucha el audio libro en YouTube'
                        : 'Ver libro',
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
          title: const Text('Detalle del Libro'),
          actions: buildAppBarActions(context),
        ),
        body: SafeArea(child: bodyContent),
      ),
    );
  }
}
