import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Marca que el usuario pospuso la configuración inicial ("Configurar más
/// tarde" en modo initialSetup). El dashboard muestra un banner mientras el
/// capital siga sin configurarse. App-scoped (sobrevive la navegación).
class SetupDeferred extends Notifier<bool> {
  @override
  bool build() => false;

  void markDeferred() => state = true;
  void clear() => state = false;
}

final setupDeferredProvider = NotifierProvider<SetupDeferred, bool>(
  SetupDeferred.new,
);
