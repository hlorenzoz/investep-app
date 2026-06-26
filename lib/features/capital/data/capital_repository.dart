import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/allocation.dart';
import '../domain/capital.dart';
import '../domain/capital_overview.dart';

/// Capa de datos del capital y sus allocations.
///
/// `GET /capital` es idempotente → reintenta con backoff ante 503/500 (igual
/// que `AuthRepository.getMe`). Las mutaciones (PUT/POST/PATCH/DELETE) NO se
/// reintentan: el reintento lo dispara el usuario reenviando el formulario; los
/// 4xx (409/404/422) se propagan como [ApiException] con `error.message`.
class CapitalRepository {
  CapitalRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /capital` → capital + allocations + totales. Backoff ante transitorios.
  Future<CapitalOverview> getCapital() async {
    var attempt = 0;
    while (true) {
      attempt++;
      try {
        final res = await _dio.get<Map<String, dynamic>>('/capital');
        return CapitalOverview.fromJson(res.data!);
      } on DioException catch (e) {
        final error = ApiException.fromDioException(e);
        if (!error.isRetryable || attempt >= _maxAttempts) {
          throw error;
        }
        await Future<void>.delayed(_retryBaseDelay * (1 << (attempt - 1)));
      }
    }
  }

  /// `PUT /capital { totalCapital, currency? }`. 409 = capital < asignado o
  /// cambio de moneda con allocations existentes.
  Future<Capital> putCapital({
    required num totalCapital,
    String? currency,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/capital',
        data: {'totalCapital': totalCapital, 'currency': ?currency},
      );
      return Capital.fromJson(res.data!['capital'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `POST /capital/allocations`. IMPORTANTE: `accountType` NO se envía — lo
  /// deriva el backend del plan. 201 → allocation creada.
  Future<Allocation> createAllocation({
    required int brokerId,
    required int investmentPlanId,
    required num initialDeposit,
    String? currency,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/capital/allocations',
        data: {
          'brokerId': brokerId,
          'investmentPlanId': investmentPlanId,
          'initialDeposit': initialDeposit,
          'currency': ?currency,
        },
      );
      return Allocation.fromJson(
        res.data!['allocation'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /capital/allocations/{id}` con los campos provistos.
  Future<Allocation> patchAllocation(
    String id, {
    int? investmentPlanId,
    num? initialDeposit,
    String? currency,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/capital/allocations/$id',
        data: {
          'investmentPlanId': ?investmentPlanId,
          'initialDeposit': ?initialDeposit,
          'currency': ?currency,
        },
      );
      return Allocation.fromJson(
        res.data!['allocation'] as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /capital/allocations/{id}` → `{ deleted: true }`.
  Future<void> deleteAllocation(String id) async {
    try {
      await _dio.delete<Map<String, dynamic>>('/capital/allocations/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final capitalRepositoryProvider = Provider<CapitalRepository>((ref) {
  return CapitalRepository(ref.watch(apiClientProvider));
});
