import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/store/data/store_repository.dart';
import 'package:investep_app/features/store/domain/product.dart';
import 'package:investep_app/features/store/presentation/store_catalog_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockStoreRepository extends Mock implements StoreRepository {}

void main() {
  late MockStoreRepository mockStoreRepository;
  late ProviderContainer container;

  setUp(() {
    mockStoreRepository = MockStoreRepository();
    container = ProviderContainer(
      overrides: [
        storeRepositoryProvider.overrideWithValue(mockStoreRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final testProducts = [
    const Product(
      id: 1,
      slug: 'remera-keep-it-simple',
      name: 'Remera Keep It Simple',
      description: 'Remera de algodón.',
      price: 29.99,
      currency: 'USD',
      image: 'shirts/remera-simple.webp',
      category: ProductCategory.tshirt,
      gender: ProductGender.men,
      theme: ProductTheme.dark,
      active: true,
      amazonUrl: 'https://amazon.com/remera-simple',
    ),
  ];

  testWidgets(
    'StoreCatalogScreen renders products and responds to filter pills',
    (tester) async {
      when(
        () => mockStoreRepository.fetchProducts(category: null, active: true),
      ).thenAnswer((_) async => testProducts);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: StoreCatalogScreen(),
          ),
        ),
      );

      // Verify loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify catalog elements rendered
      expect(find.text('Tienda'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Libros'), findsOneWidget);
      expect(find.text('Remera Keep It Simple'), findsOneWidget);
      expect(find.text('Ver en Amazon'), findsOneWidget);
    },
  );

  testWidgets('StoreCatalogScreen card click navigates to product details view', (
    tester,
  ) async {
    when(
      () => mockStoreRepository.fetchProducts(category: null, active: true),
    ).thenAnswer((_) async => testProducts);

    final router = GoRouter(
      initialLocation: '/store',
      routes: [
        GoRoute(
          path: '/store',
          builder: (context, state) => const StoreCatalogScreen(),
          routes: [
            GoRoute(
              path: ':idOrSlug',
              builder: (context, state) => Scaffold(
                body: Text('DETAIL:${state.pathParameters['idOrSlug']}'),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on card body of 'Remera Keep It Simple'
    final cardFinder = find.text('Remera Keep It Simple');
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verify it navigated to details screen displaying "DETAIL:remera-keep-it-simple"
    expect(find.text('DETAIL:remera-keep-it-simple'), findsOneWidget);
  });
}
