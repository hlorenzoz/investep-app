import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/network/api_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/auth_repository.dart';
import '../domain/auth_user.dart';

/// Estados posibles de la autenticación.
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final AuthUser user;
  const LoginSuccess(this.user);
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

/// El gate (`GET /auth/me`) falló por un error transitorio (503/500): el backend
/// o Supabase están caídos. La sesión Supabase SIGUE viva → NO se desloguea; se
/// ofrece reintentar.
class LoginGateRetryable extends LoginState {
  final String message;
  const LoginGateRetryable(this.message);
}

/// Controlador Riverpod sin code-gen que maneja el flujo de login.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginInitial();

  /// Reinicia el estado del login al inicial (útil para re-testear).
  void reset() {
    state = const LoginInitial();
  }

  /// Flujo de login:
  /// 1. Autenticación contra Supabase Auth (la API NO tiene endpoint de login).
  /// 2. Gate contra `GET /auth/me` con el Bearer que adjunta el interceptor.
  ///
  /// El token NO se persiste a mano: el SDK de Supabase mantiene la sesión y el
  /// interceptor lee `currentSession.accessToken` en cada request.
  Future<void> login(String email, String password) async {
    state = const LoginLoading();

    try {
      final supabaseClient = ref.read(supabaseClientProvider);

      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.session == null) {
        state = const LoginFailure(
          'Error: No se pudo obtener la sesión de Supabase.',
        );
        return;
      }

      await _runGate();
    } on supabase.AuthException catch (e) {
      state = LoginFailure(e.message);
    } catch (e) {
      state = LoginFailure('Ocurrió un error inesperado: $e');
    }
  }

  /// Reintenta SÓLO el gate (`GET /auth/me`) reusando la sesión Supabase ya
  /// activa — no re-hace el login. Lo usa la UI ante `LoginGateRetryable`.
  Future<void> retryGate() async {
    state = const LoginLoading();
    await _runGate();
  }

  /// Valida la sesión contra la API y decide el destino:
  /// - 200 → `LoginSuccess` (la vista decide gate de cambio de contraseña según
  ///   `user.mustResetPassword`).
  /// - 401 → token muerto: `signOut` + `LoginFailure` (re-login).
  /// - 503/500 → backend caído: `LoginGateRetryable` SIN desloguear.
  Future<void> _runGate() async {
    final repo = ref.read(authRepositoryProvider);
    try {
      final user = await repo.getMe();
      state = LoginSuccess(user);
    } on ApiException catch (e) {
      if (e.status == 401) {
        await ref.read(supabaseClientProvider).auth.signOut();
        state = LoginFailure(e.message);
      } else if (e.isRetryable) {
        // 503/500 → reintentar, NO desloguear (regla 401 ≠ 503).
        state = LoginGateRetryable(e.message);
      } else {
        state = LoginFailure(e.message);
      }
    } catch (e) {
      state = LoginFailure('Ocurrió un error inesperado: $e');
    }
  }
}

/// Provider para el controlador de login.
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );
