import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/providers/supabase_provider.dart';
import '../../../core/storage/secure_session_store.dart';
import '../domain/password_policy.dart';

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

/// Controlador Riverpod (sin code-gen) del cambio de contraseña.
///
/// Flujo:
/// 1. Actualiza la contraseña en Supabase y, en la MISMA operación, limpia el
///    flag `must_reset_password` de `user_metadata` (que la API lee en
///    `/auth/me`).
/// 2. Cierra la sesión (Supabase + token local) para forzar un re-login con la
///    contraseña nueva — más seguro que mantener vivos tokens emitidos contra
///    la contraseña anterior.
///
/// La navegación NO vive acá: es responsabilidad de la vista reaccionar al
/// estado (`ChangePasswordSuccess`).
class ChangePasswordController extends Notifier<ChangePasswordState> {
  @override
  ChangePasswordState build() => const ChangePasswordInitial();

  Future<void> submit(String newPassword) async {
    state = const ChangePasswordLoading();

    try {
      final supabaseClient = ref.read(supabaseClientProvider);

      await supabaseClient.auth.updateUser(
        UserAttributes(
          password: newPassword,
          data: {mustResetPasswordMetadataKey: false},
        ),
      );

      // Forzamos re-login con la nueva contraseña.
      await supabaseClient.auth.signOut();
      await ref.read(secureSessionStoreProvider).clearSession();

      state = const ChangePasswordSuccess();
    } on AuthException catch (e) {
      state = ChangePasswordFailure(e.message);
    } catch (e) {
      state = ChangePasswordFailure('Ocurrió un error inesperado: $e');
    }
  }
}

final changePasswordControllerProvider =
    NotifierProvider.autoDispose<ChangePasswordController, ChangePasswordState>(
      ChangePasswordController.new,
    );
