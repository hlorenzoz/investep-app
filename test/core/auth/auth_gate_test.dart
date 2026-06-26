import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/auth/auth_gate.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/auth/data/auth_repository.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/features/auth/presentation/last_email_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    hide AuthUser, AuthState;
import 'package:supabase_flutter/supabase_flutter.dart'
    as supabase
    show AuthState;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockSession extends Mock implements Session {}

class MockAuthState extends Mock implements supabase.AuthState {}

void main() {
  late MockAuthRepository repo;
  late MockSupabaseClient supabaseClient;
  late MockGoTrueClient goTrue;
  late StreamController<supabase.AuthState> authStream;
  late ProviderContainer container;

  final user = AuthUser(
    id: 'uuid-1',
    email: 'user@example.com',
    mustResetPassword: false,
  );
  final userMustReset = AuthUser(
    id: 'uuid-1',
    email: 'reset@example.com',
    mustResetPassword: true,
  );

  setUp(() {
    repo = MockAuthRepository();
    supabaseClient = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    authStream = StreamController<supabase.AuthState>.broadcast();

    when(() => supabaseClient.auth).thenReturn(goTrue);
    when(() => goTrue.onAuthStateChange).thenAnswer((_) => authStream.stream);
    when(() => goTrue.signOut()).thenAnswer((_) async {});
    when(() => goTrue.currentSession).thenReturn(MockSession());

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        supabaseClientProvider.overrideWithValue(supabaseClient),
      ],
    );
    addTearDown(container.dispose);
    // Suscribe para que build() corra y se enganche al stream.
    container.listen(authGateProvider, (_, _) {});
  });

  AuthGate notifier() => container.read(authGateProvider.notifier);
  AuthGateState state() => container.read(authGateProvider);
  String? lastEmail() => container.read(lastEmailProvider);

  group('evaluate', () {
    test('sin sesión → GateNoSession', () async {
      when(() => goTrue.currentSession).thenReturn(null);

      await notifier().evaluate();

      expect(state(), isA<GateNoSession>());
      verifyNever(() => repo.getMe());
    });

    test('200 mustReset=false → GateAuthenticated y guarda el email', () async {
      when(() => repo.getMe()).thenAnswer((_) async => user);

      await notifier().evaluate();

      final s = state();
      expect(s, isA<GateAuthenticated>());
      expect((s as GateAuthenticated).user.id, 'uuid-1');
      expect(lastEmail(), 'user@example.com');
    });

    test(
      '200 mustReset=true → GateNeedsPasswordReset y guarda el email',
      () async {
        when(() => repo.getMe()).thenAnswer((_) async => userMustReset);

        await notifier().evaluate();

        expect(state(), isA<GateNeedsPasswordReset>());
        expect(lastEmail(), 'reset@example.com');
      },
    );

    test(
      '401 → GateNoSession (el signOut lo centraliza el interceptor)',
      () async {
        when(() => repo.getMe()).thenAnswer(
          (_) async =>
              throw const ApiException(401, 'UNAUTHORIZED', 'Token muerto'),
        );

        await notifier().evaluate();

        expect(state(), isA<GateNoSession>());
        // El signOut ahora vive en el interceptor de Dio (handleAuthError), no acá.
        verifyNever(() => goTrue.signOut());
      },
    );

    test('503 → GateRetrying503 SIN signOut (no desloguear)', () async {
      when(() => repo.getMe()).thenAnswer(
        (_) async => throw const ApiException(
          503,
          'SERVICE_UNAVAILABLE',
          'Backend caído',
        ),
      );

      await notifier().evaluate();

      final s = state();
      expect(s, isA<GateRetrying503>());
      expect((s as GateRetrying503).message, 'Backend caído');
      verifyNever(() => goTrue.signOut());
    });

    test('error no-retryable inesperado (404) → GateNoSession', () async {
      when(() => repo.getMe()).thenAnswer(
        (_) async => throw const ApiException(404, 'NOT_FOUND', 'No está'),
      );

      await notifier().evaluate();

      expect(state(), isA<GateNoSession>());
    });
  });

  group('retry503', () {
    test('reintenta y resuelve a GateAuthenticated', () async {
      var calls = 0;
      when(() => repo.getMe()).thenAnswer((_) async {
        calls++;
        if (calls == 1) {
          throw const ApiException(503, 'SERVICE_UNAVAILABLE', 'caído');
        }
        return user;
      });

      await notifier().evaluate();
      expect(state(), isA<GateRetrying503>());

      await notifier().retry503();
      expect(state(), isA<GateAuthenticated>());
    });
  });

  group('stream onAuthStateChange', () {
    test('evento con sesión null → GateNoSession', () async {
      final event = MockAuthState();
      when(() => event.session).thenReturn(null);

      authStream.add(event);
      await Future<void>.delayed(Duration.zero);

      expect(state(), isA<GateNoSession>());
    });

    test('evento con sesión → re-evalúa contra /auth/me', () async {
      when(() => repo.getMe()).thenAnswer((_) async => user);
      final event = MockAuthState();
      when(() => event.session).thenReturn(MockSession());

      authStream.add(event);
      await Future<void>.delayed(Duration.zero);

      expect(state(), isA<GateAuthenticated>());
    });
  });
}
