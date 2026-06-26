import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/capital/data/capital_repository.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late CapitalRepository repo;

  setUp(() {
    dio = MockDio();
    repo = CapitalRepository(dio, retryBaseDelay: Duration.zero);
  });

  Response<Map<String, dynamic>> ok(
    Map<String, dynamic> data, {
    int status = 200,
  }) => Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: status,
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

  Map<String, dynamic> allocationJson() => {
    'id': 'alloc-1',
    'brokerId': 7,
    'brokerSlug': 'ibkr',
    'accountType': 'equity',
    'investmentPlanId': 3,
    'targetMonthlyPct': 2.5,
    'initialDeposit': 1000,
    'currency': 'USD',
  };

  group('getCapital', () {
    test('200 con capital y allocations → parsea todo', () async {
      when(() => dio.get<Map<String, dynamic>>('/capital')).thenAnswer(
        (_) async => ok({
          'capital': {'totalCapital': 5000, 'currency': 'USD'},
          'allocations': [allocationJson()],
          'totalAllocated': 1000,
          'available': 4000,
        }),
      );

      final overview = await repo.getCapital();

      expect(overview.capital!.totalCapital, 5000);
      expect(overview.capital!.currency, 'USD');
      expect(overview.allocations, hasLength(1));
      expect(overview.allocations.first.brokerId, 7);
      expect(overview.allocations.first.accountType, AccountType.equity);
      expect(overview.totalAllocated, 1000);
      expect(overview.available, 4000);
    });

    test('200 con capital null → hasCapital=false', () async {
      when(() => dio.get<Map<String, dynamic>>('/capital')).thenAnswer(
        (_) async => ok({
          'capital': null,
          'allocations': <dynamic>[],
          'totalAllocated': 0,
          'available': 0,
        }),
      );

      final overview = await repo.getCapital();

      expect(overview.capital, isNull);
      expect(overview.hasCapital, isFalse);
      expect(overview.allocations, isEmpty);
    });

    test('reintenta ante 503 y resuelve en el 2º intento', () async {
      var calls = 0;
      when(() => dio.get<Map<String, dynamic>>('/capital')).thenAnswer((
        _,
      ) async {
        calls++;
        if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
        return ok({
          'capital': null,
          'allocations': <dynamic>[],
          'totalAllocated': 0,
          'available': 0,
        });
      });

      await repo.getCapital();

      expect(calls, 2);
    });

    test('503 persistente → agota reintentos (3 llamadas)', () async {
      when(() => dio.get<Map<String, dynamic>>('/capital')).thenAnswer(
        (_) async => throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído'),
      );

      await expectLater(
        repo.getCapital(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
      verify(() => dio.get<Map<String, dynamic>>('/capital')).called(3);
    });
  });

  group('putCapital', () {
    test('envía body y parsea el capital', () async {
      when(
        () =>
            dio.put<Map<String, dynamic>>('/capital', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => ok({
          'capital': {'totalCapital': 8000, 'currency': 'USD'},
        }),
      );

      final capital = await repo.putCapital(
        totalCapital: 8000,
        currency: 'USD',
      );

      expect(capital.totalCapital, 8000);
      final captured =
          verify(
                () => dio.put<Map<String, dynamic>>(
                  '/capital',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;
      expect(captured['totalCapital'], 8000);
      expect(captured['currency'], 'USD');
    });

    test('409 → ApiException(409) con el message del servidor', () async {
      when(
        () =>
            dio.put<Map<String, dynamic>>('/capital', data: any(named: 'data')),
      ).thenAnswer(
        (_) async => throw dioErr(409, 'CONFLICT', 'Menor a lo asignado'),
      );

      await expectLater(
        repo.putCapital(totalCapital: 1),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.message, 'message', 'Menor a lo asignado'),
        ),
      );
    });
  });

  group('createAllocation', () {
    test('201 parsea la allocation y NUNCA envía accountType', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/capital/allocations',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => ok({'allocation': allocationJson()}, status: 201),
      );

      final allocation = await repo.createAllocation(
        brokerId: 7,
        investmentPlanId: 3,
        initialDeposit: 1000,
        currency: 'USD',
      );

      expect(allocation.id, 'alloc-1');

      final captured =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  '/capital/allocations',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;
      expect(captured['brokerId'], 7);
      expect(captured['investmentPlanId'], 3);
      expect(captured['initialDeposit'], 1000);
      expect(captured['currency'], 'USD');
      // accountType lo deriva el backend del plan: NUNCA va en el body.
      expect(captured.containsKey('accountType'), isFalse);
    });

    test('409 duplicado / supera capital → ApiException(409)', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/capital/allocations',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => throw dioErr(409, 'CONFLICT', 'Duplicado'));

      await expectLater(
        repo.createAllocation(
          brokerId: 1,
          investmentPlanId: 1,
          initialDeposit: 1,
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 409)),
      );
    });

    test('422 entrada inválida → ApiException(422)', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/capital/allocations',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => throw dioErr(422, 'VALIDATION_ERROR', 'Moneda inválida'),
      );

      await expectLater(
        repo.createAllocation(
          brokerId: 1,
          investmentPlanId: 1,
          initialDeposit: 1,
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 422)),
      );
    });

    test('NO reintenta ante 503 (es POST): una sola llamada', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/capital/allocations',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído'),
      );

      await expectLater(
        repo.createAllocation(
          brokerId: 1,
          investmentPlanId: 1,
          initialDeposit: 1,
        ),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/capital/allocations',
          data: any(named: 'data'),
        ),
      ).called(1);
    });
  });

  group('patchAllocation', () {
    test('envía sólo los campos provistos', () async {
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/capital/allocations/alloc-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok({'allocation': allocationJson()}));

      await repo.patchAllocation('alloc-1', initialDeposit: 2000);

      final captured =
          verify(
                () => dio.patch<Map<String, dynamic>>(
                  '/capital/allocations/alloc-1',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;
      expect(captured['initialDeposit'], 2000);
      expect(captured.containsKey('investmentPlanId'), isFalse);
      expect(captured.containsKey('currency'), isFalse);
    });
  });

  group('deleteAllocation', () {
    test('llama DELETE en la ruta de la allocation', () async {
      when(
        () => dio.delete<Map<String, dynamic>>('/capital/allocations/alloc-1'),
      ).thenAnswer((_) async => ok({'deleted': true}));

      await repo.deleteAllocation('alloc-1');

      verify(
        () => dio.delete<Map<String, dynamic>>('/capital/allocations/alloc-1'),
      ).called(1);
    });
  });
}
