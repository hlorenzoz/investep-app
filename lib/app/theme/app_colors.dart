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
}
