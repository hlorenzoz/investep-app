import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/features/admin/data/admin_repository.dart';
import 'package:investep_app/features/admin/domain/user_admin.dart';
import 'package:investep_app/features/admin/presentation/user_list_view.dart';
import 'package:investep_app/features/admin/presentation/widgets/user_form_dialog.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

class MockAdminRepository extends Mock implements AdminRepository {}

void main() {
  late MockAdminRepository repo;

  final userAdmin = UserAdmin(
    id: 'u-1',
    email: 'admin@example.com',
    role: 'admin',
    fullName: 'Admin User',
    createdAt: DateTime(2026, 7, 1),
    mustResetPassword: true,
    phone: '+54 11 5555-0001',
    country: 'Argentina',
  );

  final userRegular = UserAdmin(
    id: 'u-2',
    email: 'user@example.com',
    role: 'user',
    fullName: 'Regular User',
    createdAt: DateTime(2026, 7, 1),
    mustResetPassword: false,
  );

  setUp(() {
    repo = MockAdminRepository();
    registerFallbackValue(const <String, dynamic>{});
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [adminRepositoryProvider.overrideWithValue(repo)],
      child: Consumer(
        builder: (context, ref, _) {
          final locale = ref.watch(localeProvider);
          final themeMode = ref.watch(themeModeProvider);
          return MaterialApp(
            locale: locale,
            themeMode: themeMode,
            theme: ThemeData.light(),
            darkTheme: ThemeData.dark(),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const UserListView(),
          );
        },
      ),
    );
  }

  testWidgets(
    'Renderiza lista de usuarios con nombres, emails, tags de rol y badges',
    (tester) async {
      when(
        () => repo.getUsers(),
      ).thenAnswer((_) async => [userAdmin, userRegular]);

      await tester.pumpWidget(createTestWidget());
      await tester.pump(); // Inicia carga
      await tester.pumpAndSettle();

      // Comprobar textos
      expect(find.text('Admin User'), findsOneWidget);
      expect(find.text('admin@example.com'), findsOneWidget);
      expect(find.text('Regular User'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);

      // Tags de rol
      expect(find.text('Admin'), findsOneWidget);
      expect(find.text('User'), findsOneWidget);

      // Badge "Forzar Clave" (solo el admin tiene mustResetPassword: true)
      expect(find.text('Forzar Clave'), findsOneWidget);
    },
  );

  testWidgets(
    'Al presionar FAB (+) abre el diálogo de aprovisionamiento de usuario',
    (tester) async {
      when(() => repo.getUsers()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap en FAB
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Debe abrir UserFormDialog
      expect(find.byType(UserFormDialog), findsOneWidget);
      expect(find.text('Aprovisionar Usuario'), findsOneWidget);
    },
  );

  testWidgets(
    'Al presionar editar en una tarjeta abre el formulario cargado con sus datos',
    (tester) async {
      when(() => repo.getUsers()).thenAnswer((_) async => [userRegular]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar botón de edición (primer IconButton o Icon con LucideIcons.edit3)
      await tester.tap(find.byIcon(LucideIcons.edit3).first);
      await tester.pumpAndSettle();

      // Debe abrir UserFormDialog en modo edición
      expect(find.byType(UserFormDialog), findsOneWidget);
      expect(find.text('Editar Usuario'), findsOneWidget);
      expect(
        find.text('Regular User'),
        findsWidgets,
      ); // En la tarjeta y en el input
    },
  );

  testWidgets(
    'Al presionar eliminar muestra diálogo de confirmación y llama al repositorio en confirmación',
    (tester) async {
      when(() => repo.getUsers()).thenAnswer((_) async => [userRegular]);
      when(() => repo.deleteUser('u-2')).thenAnswer((_) async => {});

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tocar botón de eliminar (el segundo IconButton o el icono de basura)
      await tester.tap(find.byType(IconButton).at(1));
      await tester.pumpAndSettle();

      // Debe mostrar diálogo de confirmación
      expect(find.text('¿Eliminar usuario?'), findsOneWidget);
      expect(
        find.textContaining('Esta acción es destructiva e irreversible.'),
        findsOneWidget,
      );

      // Confirmar
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      verify(() => repo.deleteUser('u-2')).called(1);
    },
  );

  testWidgets(
    'Renderiza phone y country en la tarjeta cuando están presentes',
    (tester) async {
      when(() => repo.getUsers()).thenAnswer((_) async => [userAdmin]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('+54 11 5555-0001'), findsOneWidget);
      expect(find.text('Argentina'), findsOneWidget);
      expect(find.byIcon(LucideIcons.phone), findsOneWidget);
      expect(find.byIcon(LucideIcons.globe), findsOneWidget);
    },
  );

  testWidgets('No renderiza phone ni country cuando son null', (tester) async {
    when(() => repo.getUsers()).thenAnswer((_) async => [userRegular]);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // userRegular no tiene phone ni country
    expect(find.byIcon(LucideIcons.phone), findsNothing);
    expect(find.byIcon(LucideIcons.globe), findsNothing);
  });

  testWidgets(
    'En UserFormDialog (Admin), la seleccion de pais y telefono sincronizan',
    (tester) async {
      when(() => repo.getUsers()).thenAnswer((_) async => [userRegular]);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Abrir formulario de aprovisionamiento
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Debe abrir el dialogo
      expect(find.byType(UserFormDialog), findsOneWidget);

      final phoneInput = find.widgetWithText(
        TextFormField,
        'Teléfono (Opcional)',
      );
      expect(phoneInput, findsOneWidget);

      // Escribir prefijo de España
      await tester.enterText(phoneInput, '+34 600000000');
      await tester.pumpAndSettle();

      // Se debe haber autoseleccionado España en el Selector
      expect(find.textContaining('España'), findsOneWidget);
    },
  );
}
