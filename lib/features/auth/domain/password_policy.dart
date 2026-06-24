/// Política de contraseñas y constante de contrato compartida con la API.
///
/// `mustResetPasswordMetadataKey` es la clave que la API lee de `user_metadata`
/// de Supabase para decidir el flag `mustResetPassword` que retorna `/auth/me`.
/// Al cambiar la contraseña la limpiamos a `false` en la misma operación.
///
/// OJO (deuda de seguridad consciente): este flag vive en `user_metadata`, que
/// es editable por el propio usuario. El enforcement real debería moverse a
/// `app_metadata` + un endpoint admin en `investep-app-api`. Ver follow-up.
const String mustResetPasswordMetadataKey = 'must_reset_password';

/// Longitud mínima exigida para una contraseña nueva.
const int passwordMinLength = 8;

/// Valida una contraseña nueva. Devuelve el mensaje de error, o `null` si es
/// válida. Función pura: sin Flutter ni Supabase, fácil de testear.
String? validateNewPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Por favor ingresá una contraseña nueva';
  }
  if (value.length < passwordMinLength) {
    return 'La contraseña debe tener al menos $passwordMinLength caracteres';
  }
  return null;
}

/// Valida la confirmación contra la contraseña original. Devuelve el mensaje de
/// error, o `null` si coinciden.
String? validatePasswordConfirmation(String? value, String original) {
  if (value == null || value.isEmpty) {
    return 'Repetí la contraseña nueva';
  }
  if (value != original) {
    return 'Las contraseñas no coinciden';
  }
  return null;
}
