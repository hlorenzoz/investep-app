import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/providers/supabase_provider.dart';

/// Estados del login. El gating (`/auth/me`, 401 vs 503, mustResetPassword) NO
/// vive acá: lo maneja `AuthGate`. Este controlador sólo hace la pata Supabase.
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

/// Controlador del login. Responsabilidad acotada: autenticar contra Supabase
/// (`signInWithPassword`). Tras un signIn exitoso queda en [LoginLoading]: el
/// SDK emite `onAuthStateChange(signedIn)` → `AuthGate` evalúa `/auth/me` y el
/// `redirect` del router saca al usuario de `/login`.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginInitial();

  /// Reinicia el estado del login al inicial.
  void reset() {
    state = const LoginInitial();
  }

  /// Autentica contra Supabase Auth (la API REST no tiene endpoint de login).
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

      // Éxito: dejamos LoginLoading. El AuthGate (suscrito a onAuthStateChange)
      // valida la sesión y el router redirige fuera de /login.
    } on supabase.AuthException catch (e) {
      state = LoginFailure(e.message);
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
