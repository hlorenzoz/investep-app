import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/retry.dart';
import '../domain/academy_models.dart';

class AcademyRepository {
  AcademyRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /academy/plans?locale=` → paquetes de la academia para el cliente.
  Future<List<AcademyPlan>> getAcademyPlans({String locale = 'es'}) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/academy/plans',
          queryParameters: {'locale': locale},
        );
        final list = res.data!['plans'] as List<dynamic>;
        return list
            .map((e) => AcademyPlan.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /admin/academy/plans` → catálogo completo para administración.
  Future<List<AcademyPlanAdmin>> getAdminAcademyPlans() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/admin/academy/plans',
        );
        final list = res.data!['plans'] as List<dynamic>;
        return list
            .map((e) => AcademyPlanAdmin.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/academy/plans` → crear un paquete.
  Future<AcademyPlanAdmin> createAcademyPlan(Map<String, dynamic> plan) {
    return retryWithBackoff(
      () async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/admin/academy/plans',
          data: plan,
        );
        return AcademyPlanAdmin.fromJson(
          res.data!['plan'] as Map<String, dynamic>,
        );
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `PATCH /admin/academy/plans/:id` → actualización de un paquete.
  Future<AcademyPlanAdmin> updateAcademyPlan(
    int id,
    Map<String, dynamic> delta,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/admin/academy/plans/$id',
      data: delta,
    );
    return AcademyPlanAdmin.fromJson(res.data!['plan'] as Map<String, dynamic>);
  }

  /// `DELETE /admin/academy/plans/:id` → eliminación de un paquete.
  Future<void> deleteAcademyPlan(int id) {
    return retryWithBackoff(
      () async {
        await _dio.delete<void>('/admin/academy/plans/$id');
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /admin/academy/features` → catálogo completo de características.
  Future<List<AcademyFeatureAdmin>> getAdminAcademyFeatures() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/admin/academy/features',
        );
        final list = res.data!['features'] as List<dynamic>;
        return list
            .map((e) => AcademyFeatureAdmin.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/academy/features` → crear una característica.
  Future<AcademyFeatureAdmin> createAcademyFeature(
    Map<String, dynamic> feature,
  ) {
    return retryWithBackoff(
      () async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/admin/academy/features',
          data: feature,
        );
        return AcademyFeatureAdmin.fromJson(
          res.data!['feature'] as Map<String, dynamic>,
        );
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `PATCH /admin/academy/features/:id` → actualizar una característica.
  Future<AcademyFeatureAdmin> updateAcademyFeature(
    int id,
    Map<String, dynamic> delta,
  ) async {
    final res = await _dio.patch<Map<String, dynamic>>(
      '/admin/academy/features/$id',
      data: delta,
    );
    return AcademyFeatureAdmin.fromJson(
      res.data!['feature'] as Map<String, dynamic>,
    );
  }

  /// `DELETE /admin/academy/features/:id` → eliminar una característica.
  Future<void> deleteAcademyFeature(int id) {
    return retryWithBackoff(
      () async {
        await _dio.delete<void>('/admin/academy/features/$id');
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }
}

final academyRepositoryProvider = Provider<AcademyRepository>((ref) {
  return AcademyRepository(ref.watch(apiClientProvider));
});
