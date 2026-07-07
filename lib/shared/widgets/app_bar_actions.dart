import 'package:flutter/material.dart';
import 'language_selector.dart';
import 'theme_selector.dart';

/// Helper para construir las acciones del AppBar de forma responsiva.
///
/// En viewports de escritorio/tablet (ancho >= 600 dp), agrega
/// automáticamente el selector de idioma y tema.
/// En móviles (smartphones), solo muestra las acciones adicionales provistas.
List<Widget> buildAppBarActions(
  BuildContext context, {
  List<Widget>? extraActions,
}) {
  final isDesktop = MediaQuery.sizeOf(context).width >= 600;
  return [
    if (extraActions != null) ...extraActions,
    if (isDesktop) ...[
      const LanguageSelector(),
      const ThemeSelector(),
      const SizedBox(width: 16),
    ],
  ];
}
