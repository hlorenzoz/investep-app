import 'dart:async';

import 'package:alchemist/alchemist.dart';

/// Config global de Alchemist para los golden tests.
///
/// Desactivamos los "platform goldens" (render real, dependiente de
/// fuentes/plataforma y del blur de BackdropFilter) y dejamos sólo los "CI
/// goldens" (deterministas, fuente Ahem). Correr SIEMPRE en host, nunca en web.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  return AlchemistConfig.runWithConfig(
    config: const AlchemistConfig(
      platformGoldensConfig: PlatformGoldensConfig(enabled: false),
    ),
    run: testMain,
  );
}
