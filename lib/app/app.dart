import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/l10n/locale_provider.dart';
import '../l10n/gen/app_localizations.dart';
import 'router.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

/// Raíz de la aplicación. Usa `MaterialApp.router` con go_router y aplica el
/// tema dinámico (claro/oscuro/sistema) sobre el que se construye el lenguaje glassmorphism.
class InvestepApp extends ConsumerWidget {
  const InvestepApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Investep',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
