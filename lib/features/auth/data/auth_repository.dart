import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/auth_user.dart';

/// Capa de datos de autenticación contra la API REST de Investep.
///
/// La API NO tiene endpoint de login (eso va directo contra Supabase Auth);
/// acá sólo viven los endpoints protegidos que SÍ expone la API bajo el tag
/// `Auth`: `GET /auth/me` y `POST /auth/change-password`. El header
/// `Authorization: Bearer ...` lo adjunta el interceptor de Dio.
class AuthRepository {
  AuthRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;

  /// Delay base del backoff exponencial. Inyectable para que los tests usen
  /// `Duration.zero` y no esperen de verdad.
  final Duration _retryBaseDelay;

  static const _maxAttempts = 3;

  /// `GET /auth/me` → usuario autenticado (con el flag `mustResetPassword`).
  ///
  /// Reintenta con backoff exponencial ante errores transitorios (503 / sin
  /// respuesta). Es idempotente, así que el retry es seguro. Un 401 (token
  /// muerto) NO se reintenta: se propaga como [ApiException] para que la capa
  /// superior dispare el re-login.
  Future<AuthUser> getMe() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/auth/me');
        return AuthUser.fromJson(res.data!);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /auth/change-password` con body `{ newPassword }`.
  ///
  /// IMPORTANTE: NO se manda `userId` — el servidor lo toma del token. En un
  /// 200 el backend revoca TODAS las sesiones (incluida la actual), así que el
  /// access token con el que se llamó queda muerto: la capa superior DEBE
  /// limpiar la sesión local y forzar re-login.
  ///
  /// SIN auto-retry: es un POST y el reintento lo dispara el usuario re-enviando
  /// el formulario (ver tabla de errores en AGENTS §4).
  Future<AuthUser> changePassword(String newPassword) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/auth/change-password',
        data: {'newPassword': newPassword},
      );
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /auth/profile` con body `{ fullName, phone, country }`.
  /// Permite a cualquier usuario autenticado actualizar su propio perfil.
  Future<AuthUser> updateProfile(Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/auth/profile',
        data: data,
      );
      return AuthUser.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return AuthRepository(dio);
});
