import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/tickers/data/ticker_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late TickerRepository repo;

  setUp(() {
    dio = MockDio();
    repo = TickerRepository(dio, retryBaseDelay: Duration.zero);
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

  Map<String, dynamic> tickerJson(String symbol, {bool isFavorite = true}) => {
    'id': 1,
    'symbol': symbol,
    'name': '$symbol Inc.',
    'assetClass': 'stock',
    'financials': <String, dynamic>{},
    'createdAt': '2026-01-01T00:00:00Z',
    'updatedAt': '2026-01-01T00:00:00Z',
    'isFavorite': isFavorite,
  };

  group('addFavorite', () {
    test('PUT al endpoint correcto y devuelve favorite=true', () async {
      when(
        () => dio.put<Map<String, dynamic>>('/tickers/AAPL/favorite'),
      ).thenAnswer((_) async => ok({'favorite': true}));

      final result = await repo.addFavorite('AAPL');

      expect(result, isTrue);
      verify(
        () => dio.put<Map<String, dynamic>>('/tickers/AAPL/favorite'),
      ).called(1);
    });

    test('reintenta ante 503 y resuelve en el 2º intento', () async {
      var calls = 0;
      when(
        () => dio.put<Map<String, dynamic>>('/tickers/AAPL/favorite'),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
        return ok({'favorite': true});
      });

      await repo.addFavorite('AAPL');

      expect(calls, 2);
    });

    test('500 INTERNAL_ERROR → ApiException sin reintentar', () async {
      var calls = 0;
      when(
        () => dio.put<Map<String, dynamic>>('/tickers/AAPL/favorite'),
      ).thenAnswer((_) async {
        calls++;
        throw dioErr(500, 'INTERNAL_ERROR', 'Falló algo interno');
      });

      await expectLater(
        repo.addFavorite('AAPL'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 500)),
      );
      // Un 500 NO se reintenta: una sola llamada.
      expect(calls, 1);
    });

    test('404 símbolo inexistente → ApiException sin reintentar', () async {
      var calls = 0;
      when(
        () => dio.put<Map<String, dynamic>>('/tickers/ZZZ/favorite'),
      ).thenAnswer((_) async {
        calls++;
        throw dioErr(404, 'NOT_FOUND', 'No existe');
      });

      await expectLater(
        repo.addFavorite('ZZZ'),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 404)),
      );
      expect(calls, 1);
    });
  });

  group('removeFavorite', () {
    test('DELETE al endpoint correcto y devuelve favorite=false', () async {
      when(
        () => dio.delete<Map<String, dynamic>>('/tickers/AAPL/favorite'),
      ).thenAnswer((_) async => ok({'favorite': false}));

      final result = await repo.removeFavorite('AAPL');

      expect(result, isFalse);
      verify(
        () => dio.delete<Map<String, dynamic>>('/tickers/AAPL/favorite'),
      ).called(1);
    });
  });

  group('getFavorites', () {
    test('manda favorite=true y parsea la lista de tickers', () async {
      when(
        () => dio.get<Map<String, dynamic>>(
          '/tickers',
          queryParameters: any(named: 'queryParameters'),
        ),
      ).thenAnswer(
        (_) async => ok({
          'tickers': [tickerJson('AAPL'), tickerJson('TSLA')],
          'pagination': {'page': 1, 'limit': 100, 'total': 2},
        }),
      );

      final favorites = await repo.getFavorites();

      expect(favorites, hasLength(2));
      expect(favorites.first.symbol, 'AAPL');
      expect(favorites.first.isFavorite, isTrue);
      final captured = verify(
        () => dio.get<Map<String, dynamic>>(
          '/tickers',
          queryParameters: captureAny(named: 'queryParameters'),
        ),
      ).captured.single as Map<String, dynamic>;
      expect(captured['favorite'], true);
    });
  });
}
