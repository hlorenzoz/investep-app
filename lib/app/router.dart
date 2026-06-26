import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/auth/auth_gate.dart';
import '../core/auth/gate_refresh_listenable.dart';
import '../features/auth/presentation/change_password_screen.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/splash_screen.dart';
import '../features/portfolio/presentation/portfolio_screen.dart';
import '../features/setup/presentation/broker_setup_flow.dart';
import '../features/setup/presentation/setup_mode.dart';

/// Decisión de redirección a partir del estado del gate y la ubicación actual.
///
/// Función pura (sin contexto ni navegación) para poder testear el gating de
/// forma exhaustiva. Devuelve la ruta destino o `null` para permitir quedarse.
///
/// Clave de seguridad: `GateNeedsPasswordReset` fuerza `/change-password` desde
/// CUALQUIER otra ubicación. Como `redirect` corre en cada navegación (back y
/// deep-link incluidos), el gate de cambio de contraseña es INSALVABLE: la única
/// salida es el `signOut` del flujo exitoso → `GateNoSession` → `/login`.
String? gateRedirect(AuthGateState gate, String location) {
  return switch (gate) {
    GateChecking() ||
    GateRetrying503() => location == '/splash' ? null : '/splash',
    GateNoSession() => location == '/login' ? null : '/login',
    GateNeedsPasswordReset() =>
      location == '/change-password' ? null : '/change-password',
    GateAuthenticated() =>
      (location == '/login' ||
              location == '/splash' ||
              location == '/change-password')
          ? '/'
          : null,
  };
}

/// Router de la app. El `redirect` consume [authGateProvider] y se re-evalúa
/// vía `refreshListenable` cada vez que el gating cambia.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(gateRefreshProvider);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) =>
        gateRedirect(ref.read(authGateProvider), state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/change-password',
        name: 'change_password',
        builder: (context, state) => const ChangePasswordScreen(),
      ),
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => BrokerSetupFlow(
          mode: state.extra as SetupMode? ?? SetupMode.initialSetup,
        ),
      ),
      GoRoute(
        path: '/',
        name: 'portfolio',
        builder: (context, state) => const PortfolioScreen(),
      ),
    ],
  );
});
