import 'package:flutter/widgets.dart';

/// Paleta base de Investep App.
///
/// El glassmorphism luce mejor sobre fondos con profundidad, por eso el tema
/// base es oscuro con un degradado de fondo sobre el que apoyan las superficies
/// de cristal. Mantené el contraste alto: son datos financieros, la legibilidad
/// manda por encima del efecto visual.
abstract final class AppColors {
  // Fondo con profundidad (degradado) sobre el que apoyan las superficies glass.
  static const Color backgroundTop = Color(0xFF0B1020);
  static const Color backgroundBottom = Color(0xFF131A2E);

  // Acento de marca.
  static const Color accent = Color(0xFF4F8CFF);
  static const Color accentSoft = Color(0xFF8AB4FF);

  // Superficie de cristal: blanco translúcido + borde sutil.
  static const Color glassFill = Color(0x1FFFFFFF); // ~12% opacidad
  static const Color glassBorder = Color(0x33FFFFFF); // ~20% opacidad

  // Texto sobre fondo oscuro.
  static const Color textPrimary = Color(0xFFF5F7FF);
  static const Color textSecondary = Color(0xFFB6BFD8);

  // Semánticos (variaciones de cartera).
  static const Color positive = Color(0xFF36D399);
  static const Color negative = Color(0xFFFF5C7A);

  // --- Colores para el Tema Claro (Blanco y Negro de Alto Contraste) ---
  static const Color lightBackgroundTop = Color(0xFFFFFFFF);
  static const Color lightBackgroundBottom = Color(0xFFFFFFFF); // Blanco puro para todo el fondo

  static const Color lightAccent = Color(0xFF000000); // Negro puro para acento y botones
  static const Color lightAccentSoft = Color(0xFF334155); // Slate 700 para acentos secundarios

  // Superficie de cristal claro: gris slate ultra claro + borde gris suave para alto contraste.
  static const Color lightGlassFill = Color(0xFFF1F5F9); // Slate 100 (gris claro)
  static const Color lightGlassBorder = Color(0xFFE2E8F0); // Slate 200 (borde gris)

  // Texto sobre fondo claro.
  static const Color lightTextPrimary = Color(0xFF000000); // Negro puro
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600

  // Semánticos (variaciones de cartera en claro).
  static const Color lightPositive = Color(0xFF0D9488); // Teal 600
  static const Color lightNegative = Color(0xFFE11D48); // Rose 600
}
