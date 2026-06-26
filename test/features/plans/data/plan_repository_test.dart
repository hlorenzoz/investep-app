import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/plans/data/plan_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late PlanRepository repo;

  setUp(() {
    dio = MockDio();
    repo = PlanRepository(dio, retryBaseDelay: Duration.zero);
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

  test('manda locale y accountType como query params y parsea', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/plans',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => ok({
        'locale': 'es',
        'plans': [
          {
            'id': 3,
            'accountType': 'equity',
            'targetMonthlyPct': 2.5,
            'label': 'Conservador',
          },
          {
            'id': 4,
            'accountType': 'equity',
            'targetMonthlyPct': 5,
            'label': null,
          },
        ],
      }),
    );

    final plans = await repo.getPlans(
      locale: 'es',
      accountType: AccountType.equity,
    );

    expect(plans, hasLength(2));
    expect(plans.first.id, 3);
    expect(plans.first.targetMonthlyPct, 2.5);
    expect(plans.first.label, 'Conservador');
    expect(plans[1].label, isNull);

    final captured =
        verify(
              () => dio.get<Map<String, dynamic>>(
                '/plans',
                queryParameters: captureAny(named: 'queryParameters'),
              ),
            ).captured.single
            as Map;
    expect(captured['locale'], 'es');
    expect(captured['accountType'], 'equity');
  });

  test('401 → ApiException(401), una sola llamada (sin retry)', () async {
    when(
      () => dio.get<Map<String, dynamic>>(
        '/plans',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer(
      (_) async => throw dioErr(401, 'UNAUTHORIZED', 'Token inválido'),
    );

    await expectLater(
      repo.getPlans(locale: 'es', accountType: AccountType.equity),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    verify(
      () => dio.get<Map<String, dynamic>>(
        '/plans',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).called(1);
  });

  test('reintenta ante 503', () async {
    var calls = 0;
    when(
      () => dio.get<Map<String, dynamic>>(
        '/plans',
        queryParameters: any(named: 'queryParameters'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
      return ok({'locale': 'es', 'plans': <dynamic>[]});
    });

    await repo.getPlans(locale: 'es', accountType: AccountType.options);

    expect(calls, 2);
  });
}
