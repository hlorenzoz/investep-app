import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/auth/presentation/login_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockAuthResponse extends Mock implements AuthResponse {}

class MockSession extends Mock implements Session {}

void main() {
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;
  late ProviderContainer container;

  setUp(() {
    supabase = MockSupabaseClient();
    goTrue = MockGoTrueClient();
    when(() => supabase.auth).thenReturn(goTrue);

    container = ProviderContainer(
      overrides: [supabaseClientProvider.overrideWithValue(supabase)],
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

  group('login', () {
    test(
      'signIn ok con sesión → queda en LoginLoading (el gate toma el control)',
      () async {
        stubSignIn(withSession: true);

        await notifier().login('user@example.com', 'secret123');

        // El gating (/auth/me) lo maneja AuthGate, no este controller: tras un
        // signIn exitoso quedamos en loading y el router redirige.
        expect(currentState(), isA<LoginLoading>());
      },
    );

    test('signIn lanza AuthException → LoginFailure', () async {
      when(
        () => goTrue.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => throw const AuthException('Credenciales inválidas'),
      );

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
}
