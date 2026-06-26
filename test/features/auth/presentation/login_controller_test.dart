import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/auth/data/auth_repository.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/features/auth/presentation/login_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

void main() {
  late MockAuthRepository repo;
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;
  late ProviderContainer container;

  final authUser = AuthUser(
    id: 'uuid-1',
    email: 'user@example.com',
    mustResetPassword: true,
  );

  setUp(() {
    repo = MockAuthRepository();
    supabase = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);
    when(() => goTrue.signOut()).thenAnswer((_) async {});

    container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        supabaseClientProvider.overrideWithValue(supabase),
      ],
    );
    addTearDown(container.dispose);
    container.listen(loginControllerProvider, (_, _) {});
  });

  LoginController notifier() =>
      container.read(loginControllerProvider.notifier);
  LoginState currentState() => container.read(loginControllerProvider);

  void stubSignIn({required bool withSession}) {
    final response = MockAuthResponse();
    when(() => response.session).thenReturn(withSession ? MockSession() : null);
    when(
      () => goTrue.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => response);
  }

  group('login (flujo completo)', () {
    test('signIn ok + /auth/me 200 → LoginSuccess con el usuario', () async {
      stubSignIn(withSession: true);
      when(() => repo.getMe()).thenAnswer((_) async => authUser);

      await notifier().login('user@example.com', 'secret123');

      final state = currentState();
      expect(state, isA<LoginSuccess>());
      expect((state as LoginSuccess).user.mustResetPassword, isTrue);
    });

    test('signIn lanza AuthException → LoginFailure', () async {
      when(
        () => goTrue.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => throw const AuthException('Credenciales inválidas'));

      await notifier().login('user@example.com', 'bad');

      final state = currentState();
      expect(state, isA<LoginFailure>());
      expect((state as LoginFailure).message, 'Credenciales inválidas');
    });

    test('session nula → LoginFailure', () async {
      stubSignIn(withSession: false);

      await notifier().login('user@example.com', 'secret123');

      expect(currentState(), isA<LoginFailure>());
    });
  });

  group('retryGate (gate aislado)', () {
    test('200 → LoginSuccess', () async {
      when(() => repo.getMe()).thenAnswer((_) async => authUser);

      await notifier().retryGate();

      expect(currentState(), isA<LoginSuccess>());
    });

    test('401 → signOut + LoginFailure (token muerto)', () async {
      when(() => repo.getMe()).thenAnswer(
        (_) async => throw const ApiException(401, 'UNAUTHORIZED', 'Token inválido'),
      );

      await notifier().retryGate();

      expect(currentState(), isA<LoginFailure>());
      verify(() => goTrue.signOut()).called(1);
    });

    test('503 → LoginGateRetryable SIN signOut (no desloguear)', () async {
      when(() => repo.getMe()).thenAnswer(
        (_) async => throw const ApiException(
          503,
          'SERVICE_UNAVAILABLE',
          'Backend caído',
        ),
      );

      await notifier().retryGate();

      final state = currentState();
      expect(state, isA<LoginGateRetryable>());
      expect((state as LoginGateRetryable).message, 'Backend caído');
      verifyNever(() => goTrue.signOut());
    });
  });
}
