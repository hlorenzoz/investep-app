import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/auth/data/auth_repository.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/features/auth/presentation/change_password_controller.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockAuthRepository repo;
  late MockSupabaseClient supabase;
  late MockGoTrueClient goTrue;
  late ProviderContainer container;

  final authUser = AuthUser(
    id: 'uuid-1',
    email: 'user@example.com',
    role: 'user',
    mustResetPassword: false,
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
    // Mantiene vivo el autoDispose durante el test.
    container.listen(changePasswordControllerProvider, (_, _) {});
  });

  ChangePasswordController notifier() =>
      container.read(changePasswordControllerProvider.notifier);
  ChangePasswordState currentState() =>
      container.read(changePasswordControllerProvider);

  test('200 → signOut (re-login obligatorio) y estado Success', () async {
    when(() => repo.changePassword(any())).thenAnswer((_) async => authUser);

    await notifier().submit('nuevaClave123');

    expect(currentState(), isA<ChangePasswordSuccess>());
    verify(() => goTrue.signOut()).called(1);
  });

  test(
    '401 → SessionExpired (el signOut lo centraliza el interceptor)',
    () async {
      when(() => repo.changePassword(any())).thenAnswer(
        (_) async =>
            throw const ApiException(401, 'UNAUTHORIZED', 'Token inválido'),
      );

      await notifier().submit('nuevaClave123');

      final state = currentState();
      expect(state, isA<ChangePasswordSessionExpired>());
      expect((state as ChangePasswordSessionExpired).message, 'Token inválido');
      // El signOut en 401 ahora lo hace el interceptor de Dio, no el controller.
      verifyNever(() => goTrue.signOut());
    },
  );

  test('400 → Failure con el message del server, SIN signOut', () async {
    when(() => repo.changePassword(any())).thenAnswer(
      (_) async => throw const ApiException(
        400,
        'VALIDATION_ERROR',
        'Contraseña muy débil',
      ),
    );

    await notifier().submit('debil');

    final state = currentState();
    expect(state, isA<ChangePasswordFailure>());
    expect((state as ChangePasswordFailure).message, 'Contraseña muy débil');
    verifyNever(() => goTrue.signOut());
  });

  test('422 → Failure marcado como bug del cliente', () async {
    when(() => repo.changePassword(any())).thenAnswer(
      (_) async => throw const ApiException(
        422,
        'VALIDATION_ERROR',
        'newPassword ausente',
      ),
    );

    await notifier().submit('x');

    final state = currentState();
    expect(state, isA<ChangePasswordFailure>());
    expect(
      (state as ChangePasswordFailure).message,
      contains('Error interno del cliente'),
    );
  });

  test('503 → Failure reintentable (se muestra el message)', () async {
    when(() => repo.changePassword(any())).thenAnswer(
      (_) async => throw const ApiException(
        503,
        'SERVICE_UNAVAILABLE',
        'Reintentá en unos segundos',
      ),
    );

    await notifier().submit('nuevaClave123');

    final state = currentState();
    expect(state, isA<ChangePasswordFailure>());
    expect(
      (state as ChangePasswordFailure).message,
      'Reintentá en unos segundos',
    );
    verifyNever(() => goTrue.signOut());
  });
}
