import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/retry.dart';
import '../domain/compound_interest_calculator.dart';

/// Capa de datos de la proyección "Desempeño vs Plan" (la calcula la API, no el cliente).
class ProjectionRepository {
  ProjectionRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /projections?planId=&baseAmount=&startDate=&grouping=[&years=]`
  /// Devuelve la serie ya calculada. 503 (transitorio) se reintenta con backoff.
  Future<List<CompoundInterestPeriodResult>> getProjection({
    required int planId,
    required double baseAmount,
    required DateTime startDate,
    required CompoundInterestGrouping grouping,
    int? years,
  }) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/projections',
          queryParameters: {
            'planId': planId,
            'baseAmount': baseAmount,
            'startDate': _isoDate(startDate),
            'grouping': grouping.name,
            'years':? years,
          },
        );
        final periods = res.data!['periods'] as List<dynamic>;
        return periods
            .map((e) => _periodFromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `YYYY-MM-DD`.
  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  static CompoundInterestPeriodResult _periodFromJson(Map<String, dynamic> j) {
    return CompoundInterestPeriodResult(
      periodIndex: (j['periodIndex'] as num).toInt(),
      label: j['label'] as String,
      date: DateTime.parse(j['date'] as String),
      startBalance: (j['startBalance'] as num).toDouble(),
      yieldAmount: (j['yieldAmount'] as num).toDouble(),
      endBalance: (j['endBalance'] as num).toDouble(),
    );
  }
}

final projectionRepositoryProvider = Provider<ProjectionRepository>((ref) {
  return ProjectionRepository(ref.watch(apiClientProvider));
});
