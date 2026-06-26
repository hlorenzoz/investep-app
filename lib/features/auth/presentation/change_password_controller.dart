import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers/supabase_provider.dart';
import '../data/auth_repository.dart';

/// Estados posibles del cambio de contraseña.
sealed class ChangePasswordState {
  const ChangePasswordState();
}

class ChangePasswordInitial extends ChangePasswordState {
  const ChangePasswordInitial();
}

class ChangePasswordLoading extends ChangePasswordState {
  const ChangePasswordLoading();
}

class ChangePasswordSuccess extends ChangePasswordState {
  const ChangePasswordSuccess();
}

class ChangePasswordFailure extends ChangePasswordState {
  final String message;
  const ChangePasswordFailure(this.message);
}

/// La sesión expiró/se invalidó (401): hay que volver al login.
class ChangePasswordSessionExpired extends ChangePasswordState {
  final String message;
  const ChangePasswordSessionExpired(this.message);
}

/// Controlador Riverpod (sin code-gen) del cambio de contraseña.
///
/// Flujo (ver AGENTS §4):
/// 1. `POST /auth/change-password { newPassword }` (server-side). El backend
///    cambia la contraseña Y baja el flag `must_reset_password` en `app_metadata`
///    en una sola operación — el cliente YA NO escribe metadata.
/// 2. En un 200 el backend revoca TODAS las sesiones (incluida la actual), así
///    que el access token con el que llamamos queda muerto. Limpiamos la sesión
///    local (`signOut`) y la vista vuelve al login para re-autenticarse con la
///    contraseña nueva.
///
/// La navegación NO vive acá: es responsabilidad de la vista reaccionar al
/// estado (`ChangePasswordSuccess` / `ChangePasswordSessionExpired`).
class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordInitial();

  Future<void> submit(String newPassword) async {
    state = const ChangePasswordLoading();

    final repo = ref.read(authRepositoryProvider);
    final supabaseClient = ref.read(supabaseClientProvider);

    try {
      await repo.changePassword(newPassword);

      // 200 → sesión revocada globalmente. NO reutilizamos el token actual:
      // limpiamos la sesión local (access + refresh) y forzamos re-login.
      await supabaseClient.auth.signOut();
      state = const ChangePasswordSuccess();
    } on ApiException catch (e) {
      if (e.status == 401) {
        // Token inválido/expirado → limpiar sesión y volver al login.
        await supabaseClient.auth.signOut();
        state = ChangePasswordSessionExpired(e.message);
      } else if (e.status == 422) {
        // Body malformado: bug del cliente. No debería pasar porque siempre
        // mandamos { newPassword: String }.
        state = ChangePasswordFailure(
          'Error interno del cliente: ${e.message}',
        );
      } else {
        // 400 (política / rechazo de Supabase) y 500/503 (reintentable):
        // mostramos el message y dejamos reintentar desde el form.
        state = ChangePasswordFailure(e.message);
      }
    } catch (e) {
      state = ChangePasswordFailure('Ocurrió un error inesperado: $e');
    }
  }
}

final changePasswordControllerProvider =
    NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );
