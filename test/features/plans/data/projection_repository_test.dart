import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/plans/data/projection_repository.dart';
import 'package:investep_app/features/plans/domain/compound_interest_calculator.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late ProjectionRepository repo;

  setUp(() {
    dio = MockDio();
    repo = ProjectionRepository(dio, retryBaseDelay: Duration.zero);
  });

  Response<Map<String, dynamic>> ok(Map<String, dynamic> data) => Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: 200,
    data: data,
  );

  DioException dioErr(int status, String code, String message) => DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: status,
      data: {
        'error': {'code': code, 'message': message},
      },
    ),
  );

  test('manda params requeridos y parsea periods correctamente', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/projections',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => ok({
        'planId': 3,
        'accountType': 'equity',
        'grouping': 'monthly',
        'periods': [
          {
            'periodIndex': 1,
            'label': 'Jul 26',
            'date': '2026-07-01',
            'startBalance': 15000,
            'yieldAmount': 3750,
            'endBalance': 18750,
          },
          {
            'periodIndex': 2,
            'label': 'Ago 26',
            'date': '2026-08-01',
            'startBalance': 18750,
            'yieldAmount': 4687.5,
            'endBalance': 23437.5,
          }
        ],
      }),
    );

    final result = await repo.getProjection(
      planId: 3,
      baseAmount: 15000,
      startDate: DateTime(2026, 7, 1),
      grouping: CompoundInterestGrouping.monthly,
    );

    expect(result, hasLength(2));
    expect(result.first.periodIndex, 1);
    expect(result.first.label, 'Jul 26');
    expect(result.first.date, DateTime(2026, 7, 1));
    expect(result.first.startBalance, 15000.0);
    expect(result.first.yieldAmount, 3750.0);
    expect(result.first.endBalance, 18750.0);

    expect(result[1].periodIndex, 2);
    expect(result[1].label, 'Ago 26');
    expect(result[1].date, DateTime(2026, 8, 1));
    expect(result[1].startBalance, 18750.0);
    expect(result[1].yieldAmount, 4687.5);
    expect(result[1].endBalance, 23437.5);

    final captured =
        verify(
          () => dio.get<Map<String, dynamic>>(
            '/projections',
            queryParameters: captureAny(named: 'queryParameters'),
          ),
        ).captured.single as Map;
    expect(captured['planId'], 3);
    expect(captured['baseAmount'], 15000.0);
    expect(captured['startDate'], '2026-07-01');
    expect(captured['grouping'], 'monthly');
  });

  test('401 → ApiException(401), sin retry', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/projections',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => throw dioErr(401, 'UNAUTHORIZED', 'Token inválido'),
    );

    await expectLater(
      repo.getProjection(
        planId: 3,
        baseAmount: 1000,
        startDate: DateTime.now(),
        grouping: CompoundInterestGrouping.daily,
      ),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/projections',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).called(1);
  });

  test('reintenta ante 503', () async {
    var calls = 0;
    when(
      () => dio.get<Map<String, dynamic>>(
        '/projections',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
      return ok({
        'planId': 3,
        'periods': <dynamic>[],
      });
    });

    await repo.getProjection(
      planId: 3,
      baseAmount: 1000,
      startDate: DateTime.now(),
      grouping: CompoundInterestGrouping.yearly,
    );

    expect(calls, 2);
  });
}
