import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/operations/data/operations_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late OperationsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = OperationsRepository(dio, retryBaseDelay: Duration.zero);
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

  Map<String, dynamic> equityOperationJson() => {
    'id': 'op-1',
    'allocationId': 'alloc-1',
    'accountType': 'equity',
    'ticker': 'AAPL',
    'openedAt': '2026-07-01T10:00:00Z',
    'quantity': 10.5,
    'buyPrice': 150.0,
    'limitPrice': 180.0,
    'soldAt': null,
    'sellPrice': null,
    'strategy': 'Buy & Hold',
    'notes': 'Some notes',
    'url': 'https://finance.yahoo.com/quote/AAPL',
    'createdAt': '2026-07-01T10:05:00Z',
    'updatedAt': '2026-07-01T10:05:00Z',
    'status': 'open',
    'totalInvested': 1575.0,
    'totalSale': null,
    'gainAmount': null,
    'gainPct': null,
  };

  Map<String, dynamic> optionsOperationJson() => {
    'id': 'op-2',
    'allocationId': 'alloc-2',
    'accountType': 'options',
    'ticker': 'AAPL',
    'openedAt': '2026-07-01T10:00:00Z',
    'quantity': 2.0,
    'buyPrice': 5.0,
    'limitPrice': null,
    'soldAt': '2026-07-02T15:00:00Z',
    'sellPrice': 8.0,
    'strategy': 'Covered Call',
    'notes': 'Option notes',
    'url': 'https://finance.yahoo.com/quote/AAPL/options',
    'createdAt': '2026-07-01T10:05:00Z',
    'updatedAt': '2026-07-02T15:05:00Z',
    'status': 'closed',
    'totalInvested': 1000.0,
    'totalSale': 1600.0,
    'gainAmount': 600.0,
    'gainPct': 60.0,
    'strike': 155.0,
    'expirationDate': '2026-07-17',
    'contractType': 'call',
  };

  group('getOperations', () {
    test(
      '200 con operaciones de activos y opciones → parsea ambas correctamente',
      () async {
        when(
          () => dio.get<Map<String, dynamic>>(
            '/operations',
            queryParameters: any(named: 'queryParameters'),
          ),
        ).thenAnswer(
          (_) async => ok({
            'operations': [equityOperationJson(), optionsOperationJson()],
          }),
        );

        final list = await repo.getOperations(
          allocationId: 'alloc-1',
          status: 'open',
        );

        expect(list, hasLength(2));

        final op1 = list[0];
        expect(op1.id, 'op-1');
        expect(op1.accountType, AccountType.equity);
        expect(op1.quantity, 10.5);
        expect(op1.buyPrice, 150.0);
        expect(op1.isOpen, isTrue);
        expect(op1.totalInvested, 1575.0);
        expect(op1.strike, isNull);

        final op2 = list[1];
        expect(op2.id, 'op-2');
        expect(op2.accountType, AccountType.options);
        expect(op2.quantity, 2.0);
        expect(op2.buyPrice, 5.0);
        expect(op2.isClosed, isTrue);
        expect(op2.totalInvested, 1000.0);
        expect(op2.totalSale, 1600.0);
        expect(op2.gainAmount, 600.0);
        expect(op2.gainPct, 60.0);
        expect(op2.strike, 155.0);
        expect(op2.expirationDate, '2026-07-17');
        expect(op2.contractType, 'call');
      },
    );

    test('reintenta ante 503 y resuelve en el 2º intento', () async {
      var calls = 0;
      when(
        () => dio.get<Map<String, dynamic>>(
          '/operations',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
        return ok({'operations': <dynamic>[]});
      });

      await repo.getOperations();

      expect(calls, 2);
    });
  });

  group('createOperation', () {
    test('envía payload y retorna la operación creada', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/operations',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok({'operation': equityOperationJson()}));

      final payload = {
        'allocationId': 'alloc-1',
        'ticker': 'AAPL',
        'quantity': 10.5,
        'buyPrice': 150.0,
      };
      final op = await repo.createOperation(payload);

      expect(op.id, 'op-1');
      verify(
        () => dio.post<Map<String, dynamic>>('/operations', data: payload),
      ).called(1);
    });

    test('422 error de validación → arroja ApiException', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/operations',
          data: any(named: 'data'),
        ),
      ).thenThrow(dioErr(422, 'VALIDATION_ERROR', 'Cantidad inválida'));

      await expectLater(
        repo.createOperation({}),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 422)
              .having((e) => e.message, 'message', 'Cantidad inválida'),
        ),
      );
    });
  });

  group('patchOperation', () {
    test('envía payload parcial y retorna la operación actualizada', () async {
      when(
        () => dio.patch<Map<String, dynamic>>(
          '/operations/op-1',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok({'operation': optionsOperationJson()}));

      final payload = {'soldAt': '2026-07-02T15:00:00Z', 'sellPrice': 8.0};
      final op = await repo.patchOperation('op-1', payload);

      expect(op.id, 'op-2');
      verify(
        () =>
            dio.patch<Map<String, dynamic>>('/operations/op-1', data: payload),
      ).called(1);
    });
  });

  group('deleteOperation', () {
    test('envía DELETE exitosamente', () async {
      when(
        () => dio.delete<Map<String, dynamic>>('/operations/op-1'),
      ).thenAnswer((_) async => ok({'deleted': true}));

      await repo.deleteOperation('op-1');

      verify(
        () => dio.delete<Map<String, dynamic>>('/operations/op-1'),
      ).called(1);
    });
  });
}
