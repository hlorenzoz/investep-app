import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import '../../../core/network/api_client.dart';
import '../../../core/providers/supabase_provider.dart';
import '../../../core/storage/secure_session_store.dart';
import '../domain/auth_user.dart';

/// Estados posibles de la autenticación.
sealed class LoginState {
  const LoginState();
}

class LoginInitial extends LoginState {
  const LoginInitial();
}

class LoginLoading extends LoginState {
  const LoginLoading();
}

class LoginSuccess extends LoginState {
  final AuthUser user;
  const LoginSuccess(this.user);
}

class LoginFailure extends LoginState {
  final String message;
  const LoginFailure(this.message);
}

/// Controlador Riverpod sin code-gen que maneja el flujo de login.
class LoginController extends Notifier<LoginState> {
  @override
  LoginState build() => const LoginInitial();

  /// Reinicia el estado del login al inicial (útil para re-testear).
  void reset() {
    state = const LoginInitial();
  }

  /// Intenta autenticar al usuario usando el flujo de dos patas:
  /// 1. Autenticación contra Supabase Auth.
  /// 2. Guardar el token de acceso obtenido en el almacenamiento seguro.
  /// 3. Validar el token contra el endpoint `/auth/me` de la API REST.
  Future<void> login(String email, String password) async {
    state = const LoginLoading();

    try {
      final supabaseClient = ref.read(supabaseClientProvider);
      final sessionStore = ref.read(secureSessionStoreProvider);

      // Pata 1: Iniciar sesión en Supabase
      final response = await supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final session = response.session;
      if (session == null) {
        state = const LoginFailure(
          'Error: No se pudo obtener la sesión de Supabase.',
        );
        return;
      }

      final accessToken = session.accessToken;

      // Pata 2: Guardar el token en el almacenamiento seguro para que el interceptor de Dio lo lea
      await sessionStore.saveSession(accessToken);

      // Pata 3: Validar contra la API de Investep
      final dio = ref.read(apiClientProvider);

      // Realizamos el request. El interceptor agregará automáticamente el Header Authorization.
      final apiResponse = await dio.get<Map<String, dynamic>>('/auth/me');

      if (apiResponse.statusCode == 200) {
        final userData = apiResponse.data as Map<String, dynamic>;
        final user = AuthUser.fromJson(userData);
        state = LoginSuccess(user);
      } else {
        // Limpiamos la sesión por seguridad
        await sessionStore.clearSession();
        state = LoginFailure(
          'Error de API inesperado: ${apiResponse.statusCode}',
        );
      }
    } on supabase.AuthException catch (e) {
      state = LoginFailure(e.message);
    } on DioException catch (e) {
      // Limpiamos la sesión si la validación falló
      await ref.read(secureSessionStoreProvider).clearSession();

      String errorMessage = 'Error de conexión con la API de Investep.';

      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map<String, dynamic> && data.containsKey('error')) {
          try {
            final errorMap = data['error'] as Map<String, dynamic>;
            errorMessage = errorMap['message'] as String;
          } catch (_) {
            errorMessage = 'Error de API: ${e.response?.statusCode}';
          }
        } else {
          errorMessage = 'Error de API: ${e.response?.statusCode}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tiempo de espera de conexión agotado con la API.';
      }

      state = LoginFailure(errorMessage);
    } catch (e) {
      // Aseguramos limpiar la sesión ante errores inesperados
      await ref.read(secureSessionStoreProvider).clearSession();
      debugPrint('Error inesperado durante el login: $e');
      state = LoginFailure('Ocurrió un error inesperado: $e');
    }
  }
}

/// Provider para el controlador de login.
final loginControllerProvider =
    NotifierProvider.autoDispose<LoginController, LoginState>(
      LoginController.new,
    );
