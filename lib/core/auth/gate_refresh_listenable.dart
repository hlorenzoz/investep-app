import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_gate.dart';

/// Adaptador que convierte cambios de [authGateProvider] en notificaciones para
/// el `refreshListenable` de go_router, de modo que `redirect` se re-evalúe cada
/// vez que el gating cambia de estado.
class GateRefreshListenable extends ChangeNotifier {
  GateRefreshListenable(Ref ref) {
    // `ref.listen` mantiene vivo a authGateProvider y dispara notifyListeners
    // en cada transición.
    ref.listen(authGateProvider, (_, _) => notifyListeners());
  }
}

final gateRefreshProvider = Provider<GateRefreshListenable>((ref) {
  final listenable = GateRefreshListenable(ref);
  ref.onDispose(listenable.dispose);
  return listenable;
});
