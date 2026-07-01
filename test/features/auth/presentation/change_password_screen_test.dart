import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/auth/data/auth_repository.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/features/auth/presentation/change_password_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class MockAuthRepository extends Mock implements AuthRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockAuthRepository mockRepo;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  final authUser = AuthUser(
    id: 'user-123',
    email: 'user@example.com',
    role: 'user',
    mustResetPassword: false,
  );

  setUp(() {
    mockRepo = MockAuthRepository();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.signOut()).thenAnswer((_) async {});
  });

  Widget createTestWidget() {
    final router = GoRouter(
      initialLocation: '/change-password',
      routes: [
        GoRoute(
          path: '/change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) =>
              const Scaffold(body: Text('LOGIN_SCREEN')),
        ),
      ],
    );

    return ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(mockRepo),
        supabaseClientProvider.overrideWithValue(mockSupabase),
      ],
      child: MaterialApp.router(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('debe renderizar los campos del formulario y botón guardar', (
    tester,
  ) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Definí tu nueva contraseña'), findsOneWidget);
    expect(find.text('Contraseña nueva'), findsOneWidget);
    expect(find.text('Repetir contraseña'), findsOneWidget);
    expect(find.text('Guardar contraseña'), findsOneWidget);
  });

  testWidgets(
    'debe mostrar error de validación cuando la contraseña no cumple la política',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'short');
      await tester.enterText(find.byType(TextFormField).at(1), 'short');
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();

      expect(
        find.text('La contraseña debe tener al menos 8 caracteres'),
        findsOneWidget,
      );
      verifyNever(() => mockRepo.changePassword(any()));
    },
  );

  testWidgets(
    'debe mostrar error de validación si las contraseñas no coinciden',
    (tester) async {
      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'Password123!');
      await tester.enterText(find.byType(TextFormField).at(1), 'Password1234!');
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();

      expect(find.text('Las contraseñas no coinciden'), findsOneWidget);
      verifyNever(() => mockRepo.changePassword(any()));
    },
  );

  testWidgets(
    'al enviar datos válidos llama al repositorio y muestra pantalla de éxito',
    (tester) async {
      when(
        () => mockRepo.changePassword('NuevaClave123!'),
      ).thenAnswer((_) async => authUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'NuevaClave123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'NuevaClave123!',
      );
      await tester.tap(find.text('Guardar contraseña'));

      await tester.pump();
      await tester.pumpAndSettle();

      verify(() => mockRepo.changePassword('NuevaClave123!')).called(1);
      expect(find.text('¡Contraseña actualizada!'), findsOneWidget);
      expect(find.text('Ir a iniciar sesión'), findsOneWidget);
    },
  );

  testWidgets(
    'al presionar Ir a iniciar sesión en pantalla de éxito navega a /login',
    (tester) async {
      when(
        () => mockRepo.changePassword('NuevaClave123!'),
      ).thenAnswer((_) async => authUser);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'NuevaClave123!',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'NuevaClave123!',
      );
      await tester.tap(find.text('Guardar contraseña'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ir a iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('LOGIN_SCREEN'), findsOneWidget);
    },
  );
}
