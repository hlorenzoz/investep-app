import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../providers/supabase_provider.dart';

/// Manejo central del 401: token ausente/inválido/expirado → limpiamos la sesión
/// local. Eso dispara `onAuthStateChange(null)` → `AuthGate` → redirect a
/// `/login`. Aplica a CUALQUIER endpoint de negocio (brokers/plans/capital/...),
/// no sólo a `/auth/me`. Un 503 (transitorio) NO desloguea: lo reintentan los
/// repos con backoff.
Future<void> handleAuthError(SupabaseClient client, int? statusCode) async {
  if (statusCode == 401) {
    await client.auth.signOut();
  }
}

/// Cliente HTTP base contra `investep-app-api` (REST).
///
/// IMPORTANTE: este es sólo el transporte. Los modelos y endpoints concretos se
/// generan contra el spec OpenAPI que publica la API (ver AGENTS.md §4); NO
/// escribas a mano modelos que ya estén en el contrato.
///
/// El interceptor adjunta el token de sesión VIVO de Supabase
/// (`currentSession.accessToken`). El SDK auto-refresca ese token en background,
/// así que un 401 de la API significa que la sesión está realmente muerta
/// (refresh fallido o revocada) → re-login; un 503 significa backend caído →
/// reintentar. No guardamos una copia estática del token en el cliente.
final apiClientProvider = Provider<Dio>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);

  String resolvedBaseUrl = AppConfig.apiBaseUrl;
  if (kIsWeb) {
    final uri = Uri.tryParse(resolvedBaseUrl);
    if (uri != null &&
        (uri.host == 'localhost' || uri.host == '127.0.0.1') &&
        uri.port == 8787) {
      resolvedBaseUrl = '/api';
    }
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: resolvedBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token = supabaseClient.auth.currentSession?.accessToken;
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (e, handler) async {
        // 401 en cualquier endpoint → re-login. Seguimos propagando el error
        // para que el repo lo mapee a ApiException(401).
        await handleAuthError(supabaseClient, e.response?.statusCode);
        handler.next(e);
      },
    ),
  );

  return dio;
});
