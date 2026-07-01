import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/user_admin.dart';

class AdminRepository {
  AdminRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /admin/users` → listado de todos los usuarios registrados.
  Future<List<UserAdmin>> getUsers() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/admin/users');
        final list = res.data!['users'] as List<dynamic>;
        return list
            .map((e) => UserAdmin.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /admin/users/{id}` → detalle de un usuario específico.
  Future<UserAdmin> getUser(String id) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/admin/users/$id');
        return UserAdmin.fromJson(res.data!['user'] as Map<String, dynamic>);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/users` → aprovisionar un usuario.
  Future<UserAdmin> createUser(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/users',
        data: data,
      );
      return UserAdmin.fromJson(res.data!['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /admin/users/{id}` → modificar campos de un usuario.
  Future<UserAdmin> updateUser(String id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/admin/users/$id',
        data: data,
      );
      return UserAdmin.fromJson(res.data!['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/users/{id}` → eliminación física/destructiva.
  Future<void> deleteUser(String id) async {
    try {
      await _dio.delete<void>('/admin/users/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AdminRepository(dio);
});
