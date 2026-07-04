import 'package:dio/dio.dart';

/// Excepción de dominio que normaliza los errores de la API REST de Investep.
///
/// La API responde SIEMPRE con un único formato de error:
/// `{ "error": { "code": "...", "message": "...", "details"?: ... } }`.
/// `message` es seguro de mostrar al usuario (nunca trae internals de Supabase).
///
/// Centralizar el mapeo acá evita duplicar el parseo entre `/auth/me` y
/// `/auth/change-password` (y cualquier endpoint futuro).
class ApiException implements Exception {
  /// Código HTTP devuelto por la API (400 / 401 / 422 / 500 / 503 ...).
  final int status;

  /// `code` del envelope (VALIDATION_ERROR / UNAUTHORIZED / SERVICE_UNAVAILABLE
  /// / INTERNAL_ERROR / ...).
  final String code;

  /// Mensaje seguro para mostrar al usuario.
  final String message;

  const ApiException(this.status, this.code, this.message);

  /// `true` sólo para errores REALMENTE transitorios donde reintentar puede
  /// resolver: 503 (Supabase caído/throttleado) y 429 (rate limit). Los
  /// timeouts / caída de red se mapean a 503 (ver [fromDioException]), así que
  /// también entran acá.
  ///
  /// Un 500 es un error INTERNO del servidor: reintentarlo no lo arregla, sólo
  /// multiplica la carga y demora el error real que ve el usuario → NO se
  /// reintenta. Tampoco un 401 (token muerto → re-login) ni los 4xx de
  /// validación (400/422): reintentar el mismo request daría el mismo error.
  bool get isRetryable => status == 503 || status == 429;

  /// Normaliza un [DioException] al contrato de error de la API.
  ///
  /// - Con envelope `{ error: { code, message } }` → usa esos valores.
  /// - Con respuesta pero sin envelope → conserva el status con code `UNKNOWN`.
  /// - Sin respuesta (timeout / red caída / connectionError) → 503 reintentable,
  ///   porque desde el cliente es indistinguible de un backend caído.
  factory ApiException.fromDioException(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['error'] is Map) {
      final err = data['error'] as Map;
      return ApiException(
        e.response?.statusCode ?? 0,
        err['code']?.toString() ?? 'UNKNOWN',
        err['message']?.toString() ?? 'Ocurrió un error.',
      );
    }

    final status = e.response?.statusCode;
    if (status != null) {
      // Hubo respuesta pero sin el envelope esperado.
      return ApiException(
        status,
        'UNKNOWN',
        'Ocurrió un error inesperado (HTTP $status).',
      );
    }

    // Sin respuesta: timeout, red caída o connectionError → lo tratamos como
    // 503 reintentable.
    return const ApiException(
      503,
      'SERVICE_UNAVAILABLE',
      'No se pudo conectar con el servidor. Reintentá en unos segundos.',
    );
  }

  @override
  String toString() => 'ApiException($status, $code): $message';
}
