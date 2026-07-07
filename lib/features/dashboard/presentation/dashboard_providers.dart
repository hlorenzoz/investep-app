import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/auth/auth_gate.dart';
import '../../tickers/data/ticker_repository.dart';

/// Provider que asocia la sesión autenticada actual con el conteo de activos
/// accesibles para el plan del usuario.
final dashboardAssetsCountProvider = FutureProvider.autoDispose<int>((
  ref,
) async {
  final gateState = ref.watch(authGateProvider);
  if (gateState is! GateAuthenticated) {
    return 0;
  }

  final user = gateState.user;
  // Si el usuario es administrador o manager, no se filtra por plan (tiene acceso ilimitado).
  // En caso contrario, se utiliza su planSlug (ej. 'bronze', 'silver', 'gold', 'platinum').
  final String? planSlug = (user.role == 'admin' || user.role == 'manager')
      ? null
      : user.planSlug;

  try {
    final tickersData = await ref
        .watch(tickerRepositoryProvider)
        .getTickers(planSlug: planSlug, limit: 1);
    return tickersData.total;
  } catch (e) {
    // Registramos el error de red para producción y retornamos un fallback seguro (0)
    debugPrint('[Dashboard] Error al obtener tickers para plan $planSlug: $e');
    return 0;
  }
});
