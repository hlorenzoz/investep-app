import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/auth/data/auth_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AuthRepository repo;

  // El backoff usa Duration.zero para que los tests no esperen de verdad.
  setUp(() {
    dio = MockDio();
    repo = AuthRepository(dio, retryBaseDelay: Duration.zero);
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

  Map<String, dynamic> meBody({required bool mustReset}) => {
    'user': {
      'id': 'uuid-1',
      'email': 'user@example.com',
      'mustResetPassword': mustReset,
    },
  };

  group('getMe', () {
    test('200 → parsea el AuthUser con el flag', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/auth/me'),
      ).thenAnswer((_) async => ok(meBody(mustReset: true)));

      final user = await repo.getMe();

      expect(user.id, 'uuid-1');
      expect(user.email, 'user@example.com');
      expect(user.mustResetPassword, isTrue);
    });

    test('reintenta ante 503 y resuelve en el 2º intento', () async {
      var calls = 0;
      when(() => dio.get<Map<String, dynamic>>('/auth/me')).thenAnswer((
        _,
      ) async {
        calls++;
        if (calls == 1) {
          throw dioErr(503, 'SERVICE_UNAVAILABLE', 'Supabase caído');
        }
        return ok(meBody(mustReset: false));
      });

      final user = await repo.getMe();

      expect(calls, 2);
      expect(user.mustResetPassword, isFalse);
    });

    test(
      '503 persistente → agota reintentos y lanza ApiException(503)',
      () async {
        when(() => dio.get<Map<String, dynamic>>('/auth/me')).thenAnswer(
          (_) async =>
              throw dioErr(503, 'SERVICE_UNAVAILABLE', 'Supabase caído'),
        );

        await expectLater(
          repo.getMe(),
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
        );
        verify(() => dio.get<Map<String, dynamic>>('/auth/me')).called(3);
      },
    );

    test(
      '401 NO se reintenta: lanza ApiException(401) en el 1º intento',
      () async {
        when(() => dio.get<Map<String, dynamic>>('/auth/me')).thenAnswer(
          (_) async => throw dioErr(401, 'UNAUTHORIZED', 'Token inválido'),
        );

        await expectLater(
          repo.getMe(),
          throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
        );
        verify(() => dio.get<Map<String, dynamic>>('/auth/me')).called(1);
      },
    );
  });

  group('changePassword', () {
    test('envía body { newPassword } y NUNCA userId; parsea el 200', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/change-password',
          data: any(named: 'data'),
        ),
      ).thenAnswer((_) async => ok(meBody(mustReset: false)));

      final user = await repo.changePassword('nuevaClave123');

      final captured =
          verify(
                () => dio.post<Map<String, dynamic>>(
                  '/auth/change-password',
                  data: captureAny(named: 'data'),
                ),
              ).captured.single
              as Map;

      expect(captured, {'newPassword': 'nuevaClave123'});
      expect(captured.containsKey('userId'), isFalse);
      expect(user.mustResetPassword, isFalse);
    });

    test('400 → ApiException con el message del servidor', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/change-password',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async =>
            throw dioErr(400, 'VALIDATION_ERROR', 'Contraseña muy débil'),
      );

      await expectLater(
        repo.changePassword('x'),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 400)
              .having((e) => e.message, 'message', 'Contraseña muy débil'),
        ),
      );
    });

    test('NO reintenta ante 503 (es POST): una sola llamada', () async {
      when(
        () => dio.post<Map<String, dynamic>>(
          '/auth/change-password',
          data: any(named: 'data'),
        ),
      ).thenAnswer(
        (_) async => throw dioErr(503, 'SERVICE_UNAVAILABLE', 'Reintentá'),
      );

      await expectLater(
        repo.changePassword('x'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
      verify(
        () => dio.post<Map<String, dynamic>>(
          '/auth/change-password',
          data: any(named: 'data'),
        ),
      ).called(1);
    });
  });
}
