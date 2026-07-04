import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/ticker.dart';

/// Capa de datos para la gestión de activos (Tickers), relaciones y planes.
class TickerRepository {
  TickerRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /tickers` → Buscar y listar activos (paginado y filtrado).
  Future<PaginatedTickers> getTickers({
    String? q,
    String? assetClass,
    String? sector,
    String? planSlug,
    bool? favorite,
    int page = 1,
    int limit = 20,
  }) {
    return retryWithBackoff(
      () async {
        final queryParams = <String, dynamic>{'page': page, 'limit': limit};
        if (q != null && q.isNotEmpty) queryParams['q'] = q;
        if (assetClass != null && assetClass.isNotEmpty) {
          queryParams['assetClass'] = assetClass;
        }
        if (sector != null && sector.isNotEmpty) queryParams['sector'] = sector;
        if (planSlug != null && planSlug.isNotEmpty) {
          queryParams['planSlug'] = planSlug;
        }
        if (favorite == true) queryParams['favorite'] = true;

        final res = await _dio.get<Map<String, dynamic>>(
          '/tickers',
          queryParameters: queryParams,
        );
        return PaginatedTickers.fromJson(res.data!);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /tickers/{symbol}` → Obtener detalle completo de un activo.
  Future<TickerDetail> getTickerDetail(String symbol) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/tickers/$symbol');
        return TickerDetail.fromJson(res.data!);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /tickers?favorite=true` → solo los activos favoritos del usuario.
  Future<List<Ticker>> getFavorites() async {
    final result = await getTickers(favorite: true, limit: 100);
    return result.tickers;
  }

  /// `PUT /tickers/{symbol}/favorite` → marca el activo como favorito.
  /// Idempotente. Devuelve el estado final (`favorite`).
  Future<bool> addFavorite(String symbol) {
    return retryWithBackoff(
      () async {
        final res = await _dio.put<Map<String, dynamic>>(
          '/tickers/$symbol/favorite',
        );
        return res.data?['favorite'] as bool? ?? true;
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `DELETE /tickers/{symbol}/favorite` → desmarca el activo.
  /// Idempotente. Devuelve el estado final (`favorite`).
  Future<bool> removeFavorite(String symbol) {
    return retryWithBackoff(
      () async {
        final res = await _dio.delete<Map<String, dynamic>>(
          '/tickers/$symbol/favorite',
        );
        return res.data?['favorite'] as bool? ?? false;
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/tickers` → Crear un nuevo activo (admin).
  Future<Ticker> createTicker(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/tickers',
        data: data,
      );
      final json = res.data!['ticker'] as Map<String, dynamic>;
      return Ticker.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /admin/tickers/{id}` → Actualizar parcialmente un activo (admin).
  Future<Ticker> updateTicker(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/admin/tickers/$id',
        data: data,
      );
      final json = res.data!['ticker'] as Map<String, dynamic>;
      return Ticker.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/tickers/{id}` → Eliminar un activo (admin).
  Future<void> deleteTicker(int id) async {
    try {
      await _dio.delete<void>('/admin/tickers/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /admin/tickers/{id}/relations` → Asociar un activo relacionado.
  Future<void> addRelation(
    int id, {
    required int relatedTickerId,
    required String relationType,
    required double multiplier,
  }) async {
    try {
      await _dio.post<void>(
        '/admin/tickers/$id/relations',
        data: {
          'relatedTickerId': relatedTickerId,
          'relationType': relationType,
          'multiplier': multiplier,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/tickers/{id}/relations` → Desasociar una relación.
  Future<void> deleteRelation(
    int id, {
    required int relatedTickerId,
    required String relationType,
  }) async {
    try {
      // De acuerdo al spec OpenAPI, el delete de relaciones espera un payload JSON
      // en el body con: relatedTickerId y relationType.
      await _dio.delete<void>(
        '/admin/tickers/$id/relations',
        data: {
          'relatedTickerId': relatedTickerId,
          'relationType': relationType,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /admin/tickers/{id}/plans` → Asociar el activo a un plan.
  Future<void> addPlan(int id, int planId) async {
    try {
      await _dio.post<void>(
        '/admin/tickers/$id/plans',
        data: {'planId': planId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/tickers/{id}/plans` → Remover el activo de un plan.
  Future<void> deletePlan(int id, int planId) async {
    try {
      await _dio.delete<void>(
        '/admin/tickers/$id/plans',
        data: {'planId': planId},
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final tickerRepositoryProvider = Provider<TickerRepository>((ref) {
  return TickerRepository(ref.watch(apiClientProvider));
});
