import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Código de locale activo para las llamadas a la API (p. ej. `GET /plans`).
/// Default español; overrideable si más adelante se agrega selección de idioma.
final localeCodeProvider = Provider<String>((ref) => 'es');
