import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/secure_session_store.dart';

/// Cliente HTTP base contra `investep-app-api` (REST).
///
/// IMPORTANTE: este es sólo el transporte. Los modelos y endpoints concretos se
/// generan contra el spec OpenAPI que publica la API (ver AGENTS.md §4); NO
/// escribas a mano modelos que ya estén en el contrato.
///
/// El interceptor adjunta el token de sesión y evita loguear datos sensibles.
final apiClientProvider = Provider<Dio>((ref) {
  final sessionStore = ref.watch(secureSessionStoreProvider);

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
      onRequest: (options, handler) async {
        final token = await sessionStore.readSession();
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );

  return dio;
});
