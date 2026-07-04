import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/relations/data/relations_repository.dart';
import 'package:investep_app/features/relations/domain/relations_overview.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late RelationsRepository repo;

  setUp(() {
    dio = MockDio();
    repo = RelationsRepository(dio, retryBaseDelay: Duration.zero);
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

  Map<String, dynamic> overviewJson() => {
    'assets': [
      {
        'symbol': 'TSLA',
        'name': 'Tesla, Inc.',
        'assetClass': 'stock',
        'longEtfs': [
          {
            'symbol': 'TSLL',
            'name': 'Direxion Daily TSLA Bull 2X',
            'relationType': 'x2',
            'multiplier': 2.0,
          },
        ],
        'inverseEtfs': [
          {
            'symbol': 'TSLS',
            'name': 'AXS TSLA Bear Daily',
            'relationType': 'inverso',
            'multiplier': -1.0,
          },
        ],
      },
    ],
    'sectors': [
      {
        'etf': 'XLK',
        'sectorName': 'Technology',
        'inverseEtfs': [
          {
            'symbol': 'TECS',
            'name': 'Direxion Daily Tech Bear 3X',
            'relationType': 'inverso',
            'multiplier': -3.0,
          },
        ],
      },
    ],
  };

  group('fetchRelationsOverview', () {
    test('200 → llama al endpoint correcto y parsea la respuesta', () async {
      when(
        () => dio.get<Map<String, dynamic>>('/tickers/relations-overview'),
      ).thenAnswer((_) async => ok(overviewJson()));

      final overview = await repo.fetchRelationsOverview();

      expect(overview, isA<RelationsOverview>());
      expect(overview.assets.single.symbol, 'TSLA');
      expect(overview.sectors.single.etf, 'XLK');
      verify(
        () => dio.get<Map<String, dynamic>>('/tickers/relations-overview'),
      ).called(1);
    });

    test('reintenta ante 503 y resuelve en el 2º intento', () async {
      var calls = 0;
      when(
        () => dio.get<Map<String, dynamic>>('/tickers/relations-overview'),
      ).thenAnswer((_) async {
        calls++;
        if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
        return ok(overviewJson());
      });

      await repo.fetchRelationsOverview();

      expect(calls, 2);
    });

    test('401 → propaga ApiException sin reintentar', () async {
      var calls = 0;
      when(
        () => dio.get<Map<String, dynamic>>('/tickers/relations-overview'),
      ).thenAnswer((_) async {
        calls++;
        throw dioErr(401, 'UNAUTHORIZED', 'Token inválido');
      });

      await expectLater(
        repo.fetchRelationsOverview(),
        throwsA(
          isA<ApiException>().having((e) => e.status, 'status', 401),
        ),
      );
      expect(calls, 1);
    });
  });
}
