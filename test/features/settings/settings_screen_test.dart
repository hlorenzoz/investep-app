// Copyright 2026 The Flutter Authors
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file or at https://developers.google.com/open-source/licenses/bsd.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/core/providers/supabase_provider.dart';
import 'package:investep_app/features/settings/presentation/settings_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

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
          builder: (context, state) => const Scaffold(
            body: Text('CHANGE_PASSWORD_ROUTE'),
          ),
        ),
      ],
    );
  }

  Widget createTestWidget(GoRouter router) {
    return ProviderScope(
      overrides: [
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

  testWidgets('debe renderizar todos los elementos de la interfaz en español', (tester) async {
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

  testWidgets('al presionar Cambiar contraseña debe navegar a /change-password', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(createTestWidget(router));
    await tester.pumpAndSettle();

    final changePasswordBtn = find.text('Cambiar contraseña');
    await tester.tap(changePasswordBtn);
    await tester.pumpAndSettle();

    expect(find.text('CHANGE_PASSWORD_ROUTE'), findsOneWidget);
  });

  testWidgets('al presionar cerrar sesión debe mostrar el diálogo y llamar a signOut en confirmación', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(createTestWidget(router));
    await tester.pumpAndSettle();

    // Presionar el botón de cerrar sesión
    await tester.tap(find.text('Cerrar sesión'));
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
  });

  testWidgets('al presionar cancelar en el diálogo de cerrar sesión no debe llamar a signOut', (tester) async {
    final router = createRouter();
    await tester.pumpWidget(createTestWidget(router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cerrar sesión'));
    await tester.pumpAndSettle();

    // Tocar Cancelar
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Cerrar sesión?'), findsNothing);
    verifyNever(() => mockAuth.signOut());
  });
}
