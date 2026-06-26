import 'package:dio/dio.dart';

import 'api_exception.dart';

/// Ejecuta una operación HTTP idempotente (GET) con backoff exponencial ante
/// errores transitorios (503/500 / sin respuesta). Centraliza la política de
/// reintentos que antes se duplicaba en cada repositorio.
///
/// - Mapea `DioException` → [ApiException].
/// - Reintenta sólo si `error.isRetryable` y no se agotaron los intentos.
/// - Un 401/404/4xx se propaga en el primer intento (no se reintenta).
Future<T> retryWithBackoff<T>(
  Future<T> Function() operation, {
  required Duration baseDelay,
  int maxAttempts = 3,
}) async {
  var attempt = 0;
  while (true) {
    attempt++;
    try {
      return await operation();
    } on DioException catch (e) {
      final error = ApiException.fromDioException(e);
      if (!error.isRetryable || attempt >= maxAttempts) {
        throw error;
      }
      // Backoff exponencial: ~base, 2x, 4x ...
      await Future<void>.delayed(baseDelay * (1 << (attempt - 1)));
    }
  }
}
