// Política de contraseñas del cliente (pre-validación del formulario).
//
// El flag `must_reset_password` ahora vive en `app_metadata` de Supabase
// (sólo escribible server-side) y se baja con `POST /auth/change-password`.
// El cliente YA NO escribe ese flag ni ninguna metadata de seguridad: el
// servidor es la autoridad. Acá sólo queda la validación de longitud mínima
// para evitar un 400 obvio de ida y vuelta — el server revalida igual.

/// Longitud mínima exigida para una contraseña nueva (política del servidor).
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
