import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';

void main() {
  final req = RequestOptions(path: '/auth/change-password');

  DioException withResponse(int status, dynamic data) => DioException(
    requestOptions: req,
    response: Response(requestOptions: req, statusCode: status, data: data),
    type: DioExceptionType.badResponse,
  );

  group('ApiException.fromDioException', () {
    test('parsea el envelope { error: { code, message } }', () {
      final e = ApiException.fromDioException(
        withResponse(400, {
          'error': {
            'code': 'VALIDATION_ERROR',
            'message': 'La contraseña debe tener al menos 8 caracteres',
          },
        }),
      );

      expect(e.status, 400);
      expect(e.code, 'VALIDATION_ERROR');
      expect(e.message, 'La contraseña debe tener al menos 8 caracteres');
    });

    test('mapea 401 UNAUTHORIZED', () {
      final e = ApiException.fromDioException(
        withResponse(401, {
          'error': {'code': 'UNAUTHORIZED', 'message': 'Token inválido'},
        }),
      );

      expect(e.status, 401);
      expect(e.code, 'UNAUTHORIZED');
      expect(e.isRetryable, isFalse);
    });

    test('mapea 503 SERVICE_UNAVAILABLE como reintentable', () {
      final e = ApiException.fromDioException(
        withResponse(503, {
          'error': {'code': 'SERVICE_UNAVAILABLE', 'message': 'Reintentá'},
        }),
      );

      expect(e.status, 503);
      expect(e.code, 'SERVICE_UNAVAILABLE');
      expect(e.isRetryable, isTrue);
    });

    test('conserva el status cuando la respuesta no trae envelope', () {
      final e = ApiException.fromDioException(
        withResponse(500, {'foo': 'bar'}),
      );

      expect(e.status, 500);
      expect(e.code, 'UNKNOWN');
    });

    test('sin respuesta (timeout / red caída) → 503 reintentable', () {
      final e = ApiException.fromDioException(
        DioException(
          requestOptions: req,
          type: DioExceptionType.connectionTimeout,
        ),
      );

      expect(e.status, 503);
      expect(e.code, 'SERVICE_UNAVAILABLE');
      expect(e.isRetryable, isTrue);
    });
  });

  group('ApiException.isRetryable', () {
    test('true sólo para transitorios reales (503/429)', () {
      expect(const ApiException(503, 'X', 'm').isRetryable, isTrue);
      expect(const ApiException(429, 'X', 'm').isRetryable, isTrue);
    });

    test('500 NO se reintenta (error interno, reintentar no lo arregla)', () {
      expect(const ApiException(500, 'INTERNAL_ERROR', 'm').isRetryable, isFalse);
    });

    test('false para 4xx no transitorios (400/401/404/422)', () {
      expect(const ApiException(400, 'X', 'm').isRetryable, isFalse);
      expect(const ApiException(401, 'X', 'm').isRetryable, isFalse);
      expect(const ApiException(404, 'X', 'm').isRetryable, isFalse);
      expect(const ApiException(422, 'X', 'm').isRetryable, isFalse);
    });
  });
}
