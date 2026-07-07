import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../features/auth/data/auth_repository.dart';
import '../../features/auth/domain/auth_user.dart';
import '../../features/auth/presentation/last_email_provider.dart';
import '../network/api_exception.dart';
import '../providers/supabase_provider.dart';

/// Estado del gating de la app. Mutuamente excluyente: determina a qué ruta
/// manda el `redirect` de go_router y qué muestra el splash.
sealed class AuthGateState {
  const AuthGateState();
}

/// Validando la sesión contra `GET /auth/me` (o primer arranque): muestra splash.
class GateChecking extends AuthGateState {
  const GateChecking();
}

/// El gate falló por un transitorio (503/500): la sesión Supabase SIGUE viva, NO
/// se desloguea. Splash con opción de reintentar.
class GateRetrying503 extends AuthGateState {
  final String message;
  const GateRetrying503(this.message);
}

/// No hay sesión (o se invalidó): mandar a `/login`.
class GateNoSession extends AuthGateState {
  const GateNoSession();
}

/// Sesión válida pero `mustResetPassword == true`: forzar `/change-password`.
class GateNeedsPasswordReset extends AuthGateState {
  final AuthUser user;
  const GateNeedsPasswordReset(this.user);
}

/// Sesión válida y contraseña vigente: acceso normal a la app.
class GateAuthenticated extends AuthGateState {
  final AuthUser user;
  const GateAuthenticated(this.user);
}

/// Fuente de verdad del gating, viva a nivel app (NO autoDispose) para
/// sobrevivir al login y manejar cold-start / deep-link / refresh de token.
///
/// Se apoya en `onAuthStateChange` de Supabase: al suscribirse, el SDK emite el
/// estado inicial (sesión restaurada o null), lo que dispara la primera
/// evaluación. Eventos posteriores (signIn / signOut / tokenRefreshed) la
/// re-disparan. La navegación NO vive acá: el `redirect` de go_router observa
/// este estado vía un `refreshListenable`.
class AuthGate extends Notifier<AuthGateState> with WidgetsBindingObserver {
  StreamSubscription<supabase.AuthState>? _sub;
  bool _evaluating = false;
  bool _dirty = false;
  bool _disposed = false;

  @override
  AuthGateState build() {
    ref.onDispose(() {
      _disposed = true;
      _sub?.cancel();
      try {
        WidgetsBinding.instance.removeObserver(this);
      } catch (_) {
        // En tests de unidad puros el binding no se inicializa
      }
    });

    try {
      final client = ref.read(supabaseClientProvider);
      _sub = client.auth.onAuthStateChange.listen(_onAuthChanged);
      try {
        WidgetsBinding.instance.addObserver(this);
      } catch (_) {
        // En tests de unidad puros el binding no se inicializa
      }
    } catch (_) {
      // Supabase no inicializado (config inválida): no podemos gatear, mandamos
      // a /login (que muestra el aviso de configuración).
      Future.microtask(() => _set(const GateNoSession()));
    }

    return const GateChecking();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(forceRefresh());
    }
  }

  void _set(AuthGateState next) {
    if (_disposed) return;
    state = next;
  }

  void _onAuthChanged(supabase.AuthState data) {
    if (data.session == null) {
      _set(const GateNoSession());
    } else {
      final event = data.event;
      final isRelevantEvent =
          event == supabase.AuthChangeEvent.signedIn ||
          event == supabase.AuthChangeEvent.initialSession ||
          event == supabase.AuthChangeEvent.passwordRecovery ||
          event == supabase.AuthChangeEvent.userUpdated;

      final alreadyAuthenticated =
          state is GateAuthenticated || state is GateNeedsPasswordReset;

      if (!alreadyAuthenticated || isRelevantEvent) {
        unawaited(evaluate());
      }
    }
  }

  /// Evalúa la sesión actual contra `GET /auth/me` y decide el destino.
  ///
  /// El guard `_evaluating` evita corridas concurrentes. Si llega un evento de
  /// auth (signedIn/tokenRefreshed) mientras hay una evaluación en vuelo, se
  /// marca `_dirty` para re-evaluar al terminar y NO perder ese evento.
  Future<void> evaluate() async {
    if (_evaluating) {
      _dirty = true;
      return;
    }
    _evaluating = true;
    try {
      do {
        _dirty = false;
        await _runOnce();
      } while (_dirty && !_disposed);
    } finally {
      _evaluating = false;
    }
  }

  /// Forzar refresco de sesión en Supabase y evaluación de /auth/me.
  /// Útil ante transiciones a primer plano (foreground) o cambios inmediatos de rol/plan.
  Future<void> forceRefresh() async {
    final client = ref.read(supabaseClientProvider);
    if (client.auth.currentSession != null) {
      try {
        await client.auth.refreshSession();
      } catch (_) {
        // Ignoramos fallos de red durante el refresh
      }
    }
    await evaluate();
  }

  Future<void> _runOnce() async {
    final client = ref.read(supabaseClientProvider);
    if (client.auth.currentSession == null) {
      _set(const GateNoSession());
      return;
    }

    final wasAuthenticated =
        state is GateAuthenticated || state is GateNeedsPasswordReset;
    final previousState = state;

    if (!wasAuthenticated) {
      _set(const GateChecking());
    }

    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.getMe();
      // Recordamos el email para precargarlo en el login tras change-password.
      ref.read(lastEmailProvider.notifier).set(user.email);
      _set(
        user.mustResetPassword
            ? GateNeedsPasswordReset(user)
            : GateAuthenticated(user),
      );
    } on ApiException catch (e) {
      if (e.status == 401) {
        // Token muerto. La limpieza de sesión (signOut) la centraliza el
        // interceptor de Dio (handleAuthError); acá sólo reflejamos el gating.
        _set(const GateNoSession());
      } else if (e.isRetryable) {
        if (wasAuthenticated) {
          // Si ya estaba autenticado, no lo pateamos a la pantalla de error.
          // Mantenemos el estado previo para no arruinar la UX.
          _set(previousState);
        } else {
          // 503/429 → transitorio: NO desloguear, ofrecer reintento.
          _set(GateRetrying503(e.message));
        }
      } else {
        // 4xx inesperado: lo más seguro es re-login.
        _set(const GateNoSession());
      }
    } catch (_) {
      if (wasAuthenticated) {
        _set(previousState);
      } else {
        _set(const GateNoSession());
      }
    }
  }

  /// Reintenta el gate tras un 503/429 (lo dispara el botón "Reintentar" del splash).
  Future<void> retry503() => evaluate();
}

final authGateProvider = NotifierProvider<AuthGate, AuthGateState>(
  AuthGate.new,
);
