import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Extensión personalizada para las propiedades dinámicas de glassmorphism y
/// gradientes de fondo que no encajan directamente en el ColorScheme de Flutter.
class GlassThemeExtension extends ThemeExtension<GlassThemeExtension> {
  final Color glassFill;
  final Color glassBorder;
  final LinearGradient backgroundGradient;
  final Color textPrimary;
  final Color textSecondary;
  final Color positive;
  final Color negative;

  GlassThemeExtension({
    required this.glassFill,
    required this.glassBorder,
    required this.backgroundGradient,
    required this.textPrimary,
    required this.textSecondary,
    required this.positive,
    required this.negative,
  });

  @override
  GlassThemeExtension copyWith({
    Color? glassFill,
    Color? glassBorder,
    LinearGradient? backgroundGradient,
    Color? textPrimary,
    Color? textSecondary,
    Color? positive,
    Color? negative,
  }) {
    return GlassThemeExtension(
      glassFill: glassFill ?? this.glassFill,
      glassBorder: glassBorder ?? this.glassBorder,
      backgroundGradient: backgroundGradient ?? this.backgroundGradient,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      positive: positive ?? this.positive,
      negative: negative ?? this.negative,
    );
  }

  @override
  GlassThemeExtension lerp(
    ThemeExtension<GlassThemeExtension>? other,
    double t,
  ) {
    if (other is! GlassThemeExtension) return this;
    return GlassThemeExtension(
      glassFill: Color.lerp(glassFill, other.glassFill, t)!,
      glassBorder: Color.lerp(glassBorder, other.glassBorder, t)!,
      backgroundGradient: LinearGradient.lerp(
        backgroundGradient,
        other.backgroundGradient,
        t,
      )!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
    );
  }
}

/// Tema visual de la app. Soporta variantes claras y oscuras con glassmorphism.
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
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.textPrimary,
        centerTitle: false,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent,
          side: const BorderSide(color: AppColors.accent),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.accent,
          shape: const StadiumBorder(),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.accent.withOpacity(0.24),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.accent);
          }
          return const IconThemeData(color: AppColors.textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(color: AppColors.textSecondary, fontSize: 12);
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: AppColors.accent.withOpacity(0.24),
        selectedIconTheme: const IconThemeData(color: AppColors.accent),
        unselectedIconTheme: const IconThemeData(
          color: AppColors.textSecondary,
        ),
        selectedLabelTextStyle: const TextStyle(
          color: AppColors.accent,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
        ),
      ),
      extensions: [
        GlassThemeExtension(
          glassFill: AppColors.glassFill,
          glassBorder: AppColors.glassBorder,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
          ),
          textPrimary: AppColors.textPrimary,
          textSecondary: AppColors.textSecondary,
          positive: AppColors.positive,
          negative: AppColors.negative,
        ),
      ],
    );
  }

  static ThemeData get light {
    final base = ThemeData.light(useMaterial3: true);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.lightBackgroundTop,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.lightAccent, // Negro
        onPrimary: Colors.white,
        secondary: AppColors.lightAccentSoft, // Slate 700
        onSecondary: Colors.white,
        secondaryContainer: const Color(0xFFF1F5F9), // Slate 100
        onSecondaryContainer: Colors.black,
        surface: AppColors.lightBackgroundBottom, // Blanco
        onSurface: Colors.black,
        primaryContainer: AppColors.lightAccent, // Negro
        onPrimaryContainer: Colors.white,
        outline: const Color(0xFFE2E8F0), // Slate 200 (para bordes por defecto)
        outlineVariant: const Color(0xFFCBD5E1), // Slate 300
      ),
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: AppColors.lightTextPrimary,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.lightAccent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.lightAccent,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: const StadiumBorder(),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          side: const BorderSide(color: AppColors.lightAccent),
          shape: const StadiumBorder(),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.lightAccent,
          shape: const StadiumBorder(),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: SegmentedButton.styleFrom(
          selectedBackgroundColor: const Color(0xFFF1F5F9), // Slate 100
          selectedForegroundColor: Colors.black,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF475569), // Slate 600
          side: const BorderSide(color: Color(0xFFE2E8F0)), // Slate 200
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.lightAccent,
            width: 1.5,
          ),
        ),
        labelStyle: const TextStyle(color: Color(0xFF475569)),
        floatingLabelStyle: const TextStyle(color: AppColors.lightAccent),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: const Color(0xFFE2E8F0), // Slate 200
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.black);
          }
          return const IconThemeData(color: Color(0xFF475569)); // Slate 600
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            );
          }
          return const TextStyle(
            color: Color(0xFF475569), // Slate 600
            fontSize: 12,
          );
        }),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.transparent,
        indicatorColor: const Color(0xFFE2E8F0), // Slate 200
        selectedIconTheme: const IconThemeData(color: Colors.black),
        unselectedIconTheme: const IconThemeData(color: Color(0xFF475569)),
        selectedLabelTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        unselectedLabelTextStyle: const TextStyle(
          color: Color(0xFF475569),
          fontSize: 12,
        ),
      ),
      extensions: [
        GlassThemeExtension(
          glassFill: AppColors.lightGlassFill,
          glassBorder: AppColors.lightGlassBorder,
          backgroundGradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.lightBackgroundTop,
              AppColors.lightBackgroundBottom,
            ],
          ),
          textPrimary: AppColors.lightTextPrimary,
          textSecondary: AppColors.lightTextSecondary,
          positive: AppColors.lightPositive,
          negative: AppColors.lightNegative,
        ),
      ],
    );
  }
}

/// Extensión utilitaria sobre [BuildContext] para acceder de forma rápida
/// y segura a las propiedades de glassmorphism y gradientes.
///
/// Si la extensión de tema no está registrada (ej: en entornos de testing de
/// widgets simples), hace fallback al tema oscuro estándar por defecto para
/// evitar excepciones.
extension GlassThemeX on BuildContext {
  GlassThemeExtension get glass =>
      Theme.of(this).extension<GlassThemeExtension>() ??
      _defaultDarkGlassExtension;
}

final _defaultDarkGlassExtension = GlassThemeExtension(
  glassFill: AppColors.glassFill,
  glassBorder: AppColors.glassBorder,
  backgroundGradient: const LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.backgroundTop, AppColors.backgroundBottom],
  ),
  textPrimary: AppColors.textPrimary,
  textSecondary: AppColors.textSecondary,
  positive: AppColors.positive,
  negative: AppColors.negative,
);
