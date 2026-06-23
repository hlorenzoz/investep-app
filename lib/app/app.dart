import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';
import 'theme/app_theme.dart';

/// Raíz de la aplicación. Usa `MaterialApp.router` con go_router y aplica el
/// tema oscuro base sobre el que se construye el lenguaje glassmorphism.
class InvestepApp extends ConsumerWidget {
  const InvestepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Investep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      routerConfig: router,
    );
  }
}
