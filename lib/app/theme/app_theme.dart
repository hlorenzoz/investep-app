import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tema visual de la app. Base oscura pensada para glassmorphism.
///
/// Mantenemos un único tema oscuro por ahora; cuando se defina la variante clara
/// se agrega `lightTheme` y se conmuta vía un provider de Riverpod.
abstract final class AppTheme {
  static ThemeData get dark {
    final base = ThemeData.dark(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.backgroundTop,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent,
        secondary: AppColors.accentSoft,
        surface: AppColors.backgroundBottom,
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      // Las superficies "de cristal" se construyen con GlassCard, no con Card
      // de Material; dejamos el AppBar transparente para que el degradado pase.
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
    );
  }

  /// Degradado de fondo reutilizable detrás de las superficies glass.
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
  );
}
