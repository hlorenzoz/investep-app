import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Último email autenticado, recordado a nivel app (NO autoDispose) para
/// precargarlo en el login tras un cambio de contraseña.
///
/// Se usa estado en memoria en vez de un query param en `/login`: en web, el
/// email en la URL quedaría en el historial del navegador (PII). El gate lo
/// setea cuando aprende el email del usuario (autenticado / needs-reset).
class LastEmail extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? email) => state = email;
}

final lastEmailProvider = NotifierProvider<LastEmail, String?>(LastEmail.new);
