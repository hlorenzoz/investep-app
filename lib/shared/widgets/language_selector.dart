import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../core/l10n/locale_provider.dart';

/// Widget de selector de idioma interactivo y premium.
///
/// Cambia entre Español ('es') y Inglés ('en') al presionar.
/// Utiliza IconButton nativo para garantizar compatibilidad con el layout del AppBar.
class LanguageSelector extends ConsumerWidget {
  const LanguageSelector({super.key});

  void _handleLanguageToggle(
    BuildContext context,
    WidgetRef ref,
    Locale currentLocale,
  ) {
    final nextLocale = currentLocale.languageCode == 'es'
        ? const Locale('en')
        : const Locale('es');

    ref.read(localeProvider.notifier).setLocale(nextLocale);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final isNextEn = nextLocale.languageCode == 'en';
    final label = isNextEn ? 'Language: English' : 'Idioma: Español';

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.textPrimary : Colors.black;
    final fill = isDark ? const Color(0xFF131A2E) : Colors.white;
    final border = isDark ? AppColors.glassBorder : const Color(0x40000000);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        backgroundColor: fill,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
        width: 180,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
        elevation: 0,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final isEn = locale.languageCode == 'en';
    final tooltip = isEn ? 'Language: English' : 'Idioma: Español';
    final glassTheme = context.glass;

    return IconButton(
      tooltip: tooltip,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Row(
          key: ValueKey<String>(locale.languageCode),
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.languages,
              size: 18,
              color: glassTheme.textPrimary,
            ),
            const SizedBox(width: 4),
            Text(
              locale.languageCode.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: glassTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
      onPressed: () => _handleLanguageToggle(context, ref, locale),
    );
  }
}
