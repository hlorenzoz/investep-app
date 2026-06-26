import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/retry.dart';
import '../../capital/domain/account_type.dart';
import '../domain/investment_plan.dart';

/// Capa de datos de planes de inversión.
class PlanRepository {
  PlanRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /plans?locale=&accountType=` → planes filtrados por tipo de cuenta.
  Future<List<InvestmentPlan>> getPlans({
    required String locale,
    required AccountType accountType,
  }) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/plans',
          queryParameters: {
            'locale': locale,
            'accountType': accountType.toApi(),
          },
        );
        final list = res.data!['plans'] as List<dynamic>;
        return list
            .map((e) => InvestmentPlan.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }
}

final planRepositoryProvider = Provider<PlanRepository>((ref) {
  return PlanRepository(ref.watch(apiClientProvider));
});
