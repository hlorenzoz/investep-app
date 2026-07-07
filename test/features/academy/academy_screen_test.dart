// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/auth/auth_gate.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/features/academy/domain/academy_models.dart';
import 'package:investep_app/features/academy/presentation/academy_screen.dart';
import 'package:investep_app/features/academy/presentation/providers/academy_providers.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:url_launcher_platform_interface/link.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockUrlLauncher extends UrlLauncherPlatform
    with MockPlatformInterfaceMixin {
  String? launchedUrl;
  PreferredLaunchMode? launchMode;
  bool canLaunchResult = true;
  bool launchResult = true;

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    return canLaunchResult;
  }

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    await Future<void>.delayed(const Duration(milliseconds: 5));
    launchedUrl = url;
    launchMode = options.mode;
    return launchResult;
  }
}

class FakeAuthGate extends AuthGate {
  final AuthGateState initialState;
  FakeAuthGate(this.initialState);

  @override
  AuthGateState build() => initialState;
}

void main() {
  late MockUrlLauncher mockUrlLauncher;

  setUp(() {
    mockUrlLauncher = MockUrlLauncher();
    UrlLauncherPlatform.instance = mockUrlLauncher;
  });

  Widget createAcademyScreen({
    List<AcademyPlan>? dummyPlans,
    AuthUser? mockUser,
  }) {
    return ProviderScope(
      overrides: [
        authGateProvider.overrideWith(
          () => FakeAuthGate(
            mockUser != null
                ? GateAuthenticated(mockUser)
                : const GateNoSession(),
          ),
        ),
        if (dummyPlans != null)
          academyPlansProvider.overrideWith((ref) => dummyPlans),
      ],
      child: const MaterialApp(
        locale: Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: AcademyScreen(),
      ),
    );
  }

  group('AcademyScreen Subscription Tests', () {
    testWidgets('Muestra los planes correctamente', (
      WidgetTester tester,
    ) async {
      final dummyPlans = [
        const AcademyPlan(
          id: 1,
          slug: 'bronze',
          name: 'Plan Bronce',
          subtitle: 'Acceso básico',
          priceRegular: 5000,
          currency: 'USD',
          features: [],
          url: 'https://checkout.stripe.com/pay/bronze',
        ),
      ];

      await tester.pumpWidget(createAcademyScreen(dummyPlans: dummyPlans));

      await tester.pumpAndSettle();

      expect(find.text('Plan Bronce'), findsOneWidget);
      expect(find.text('Inscribirme Ahora'), findsOneWidget);
    });

    testWidgets('Caso 1: Abre la url en navegador externo si no es nula', (
      WidgetTester tester,
    ) async {
      final dummyPlans = [
        const AcademyPlan(
          id: 1,
          slug: 'gold',
          name: 'Plan Oro',
          priceRegular: 10000,
          currency: 'USD',
          features: [],
          url: 'https://checkout.stripe.com/pay/gold',
        ),
      ];

      await tester.pumpWidget(createAcademyScreen(dummyPlans: dummyPlans));

      await tester.pumpAndSettle();

      final button = find.text('Inscribirme Ahora');
      expect(button, findsOneWidget);

      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(); // Inicia la carga

      // Verificar que cambia a cargando temporalmente
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(
        const Duration(milliseconds: 20),
      ); // Espera el delay del mock
      await tester.pumpAndSettle(); // Completa la llamada asíncrona

      expect(
        mockUrlLauncher.launchedUrl,
        'https://checkout.stripe.com/pay/gold',
      );
      expect(
        mockUrlLauncher.launchMode,
        PreferredLaunchMode.externalApplication,
      );
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets(
      'Caso 2: Muestra el diálogo modal de fallback si la url es nula o vacía',
      (WidgetTester tester) async {
        final dummyPlans = [
          const AcademyPlan(
            id: 2,
            slug: 'free',
            name: 'Plan Gratis',
            priceRegular: 0,
            currency: 'USD',
            features: [],
            url: null, // url nula
          ),
        ];

        await tester.pumpWidget(createAcademyScreen(dummyPlans: dummyPlans));

        await tester.pumpAndSettle();

        final button = find.text('Inscribirme Ahora');
        await tester.ensureVisible(button);
        await tester.tap(button);
        await tester.pumpAndSettle();

        // Debe abrir el diálogo de fallback
        expect(find.text('Inscripción de forma directa'), findsOneWidget);
        expect(
          find.text(
            'Este paquete requiere inscripción directa con nuestro soporte. Por favor, comunícate con nosotros para brindarte asistencia inmediata.',
          ),
          findsOneWidget,
        );

        // Cerrar el diálogo
        await tester.tap(find.text('Entendido'));
        await tester.pumpAndSettle();

        expect(find.text('Inscripción de forma directa'), findsNothing);
        expect(mockUrlLauncher.launchedUrl, isNull);
      },
    );

    testWidgets('Muestra SnackBar si falla launchUrl', (
      WidgetTester tester,
    ) async {
      mockUrlLauncher.launchResult = false; // Simula fallo al abrir

      final dummyPlans = [
        const AcademyPlan(
          id: 1,
          slug: 'gold',
          name: 'Plan Oro',
          priceRegular: 10000,
          currency: 'USD',
          features: [],
          url: 'https://invalid-url.com',
        ),
      ];

      await tester.pumpWidget(createAcademyScreen(dummyPlans: dummyPlans));

      await tester.pumpAndSettle();

      final button = find.text('Inscribirme Ahora');
      await tester.ensureVisible(button);
      await tester.tap(button);
      await tester.pump(); // Inicia carga
      await tester.pump(const Duration(milliseconds: 20)); // Espera delay
      await tester.pumpAndSettle(); // Muestra SnackBar

      expect(find.byType(SnackBar), findsOneWidget);
      expect(
        find.text('No se pudo abrir el enlace de suscripción.'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Caso 3: Si el usuario tiene plan activo, deshabilita el botón y muestra "Tu Plan Actual"',
      (WidgetTester tester) async {
        final dummyPlans = [
          const AcademyPlan(
            id: 1,
            slug: 'gold',
            name: 'Plan Oro',
            priceRegular: 10000,
            currency: 'USD',
            features: [],
            url: 'https://checkout.stripe.com/pay/gold',
          ),
        ];

        final mockUser = AuthUser(
          id: 'user-123',
          email: 'gold@hlorenzoz.com',
          role: 'user',
          mustResetPassword: false,
          planSlug: 'gold', // active plan gold
        );

        await tester.pumpWidget(
          createAcademyScreen(dummyPlans: dummyPlans, mockUser: mockUser),
        );

        await tester.pumpAndSettle();

        // El botón de inscribirse debe estar deshabilitado y decir "Tu Plan Actual"
        expect(find.text('Tu Plan Actual'), findsOneWidget);
        expect(find.text('Inscribirme Ahora'), findsNothing);
      },
    );
  });
}
