import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/retry.dart';
import '../domain/relations_overview.dart';

/// Capa de datos de la vista de referencia de relaciones entre activos.
///
/// Un único endpoint de solo lectura (`GET /tickers/relations-overview`) que ya
/// devuelve todo agregado y agrupado. La app solo consume y parsea.
class RelationsRepository {
  RelationsRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /tickers/relations-overview` → catálogo completo de relaciones.
  ///
  /// 401 (token inválido) lo maneja el interceptor global (re-auth). 503 se
  /// reintenta con backoff y, si persiste, se propaga como [ApiException].
  Future<RelationsOverview> fetchRelationsOverview() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/tickers/relations-overview',
        );
        return RelationsOverview.fromJson(res.data!);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }
}

final relationsRepositoryProvider = Provider<RelationsRepository>((ref) {
  return RelationsRepository(ref.watch(apiClientProvider));
});
