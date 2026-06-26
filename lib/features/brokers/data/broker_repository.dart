import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
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
}

final brokerRepositoryProvider = Provider<BrokerRepository>((ref) {
  return BrokerRepository(ref.watch(apiClientProvider));
});
