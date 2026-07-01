import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/broker.dart';

/// Capa de datos de brokers.
///
/// ⚠️ PRE-REQUISITO: si `GET /brokers` todavía no existe en la API (404), se
/// propaga como [ApiException] y el paso "Broker" del wizard muestra un estado
/// de error bloqueante. NUNCA se hardcodean brokers.
class BrokerRepository {
  BrokerRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /brokers` → lista de brokers. Backoff ante 503/500; 404 se propaga.
  Future<List<Broker>> getBrokers() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/brokers');
        final list = res.data!['brokers'] as List<dynamic>;
        return list
            .map((e) => Broker.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/brokers` → crear un broker.
  Future<Broker> createBroker(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/brokers',
        data: data,
      );
      final brokerJson = res.data!['broker'] as Map<String, dynamic>;
      return Broker.fromJson(brokerJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /admin/brokers/{id}` → actualizar un broker.
  Future<Broker> updateBroker(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/admin/brokers/$id',
        data: data,
      );
      final brokerJson = res.data!['broker'] as Map<String, dynamic>;
      return Broker.fromJson(brokerJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/brokers/{id}` → eliminar un broker.
  Future<void> deleteBroker(int id) async {
    try {
      await _dio.delete<void>('/admin/brokers/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final brokerRepositoryProvider = Provider<BrokerRepository>((ref) {
  return BrokerRepository(ref.watch(apiClientProvider));
});
