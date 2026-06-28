import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_theme.dart';
import '../../app/theme/theme_provider.dart';

/// Widget de selector de tema interactivo y premium.
///
/// Cambia cíclicamente entre Claro -> Oscuro -> Sistema al presionar.
/// Utiliza IconButton nativo para garantizar compatibilidad con el layout del AppBar.
class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  void _handleThemeCycle(
    BuildContext context,
    WidgetRef ref,
    ThemeMode currentMode,
  ) {
    final nextMode = switch (currentMode) {
      ThemeMode.system => ThemeMode.light,
      ThemeMode.light => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.system,
    };

    ref.read(themeModeProvider.notifier).setThemeMode(nextMode);

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final modeLabel = switch (nextMode) {
      ThemeMode.system => 'Tema: Sistema',
      ThemeMode.light => 'Tema: Claro',
      ThemeMode.dark => 'Tema: Oscuro',
    };

    // Calculamos de forma predictiva los colores correctos para el tema entrante.
    // Esto asegura el contraste inmediato antes de que el árbol termine el build.
    final isNextDark =
        nextMode == ThemeMode.dark ||
        (nextMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final textColor = isNextDark ? AppColors.textPrimary : Colors.black;
    final fill = isNextDark ? const Color(0xFF131A2E) : Colors.white;
    final border = isNextDark ? AppColors.glassBorder : const Color(0x40000000);

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          modeLabel,
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
    final themeMode = ref.watch(themeModeProvider);

    final (icon, tooltip) = switch (themeMode) {
      ThemeMode.system => (LucideIcons.monitor, 'Tema: Sistema'),
      ThemeMode.light => (LucideIcons.sun, 'Tema: Claro'),
      ThemeMode.dark => (LucideIcons.moon, 'Tema: Oscuro'),
    };

    final glassTheme = context.glass;

    return IconButton(
      tooltip: tooltip,
      icon: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, animation) => ScaleTransition(
          scale: animation,
          child: FadeTransition(opacity: animation, child: child),
        ),
        child: Icon(
          icon,
          key: ValueKey<ThemeMode>(themeMode),
          size: 20,
          color: glassTheme.textPrimary,
        ),
      ),
      onPressed: () => _handleThemeCycle(context, ref, themeMode),
    );
  }
}
