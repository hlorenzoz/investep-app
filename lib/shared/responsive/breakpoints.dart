import 'package:flutter/widgets.dart';

/// Breakpoints de la app. Único umbral por ahora: < 600 = móvil.
abstract final class Breakpoints {
  /// Ancho a partir del cual dejamos de tratar el layout como móvil.
  static const double mobile = 600;

  /// Ancho máximo de las superficies centradas (wizard) en tablet/desktop.
  static const double maxContentWidth = 520;
}

/// Factor de forma derivado del ancho disponible.
enum FormFactor { mobile, tabletDesktop }

extension ResponsiveContext on BuildContext {
  /// Factor de forma actual. Usa `MediaQuery.sizeOf` para suscribirse sólo a
  /// cambios de tamaño (no a todo el MediaQuery).
  FormFactor get formFactor =>
      MediaQuery.sizeOf(this).width < Breakpoints.mobile
      ? FormFactor.mobile
      : FormFactor.tabletDesktop;

  /// `true` cuando el layout debe comportarse como móvil (pantalla completa).
  bool get isMobile => formFactor == FormFactor.mobile;
}
