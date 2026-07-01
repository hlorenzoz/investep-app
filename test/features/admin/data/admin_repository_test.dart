import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/admin/data/admin_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late AdminRepository repo;

  setUp(() {
    dio = MockDio();
    repo = AdminRepository(dio, retryBaseDelay: Duration.zero);
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

  final userRaw = {
    'id': 'u-1',
    'email': 'admin@test.com',
    'role': 'admin',
    'fullName': 'Test Admin',
    'createdAt': '2026-07-01T00:00:00Z',
    'mustResetPassword': false,
  };

  group('getUsers', () {
    test('200 → parsea lista de usuarios correctamente', () async {
      when(() => dio.get<Map<String, dynamic>>('/admin/users')).thenAnswer(
        (_) async => ok({
          'users': [userRaw]
        }),
      );

      final users = await repo.getUsers();
      expect(users.length, 1);
      expect(users[0].email, 'admin@test.com');
      expect(users[0].role, 'admin');
    });

    test('503 transitorio → reintenta y arroja error tras 3 intentos', () async {
      when(() => dio.get<Map<String, dynamic>>('/admin/users')).thenThrow(
        dioErr(503, 'SERVICE_UNAVAILABLE', 'Backend temporalmente inactivo'),
      );

      await expectLater(
        repo.getUsers(),
        throwsA(isA<ApiException>().having((e) => e.status, 'status', 503)),
      );
      verify(() => dio.get<Map<String, dynamic>>('/admin/users')).called(3);
    });
  });

  group('getUser', () {
    test('200 → parsea el detalle del usuario', () async {
      when(() => dio.get<Map<String, dynamic>>('/admin/users/u-1')).thenAnswer(
        (_) async => ok({'user': userRaw}),
      );

      final user = await repo.getUser('u-1');
      expect(user.id, 'u-1');
      expect(user.fullName, 'Test Admin');
    });
  });

  group('createUser', () {
    test('POST exitoso → parsea el usuario creado', () async {
      final input = {
        'email': 'new@test.com',
        'fullName': 'New',
        'role': 'user',
      };
      when(() => dio.post<Map<String, dynamic>>('/admin/users', data: input))
          .thenAnswer((_) async => ok({'user': userRaw}));

      final created = await repo.createUser(input);
      expect(created.id, 'u-1');
    });

    test('POST falla con 409 → propaga ApiException', () async {
      final input = {'email': 'dup@test.com'};
      when(() => dio.post<Map<String, dynamic>>('/admin/users', data: input))
          .thenThrow(dioErr(409, 'CONFLICT', 'Email ya en uso'));

      await expectLater(
        repo.createUser(input),
        throwsA(
          isA<ApiException>()
              .having((e) => e.status, 'status', 409)
              .having((e) => e.message, 'message', 'Email ya en uso'),
        ),
      );
    });
  });

  group('updateUser', () {
    test('PATCH exitoso → retorna usuario modificado', () async {
      final updateData = {'fullName': 'Name changed'};
      when(() => dio.patch<Map<String, dynamic>>('/admin/users/u-1', data: updateData))
          .thenAnswer((_) async => ok({'user': userRaw}));

      final updated = await repo.updateUser('u-1', updateData);
      expect(updated.id, 'u-1');
    });
  });

  group('deleteUser', () {
    test('DELETE exitoso → completa sin errores', () async {
      when(() => dio.delete<void>('/admin/users/u-1')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/'),
          statusCode: 200,
        ),
      );

      await expectLater(repo.deleteUser('u-1'), completes);
    });
  });
}
