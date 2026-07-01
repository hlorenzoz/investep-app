import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/app/theme/theme_provider.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/features/admin/presentation/admin_tickers_screen.dart';
import 'package:investep_app/features/tickers/data/ticker_repository.dart';
import 'package:investep_app/features/tickers/domain/ticker.dart';
import 'package:investep_app/features/tickers/presentation/tickers_provider.dart';
import 'package:investep_app/features/academy/data/academy_repository.dart';
import 'package:investep_app/features/academy/domain/academy_models.dart';
import 'package:investep_app/features/academy/presentation/providers/academy_providers.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MockTickerRepository extends Mock implements TickerRepository {}
class MockAcademyRepository extends Mock implements AcademyRepository {}

void main() {
  late MockTickerRepository repo;
  late MockAcademyRepository academyRepo;

  final testTicker = Ticker(
    id: 1,
    symbol: 'TSLA',
    name: 'Tesla, Inc.',
    assetClass: 'stock',
    exchange: 'NASDAQ',
    sector: 'Consumer Cyclical',
    price: 426.64,
    changePct: 1.44,
    financials: const {},
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  final testTickerDetail = TickerDetail(
    ticker: Ticker(
      id: 1,
      symbol: 'TSLA',
      name: 'Tesla, Inc.',
      assetClass: 'stock',
      exchange: 'NASDAQ',
      sector: 'Consumer Cyclical',
      price: 426.64,
      changePct: 1.44,
      financials: const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    relations: const [],
    plans: const ['gold'],
  );

  setUp(() {
    repo = MockTickerRepository();
    academyRepo = MockAcademyRepository();
    registerFallbackValue(const <String, dynamic>{});
  });

  Widget createTestWidget() {
    return ProviderScope(
      overrides: [
        tickerRepositoryProvider.overrideWithValue(repo),
        academyRepositoryProvider.overrideWithValue(academyRepo),
        academyPlansProvider.overrideWith((ref) async => [
          const AcademyPlan(
            id: 1,
            slug: 'gold',
            name: 'Gold Plan',
            priceRegular: 99.0,
            currency: 'USD',
            features: [],
          ),
        ]),
        tickersListProvider.overrideWith((ref) async => PaginatedTickers(
          tickers: [testTicker],
          page: 1,
          limit: 20,
          total: 1,
        )),
        tickerDetailProvider.overrideWith((ref, symbol) async => testTickerDetail),
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
            home: const AdminTickersScreen(),
          );
        },
      ),
    );
  }

  testWidgets('Renderiza listado de activos con símbolo, nombre, clase, precio y cambio %', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    await tester.pumpAndSettle();

    // Validar visualización de datos principales
    expect(find.text('TSLA'), findsOneWidget);
    expect(find.text('Tesla, Inc.'), findsOneWidget);
    expect(find.text('STOCK'), findsOneWidget);
    expect(find.text('\$426.64'), findsOneWidget);
    expect(find.text('+1.44%'), findsOneWidget);
  });

  testWidgets('FAB (+) abre el diálogo de creación de activo con inputs limpios', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Abrir formulario de creación
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    // Verificar campos del diálogo
    expect(find.text('Crear Activo'), findsNWidgets(2)); // En el título y en el botón
    expect(find.widgetWithText(TextFormField, 'Símbolo'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Nombre'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Mercado / Exchange'), findsOneWidget);
  });

  testWidgets('Editar abre el diálogo con tabs, precargado con los datos del activo', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pump();
    await tester.pumpAndSettle();

    // Tap en editar
    await tester.tap(find.byTooltip('Editar Activo'));
    await tester.pumpAndSettle();

    // Verificar presencia de tabs
    expect(find.text('Datos Básicos'), findsOneWidget);
    expect(find.text('Planes'), findsOneWidget);
    expect(find.text('Relaciones'), findsOneWidget);

    // Verificar precarga del formulario básico
    expect(find.widgetWithText(TextFormField, 'TSLA'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'Tesla, Inc.'), findsOneWidget);
    expect(find.widgetWithText(TextFormField, 'NASDAQ'), findsOneWidget);
  });

  testWidgets('El layout responsivo se contrae al 80% en viewports grandes y se expande en chicos', (tester) async {
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
      of: find.byType(AdminTickersScreen),
      matching: find.byType(Scaffold),
    );
    final size = tester.getSize(scaffoldWidgetFinder);
    expect(size.width, 800.0);

    // Caso 2: Viewport chico (Mobile: 400 de ancho)
    tester.view.physicalSize = const Size(400, 800);
    await tester.pumpAndSettle();

    final sizeChico = tester.getSize(scaffoldWidgetFinder);
    expect(sizeChico.width, 400.0);
  });

  testWidgets('Pestaña Planes: permite asociar y desasociar planes mediante checkboxes', (tester) async {
    when(() => repo.addPlan(any(), any())).thenAnswer((_) async => {});
    when(() => repo.deletePlan(any(), any())).thenAnswer((_) async => {});

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar Activo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Planes'));
    await tester.pumpAndSettle();

    expect(find.text('Gold Plan'), findsOneWidget);

    final chipFinder = find.byType(FilterChip);
    expect(chipFinder, findsOneWidget);
    
    await tester.tap(chipFinder);
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => repo.deletePlan(1, 1)).called(1);
  });

  testWidgets('Pestaña Relaciones: permite buscar, asociar y desasociar relaciones', (tester) async {
    final searchTicker = Ticker(
      id: 2,
      symbol: 'AAPL',
      name: 'Apple Inc.',
      assetClass: 'stock',
      financials: const {},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    when(() => repo.getTickers(q: 'AAPL', limit: 100)).thenAnswer((_) async => PaginatedTickers(
      tickers: [searchTicker],
      page: 1,
      limit: 20,
      total: 1,
    ));
    when(() => repo.addRelation(
      any(),
      relatedTickerId: any(named: 'relatedTickerId'),
      relationType: any(named: 'relationType'),
      multiplier: any(named: 'multiplier'),
    )).thenAnswer((_) async => {});

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Editar Activo'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Relaciones'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Activo Relacionado'), 'AAPL');
    await tester.tap(find.byIcon(LucideIcons.search).last);
    await tester.pumpAndSettle();

    expect(find.text('Subyacente encontrado: Apple Inc.'), findsOneWidget);

    await tester.enterText(find.widgetWithText(TextFormField, 'Multiplicador'), '2.0');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Asociar Relación'));
    await tester.pump();
    await tester.pumpAndSettle();

    verify(() => repo.addRelation(
      1,
      relatedTickerId: 2,
      relationType: 'leveraged_long',
      multiplier: 2.0,
    )).called(1);
  });
}
