import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/features/admin/presentation/admin_brokers_screen.dart';
import 'package:investep_app/features/brokers/data/broker_repository.dart';
import 'package:investep_app/features/brokers/domain/broker.dart';
import 'package:investep_app/features/brokers/presentation/broker_logo.dart';
import 'package:investep_app/features/brokers/presentation/brokers_provider.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockBrokerRepository extends Mock implements BrokerRepository {}

void main() {
  late MockBrokerRepository repo;

  const testBroker = Broker(
    id: 1,
    slug: 'interactive-brokers',
    name: 'Interactive Brokers',
    url: 'https://www.interactivebrokers.com',
    urlSecondary: 'https://www.interactivebrokers.ie',
    logo: 'https://x/logo.png',
  );

  setUp(() {
    repo = MockBrokerRepository();
    registerFallbackValue(const <String, dynamic>{});
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        brokerRepositoryProvider.overrideWithValue(repo),
        brokersProvider.overrideWith((ref) => repo.getBrokers()),
      ],
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
            home: const AdminBrokersScreen(),
          );
        },
      ),
    );
  }

  testWidgets(
    'Renderiza listado de brokers con nombre, slug, url y BrokerLogo',
    (tester) async {
      when(() => repo.getBrokers()).thenAnswer((_) async => [testBroker]);

      await tester.pumpWidget(createTestWidget());
      await tester.pump();
      await tester.pumpAndSettle();

      // Validar visualización de datos principales
      expect(find.text('Interactive Brokers'), findsOneWidget);
      expect(find.text('Slug: interactive-brokers'), findsOneWidget);
      expect(find.text('https://www.interactivebrokers.com'), findsOneWidget);
      expect(find.byType(BrokerLogo), findsOneWidget);
    },
  );

  testWidgets(
    'FAB (+) abre el dialogo de creacion de broker con inputs limpios y previsualizacion',
    (tester) async {
      when(() => repo.getBrokers()).thenAnswer((_) async => []);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Abrir formulario
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      // Verificar campos del dialogo (aparece en el título del diálogo y en el botón de confirmación)
      expect(find.text('Crear Bróker'), findsNWidgets(2));
      expect(find.widgetWithText(TextFormField, 'Slug'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, 'URL Principal'),
        findsOneWidget,
      );

      // Scroll hacia abajo para exponer la previsualización que quedó fuera del viewport
      final formListView = find.descendant(
        of: find.byType(Dialog),
        matching: find.byType(ListView),
      );
      await tester.drag(formListView, const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(
        find.text('Previsualización en tiempo real del logo/icono.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('Editar abre el dialogo precargado con los datos del broker', (
    tester,
  ) async {
    when(() => repo.getBrokers()).thenAnswer((_) async => [testBroker]);

    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap en editar
    await tester.tap(find.byTooltip('Editar Bróker'));
    await tester.pumpAndSettle();

    // Verificar precarga
    expect(find.text('Editar Bróker'), findsOneWidget);
    expect(
      find.widgetWithText(TextFormField, 'interactive-brokers'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'Interactive Brokers'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'https://www.interactivebrokers.com'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'https://www.interactivebrokers.ie'),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, 'https://x/logo.png'),
      findsOneWidget,
    );
  });

  testWidgets(
    'El layout responsivo se contrae al 80% en viewports grandes y se expande en chicos',
    (tester) async {
      when(() => repo.getBrokers()).thenAnswer((_) async => []);

      // Caso 1: Viewport grande (Desktop: 1000 de ancho)
      tester.view.physicalSize = const Size(1000, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // El ancho de la lista Scaffold debe estar constreñido al 80% (800 dp)
      final scaffoldWidgetFinder = find.descendant(
        of: find.byType(AdminBrokersScreen),
        matching: find.byType(Scaffold),
      );
      final size = tester.getSize(scaffoldWidgetFinder);
      expect(size.width, 800.0);

      // Caso 2: Viewport chico (Mobile: 400 de ancho)
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpAndSettle();

      final sizeChico = tester.getSize(scaffoldWidgetFinder);
      expect(sizeChico.width, 400.0);
    },
  );
}
