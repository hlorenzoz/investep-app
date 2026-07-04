import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/relations/domain/relations_overview.dart';
import 'package:investep_app/features/relations/presentation/relations_providers.dart';
import 'package:investep_app/features/relations/presentation/relations_screen.dart';
import 'package:investep_app/features/tickers/data/ticker_repository.dart';
import 'package:investep_app/features/tickers/domain/ticker.dart';
import 'package:investep_app/features/tickers/presentation/favorites_controller.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockTickerRepository extends Mock implements TickerRepository {}

void main() {
  const app = MaterialApp(
    locale: Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: RelationsScreen(),
  );

  Ticker favTicker(String symbol) => Ticker(
    id: 1,
    symbol: symbol,
    name: '$symbol Inc.',
    assetClass: 'stock',
    financials: const {},
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    isFavorite: true,
  );

  const sampleOverview = RelationsOverview(
    assets: [
      AssetRelation(
        symbol: 'TSLA',
        name: 'Tesla, Inc.',
        assetClass: AssetClass.stock,
        longEtfs: [
          RelationLink(
            symbol: 'TSLL',
            name: 'Direxion Daily TSLA Bull 2X',
            relationType: RelationType.x2,
            multiplier: 2.0,
          ),
        ],
        inverseEtfs: [
          RelationLink(
            symbol: 'TSLS',
            name: 'AXS TSLA Bear Daily',
            relationType: RelationType.inverso,
            multiplier: -1.0,
          ),
        ],
      ),
    ],
    sectors: [
      SectorRelation(
        etf: 'XLK',
        sectorName: 'Technology',
        inverseEtfs: [
          RelationLink(
            symbol: 'TECS',
            name: 'Direxion Daily Tech Bear 3X',
            relationType: RelationType.inverso,
            multiplier: -3.0,
          ),
        ],
      ),
    ],
  );

  // Override por defecto: sin favoritos (la sección se auto-oculta).
  final noFavorites = favoriteTickersProvider.overrideWith(
    (ref) => <Ticker>[],
  );

  testWidgets('renderiza ambas tablas con activos y sectores', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relationsOverviewProvider.overrideWith((ref) => sampleOverview),
          noFavorites,
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TSLA'), findsOneWidget);
    expect(find.text('Tesla, Inc.'), findsOneWidget);
    expect(find.text('TSLL'), findsOneWidget);
    expect(find.text('TSLS'), findsOneWidget);
    expect(find.text('XLK'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
    expect(find.text('TECS'), findsOneWidget);
    // Sin favoritos → no aparece la sección.
    expect(find.text('Favoritos'), findsNothing);
  });

  testWidgets('la sección Favoritos aparece cuando hay favoritos', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relationsOverviewProvider.overrideWith((ref) => sampleOverview),
          favoriteTickersProvider.overrideWith((ref) => [favTicker('AAPL')]),
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Favoritos'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);
  });

  testWidgets('tocar la estrella dispara el toggle en el repo', (tester) async {
    final repo = MockTickerRepository();
    when(() => repo.addFavorite('TSLA')).thenAnswer((_) async => true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relationsOverviewProvider.overrideWith((ref) => sampleOverview),
          noFavorites,
          tickerRepositoryProvider.overrideWithValue(repo),
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    // La primera estrella vacía corresponde al activo principal TSLA.
    await tester.tap(find.byIcon(Icons.star_border_rounded).first);
    await tester.pumpAndSettle();

    verify(() => repo.addFavorite('TSLA')).called(1);
    // Estado optimista reflejado: aparece una estrella llena.
    expect(find.byIcon(Icons.star_rounded), findsWidgets);
  });

  testWidgets('el filtro deja solo los activos que coinciden', (tester) async {
    const twoAssets = RelationsOverview(
      assets: [
        AssetRelation(
          symbol: 'TSLA',
          name: 'Tesla, Inc.',
          assetClass: AssetClass.stock,
          longEtfs: [],
          inverseEtfs: [],
        ),
        AssetRelation(
          symbol: 'AAPL',
          name: 'Apple Inc.',
          assetClass: AssetClass.stock,
          longEtfs: [],
          inverseEtfs: [],
        ),
      ],
      sectors: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relationsOverviewProvider.overrideWith((ref) => twoAssets),
          noFavorites,
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('TSLA'), findsOneWidget);
    expect(find.text('AAPL'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'aapl');
    await tester.pumpAndSettle();

    expect(find.text('AAPL'), findsOneWidget);
    expect(find.text('TSLA'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();
    expect(
      find.text('No hay activos que coincidan con la búsqueda.'),
      findsOneWidget,
    );
  });

  testWidgets('muestra estados vacíos cuando no hay datos', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relationsOverviewProvider.overrideWith(
            (ref) => const RelationsOverview(assets: [], sectors: []),
          ),
          noFavorites,
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('No hay activos con relaciones cargadas.'), findsOneWidget);
    expect(find.text('No hay sectores cargados.'), findsOneWidget);
  });

  testWidgets('muestra el estado de error con botón de reintento', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          relationsOverviewProvider.overrideWith(
            (ref) => Future<RelationsOverview>.error(Exception('boom')),
          ),
          noFavorites,
        ],
        child: app,
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('No se pudieron cargar las relaciones entre activos.'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
  });
}
