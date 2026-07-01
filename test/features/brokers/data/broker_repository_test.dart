import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/brokers/data/broker_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late BrokerRepository repo;

  setUp(() {
    dio = MockDio();
    repo = BrokerRepository(dio, retryBaseDelay: Duration.zero);
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

  test('200 → parsea la lista de brokers (incluye urlSecondary)', () async {
    when(() => dio.get<Map<String, dynamic>>('/brokers')).thenAnswer(
      (_) async => ok({
        'brokers': [
          {
            'id': 2,
            'slug': 'interactive-brokers',
            'name': 'Interactive Brokers',
            'url': 'https://www.interactivebrokers.com/',
            'urlSecondary': 'https://www.interactivebrokers.ie/',
            'logo': 'https://x/logo.svg',
            'favicon': 'https://x/favicon.png',
            'icon': 'https://x/icon.png',
          },
        ],
      }),
    );

    final brokers = await repo.getBrokers();

    expect(brokers, hasLength(1));
    final b = brokers.first;
    expect(b.id, 2);
    expect(b.slug, 'interactive-brokers');
    expect(b.name, 'Interactive Brokers');
    expect(b.url, 'https://www.interactivebrokers.com/');
    expect(b.urlSecondary, 'https://www.interactivebrokers.ie/');
    expect(b.logo, 'https://x/logo.svg');
    expect(b.favicon, 'https://x/favicon.png');
    expect(b.icon, 'https://x/icon.png');
  });

  test(
    '200 → parseo defensivo: assets nullables ausentes/null → null',
    () async {
      when(() => dio.get<Map<String, dynamic>>('/brokers')).thenAnswer(
        (_) async => ok({
          'brokers': [
            {
              'id': 5,
              'slug': 'minimal',
              'name': 'Minimal Broker',
              // sin url/urlSecondary/logo/favicon/icon
            },
            {
              'id': 6,
              'slug': 'nulls',
              'name': 'Null Broker',
              'url': null,
              'urlSecondary': null,
              'logo': null,
              'favicon': null,
              'icon': null,
            },
          ],
        }),
      );

      final brokers = await repo.getBrokers();

      expect(brokers, hasLength(2));
      for (final b in brokers) {
        expect(b.url, isNull);
        expect(b.urlSecondary, isNull);
        expect(b.logo, isNull);
        expect(b.favicon, isNull);
        expect(b.icon, isNull);
      }
    },
  );

  test('401 → ApiException(401), una sola llamada (sin retry)', () async {
    when(() => dio.get<Map<String, dynamic>>('/brokers')).thenAnswer(
      (_) async => throw dioErr(401, 'UNAUTHORIZED', 'Token inválido'),
    );

    await expectLater(
      repo.getBrokers(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    verify(() => dio.get<Map<String, dynamic>>('/brokers')).called(1);
  });

  test(
    '404 / no implementado → ApiException (el wizard bloquea, NO hardcodea)',
    () async {
      when(() => dio.get<Map<String, dynamic>>('/brokers')).thenAnswer(
        (_) async => throw dioErr(404, 'NOT_FOUND', 'Endpoint no disponible'),
      );

      await expectLater(
        repo.getBrokers(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      // 404 no es transitorio: una sola llamada, sin reintentos.
      verify(() => dio.get<Map<String, dynamic>>('/brokers')).called(1);
    },
  );

  test('reintenta ante 503 y resuelve en el 2º intento', () async {
    var calls = 0;
    when(() => dio.get<Map<String, dynamic>>('/brokers')).thenAnswer((_) async {
      calls++;
      if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
      return ok({'brokers': <dynamic>[]});
    });

    final brokers = await repo.getBrokers();

    expect(calls, 2);
    expect(brokers, isEmpty);
  });

  group('CRUD operations', () {
    test(
      'createBroker → envia POST a /admin/brokers y retorna el Broker creado',
      () async {
        final payload = {
          'slug': 'test-broker',
          'name': 'Test Broker',
          'url': 'https://test.com',
        };

        when(
          () => dio.post<Map<String, dynamic>>('/admin/brokers', data: payload),
        ).thenAnswer(
          (_) async => ok({
            'broker': {
              'id': 10,
              'slug': 'test-broker',
              'name': 'Test Broker',
              'url': 'https://test.com',
              'urlSecondary': null,
              'logo': null,
              'favicon': null,
              'icon': null,
            },
          }),
        );

        final broker = await repo.createBroker(payload);

        expect(broker.id, 10);
        expect(broker.slug, 'test-broker');
        expect(broker.name, 'Test Broker');
        expect(broker.url, 'https://test.com');
        verify(
          () => dio.post<Map<String, dynamic>>('/admin/brokers', data: payload),
        ).called(1);
      },
    );

    test(
      'updateBroker → envia PATCH a /admin/brokers/{id} y retorna el Broker actualizado',
      () async {
        final payload = {'name': 'Updated Broker'};

        when(
          () => dio.patch<Map<String, dynamic>>(
            '/admin/brokers/10',
            data: payload,
          ),
        ).thenAnswer(
          (_) async => ok({
            'broker': {
              'id': 10,
              'slug': 'test-broker',
              'name': 'Updated Broker',
              'url': 'https://test.com',
              'urlSecondary': null,
              'logo': null,
              'favicon': null,
              'icon': null,
            },
          }),
        );

        final broker = await repo.updateBroker(10, payload);

        expect(broker.id, 10);
        expect(broker.name, 'Updated Broker');
        verify(
          () => dio.patch<Map<String, dynamic>>(
            '/admin/brokers/10',
            data: payload,
          ),
        ).called(1);
      },
    );

    test('deleteBroker → envia DELETE a /admin/brokers/{id}', () async {
      when(() => dio.delete<void>('/admin/brokers/10')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
        ),
      );

      await repo.deleteBroker(10);

      verify(() => dio.delete<void>('/admin/brokers/10')).called(1);
    });
  });
}
