import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';

/// Superficie de cristal (glassmorphism) construida con `BackdropFilter` +
/// `ImageFilter.blur` NATIVOS — sin librerías externas (ver AGENTS.md §4bis).
///
/// Rendimiento: el blur es costoso, sobre todo en web/escritorio. Vigilá la
/// cantidad de `BackdropFilter` simultáneos en pantalla; no apiles cristal sobre
/// cristal sin necesidad. Para listas largas, considerá un fondo plano.
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = 20,
    this.blur = 18,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double blur;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);
    final glass = context.glass;

    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: glass.glassFill,
            borderRadius: radius,
            border: Border.all(color: glass.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
