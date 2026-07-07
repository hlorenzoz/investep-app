// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import 'package:investep_app/core/auth/auth_gate.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/features/settings/presentation/settings_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class FakeAuthGate extends AuthGate {
  final AuthGateState initialState;
  FakeAuthGate(this.initialState);

  @override
  AuthGateState build() => initialState;
}

void main() {
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.signOut()).thenAnswer((_) async {});
  });

  GoRouter createRouter() {
    return GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: '/change-password',
          builder: (context, state) =>
              const Scaffold(body: Text('CHANGE_PASSWORD_ROUTE')),
        ),
        GoRoute(
          path: '/academy',
          builder: (context, state) =>
              const Scaffold(body: Text('ACADEMY_ROUTE')),
        ),
      ],
    );
  }

  Widget createTestWidget(GoRouter router, {AuthUser? mockUser}) {
    return ProviderScope(
      overrides: [
        supabaseClientProvider.overrideWithValue(mockSupabase),
        authGateProvider.overrideWith(
          () => FakeAuthGate(
            mockUser != null
                ? GateAuthenticated(mockUser)
                : const GateNoSession(),
          ),
        ),
      ],
      child: MaterialApp.router(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  void setupViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  testWidgets('debe renderizar todos los elementos de la interfaz en español', (
    tester,
  ) async {
    setupViewport(tester);

    final router = createRouter();
    await tester.pumpWidget(createTestWidget(router));
    await tester.pumpAndSettle();

    expect(find.text('Ajustes'), findsWidgets); // En el AppBar y/o header
    expect(find.text('INTERFAZ'), findsOneWidget);
    expect(find.text('Tema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);
    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Idioma'), findsOneWidget);
    expect(find.text('Español'), findsOneWidget);
    expect(find.text('Inglés'), findsOneWidget);
    expect(find.text('CUENTA'), findsOneWidget);
    expect(find.text('Cambiar contraseña'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
  });

  testWidgets(
    'al presionar Cambiar contraseña debe navegar a /change-password',
    (tester) async {
      setupViewport(tester);

      final router = createRouter();
      await tester.pumpWidget(createTestWidget(router));
      await tester.pumpAndSettle();

      final changePasswordBtn = find.text('Cambiar contraseña');
      await tester.scrollUntilVisible(changePasswordBtn, 100.0);
      await tester.tap(changePasswordBtn);
      await tester.pumpAndSettle();

      expect(find.text('CHANGE_PASSWORD_ROUTE'), findsOneWidget);
    },
  );

  testWidgets(
    'al presionar cerrar sesión debe mostrar el diálogo y llamar a signOut en confirmación',
    (tester) async {
      setupViewport(tester);

      final router = createRouter();
      await tester.pumpWidget(createTestWidget(router));
      await tester.pumpAndSettle();

      // Presionar el botón de cerrar sesión
      final signOutBtn = find.text('Cerrar sesión');
      await tester.scrollUntilVisible(signOutBtn, 100.0);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Debe mostrarse el diálogo de confirmación
      expect(find.text('¿Cerrar sesión?'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);

      // Tocar confirmar
      await tester.tap(find.text('Confirmar'));
      await tester.pumpAndSettle();

      // Debe cerrarse el diálogo y llamarse a signOut()
      expect(find.text('¿Cerrar sesión?'), findsNothing);
      verify(() => mockAuth.signOut()).called(1);
    },
  );

  testWidgets(
    'al presionar cancelar en el diálogo de cerrar sesión no debe llamar a signOut',
    (tester) async {
      setupViewport(tester);

      final router = createRouter();
      await tester.pumpWidget(createTestWidget(router));
      await tester.pumpAndSettle();

      final signOutBtn = find.text('Cerrar sesión');
      await tester.scrollUntilVisible(signOutBtn, 100.0);
      await tester.tap(signOutBtn);
      await tester.pumpAndSettle();

      // Tocar Cancelar
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('¿Cerrar sesión?'), findsNothing);
      verifyNever(() => mockAuth.signOut());
    },
  );

  group('Sección Plan de la Academia', () {
    testWidgets(
      'debe mostrar "Sin plan activo" y botón "Ver Planes" si el usuario no tiene plan',
      (tester) async {
        setupViewport(tester);

        final mockUser = AuthUser(
          id: 'user-1',
          email: 'test@example.com',
          role: 'user',
          mustResetPassword: false,
          planSlug: null,
        );

        final router = createRouter();
        await tester.pumpWidget(createTestWidget(router, mockUser: mockUser));
        await tester.pumpAndSettle();

        expect(find.text('PLAN DE LA ACADEMIA'), findsOneWidget);
        expect(find.text('Sin plan activo'), findsOneWidget);
        expect(find.text('Ver Planes'), findsOneWidget);
      },
    );

    testWidgets(
      'debe mostrar "Plan Oro" y botón "Actualizar Plan" si el usuario tiene plan gold',
      (tester) async {
        setupViewport(tester);

        final mockUser = AuthUser(
          id: 'user-1',
          email: 'test@example.com',
          role: 'user',
          mustResetPassword: false,
          planSlug: 'gold',
        );

        final router = createRouter();
        await tester.pumpWidget(createTestWidget(router, mockUser: mockUser));
        await tester.pumpAndSettle();

        expect(find.text('Plan Oro'), findsOneWidget);
        expect(find.text('Actualizar Plan'), findsOneWidget);
      },
    );

    testWidgets(
      'debe mostrar "Administrador (Todos los planes)" y botón "Actualizar Plan" si el usuario es admin',
      (tester) async {
        setupViewport(tester);

        final mockUser = AuthUser(
          id: 'user-admin',
          email: 'admin@example.com',
          role: 'admin',
          mustResetPassword: false,
          planSlug: null,
        );

        final router = createRouter();
        await tester.pumpWidget(createTestWidget(router, mockUser: mockUser));
        await tester.pumpAndSettle();

        expect(find.text('Administrador (Todos los planes)'), findsOneWidget);
        expect(find.text('Actualizar Plan'), findsOneWidget);
      },
    );

    testWidgets('al presionar el botón de plan debe navegar a /academy', (
      tester,
    ) async {
      setupViewport(tester);

      final mockUser = AuthUser(
        id: 'user-1',
        email: 'test@example.com',
        role: 'user',
        mustResetPassword: false,
        planSlug: 'silver',
      );

      final router = createRouter();
      await tester.pumpWidget(createTestWidget(router, mockUser: mockUser));
      await tester.pumpAndSettle();

      final btn = find.text('Actualizar Plan');
      await tester.scrollUntilVisible(btn, 100.0);
      await tester.tap(btn);
      await tester.pumpAndSettle();

      expect(find.text('ACADEMY_ROUTE'), findsOneWidget);
    });
  });
}
