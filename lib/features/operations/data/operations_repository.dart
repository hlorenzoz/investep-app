import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/operation.dart';

/// Capa de datos para interactuar con los endpoints de operaciones.
class OperationsRepository {
  OperationsRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// Listar operaciones (GET `/operations`)
  /// Query params opcionales:
  /// - `allocationId` (String/UUID): Para filtrar por cuenta de bróker.
  /// - `status` ('open' | 'closed'): Para filtrar por estado.
  Future<List<Operation>> getOperations({
    String? allocationId,
    String? status,
  }) {
    return retryWithBackoff(
      () async {
        final queryParameters = <String, dynamic>{};
        if (allocationId != null)
          queryParameters['allocationId'] = allocationId;
        if (status != null) queryParameters['status'] = status;

        final res = await _dio.get<Map<String, dynamic>>(
          '/operations',
          queryParameters: queryParameters,
        );

        final list = res.data!['operations'] as List<dynamic>;
        return list
            .map((e) => Operation.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// Crear operación (POST `/operations`)
  /// Payload: `CreateOperationRequest` (campos de creación)
  Future<Operation> createOperation(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/operations',
        data: data,
      );
      final operationJson = res.data!['operation'] as Map<String, dynamic>;
      return Operation.fromJson(operationJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Obtener detalle (GET `/operations/{id}`)
  Future<Operation> getOperationDetails(String id) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/operations/$id');
        final operationJson = res.data!['operation'] as Map<String, dynamic>;
        return Operation.fromJson(operationJson);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// Actualizar operación (PATCH `/operations/{id}`)
  Future<Operation> patchOperation(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/operations/$id',
        data: data,
      );
      final operationJson = res.data!['operation'] as Map<String, dynamic>;
      return Operation.fromJson(operationJson);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Eliminar operación (DELETE `/operations/{id}`)
  Future<void> deleteOperation(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/operations/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final operationsRepositoryProvider = Provider<OperationsRepository>((ref) {
  return OperationsRepository(ref.watch(apiClientProvider));
});
