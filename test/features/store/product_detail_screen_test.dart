import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/store/data/store_repository.dart';
import 'package:investep_app/features/store/domain/product.dart';
import 'package:investep_app/features/store/presentation/product_detail_screen.dart';
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

  const testProduct = Product(
    id: 1,
    slug: 'remera-keep-it-simple',
    name: 'Remera Keep It Simple',
    description: 'Remera de algodón premium.',
    price: 29.99,
    currency: 'USD',
    image: 'shirts/remera-simple.webp',
    category: ProductCategory.tshirt,
    gender: ProductGender.men,
    theme: ProductTheme.dark,
    active: true,
    amazonUrl: 'https://amazon.com/remera-simple',
  );

  testWidgets(
    'ProductDetailScreen renders correctly with loading and loaded data',
    (tester) async {
      when(
        () => mockStoreRepository.getProduct('remera-keep-it-simple'),
      ).thenAnswer((_) async => testProduct);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProductDetailScreen(idOrSlug: 'remera-keep-it-simple'),
          ),
        ),
      );

      // Shows loading indicator initially
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verifies metadata rendered
      expect(find.text('Detalle del Producto'), findsOneWidget);
      expect(find.text('Remera Keep It Simple'), findsOneWidget);
      expect(find.text('Remera de algodón premium.'), findsOneWidget);
      expect(find.text('Hombre'), findsOneWidget);
      expect(find.text('Oscuro'), findsOneWidget);
      expect(find.text('\$29.99 USD'), findsOneWidget);
      expect(find.text('Ver en Amazon'), findsOneWidget);
    },
  );

  testWidgets(
    'ProductDetailScreen renders correctly when GoRouter extra is a serialized Map (web history restoration)',
    (tester) async {
      final Map<String, dynamic> serializedProduct = testProduct.toJson();

      final router = GoRouter(
        initialLocation: '/store',
        routes: [
          GoRoute(
            path: '/store',
            builder: (context, state) => const Scaffold(body: Text('Root')),
            routes: [
              GoRoute(
                path: ':idOrSlug',
                builder: (context, state) {
                  final idOrSlug = state.pathParameters['idOrSlug']!;
                  final extra = state.extra;
                  final product = extra is Product
                      ? extra
                      : (extra is Map
                            ? Product.fromJson(Map<String, dynamic>.from(extra))
                            : null);
                  return ProductDetailScreen(
                    idOrSlug: idOrSlug,
                    product: product,
                  );
                },
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

      // Navigate to detail route passing the serialized map as extra
      router.go('/store/remera-keep-it-simple', extra: serializedProduct);
      await tester.pumpAndSettle();

      // Verify it deserialized the Map and rendered the details immediately without loading indicator
      expect(find.text('Remera Keep It Simple'), findsOneWidget);
      expect(find.text('Remera de algodón premium.'), findsOneWidget);
      expect(find.text('\$29.99 USD'), findsOneWidget);
    },
  );
}
