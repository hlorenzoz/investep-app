import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/features/store/data/store_repository.dart';
import 'package:investep_app/features/store/domain/product.dart';
import 'package:investep_app/features/store/presentation/store_providers.dart';
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
    Product(
      id: 1,
      slug: 'test-book',
      name: 'Test Book',
      description: 'A test book',
      category: ProductCategory.book,
      gender: null,
      theme: null,
      price: 19.99,
      currency: 'USD',
      amazonUrl: 'https://amazon.com/test-book',
      image: 'images/test-book.png',
      active: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
    Product(
      id: 2,
      slug: 'test-tshirt',
      name: 'Test Tshirt',
      description: 'A test tshirt',
      category: ProductCategory.tshirt,
      gender: ProductGender.men,
      theme: ProductTheme.dark,
      price: 24.99,
      currency: 'USD',
      amazonUrl: null,
      image: 'images/test-tshirt.png',
      active: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    ),
  ];

  test('publicProductsProvider fetches active products and respects category filter', () async {
    when(() => mockStoreRepository.fetchProducts(category: null, active: true))
        .thenAnswer((_) async => testProducts);

    when(() => mockStoreRepository.fetchProducts(category: 'book', active: true))
        .thenAnswer((_) async => [testProducts[0]]);

    // Initially category filter is null, should fetch all
    final productsVal1 = await container.read(publicProductsProvider.future);
    expect(productsVal1, testProducts);
    verify(() => mockStoreRepository.fetchProducts(category: null, active: true)).called(1);

    // Change filter to book
    container.read(publicCategoryFilterProvider.notifier).setFilter(ProductCategory.book);

    final productsVal2 = await container.read(publicProductsProvider.future);
    expect(productsVal2, [testProducts[0]]);
    verify(() => mockStoreRepository.fetchProducts(category: 'book', active: true)).called(1);
  });

  test('adminProductsProvider fetches all products without active filter', () async {
    when(() => mockStoreRepository.fetchProducts())
        .thenAnswer((_) async => testProducts);

    final products = await container.read(adminProductsProvider.future);
    expect(products, testProducts);
    verify(() => mockStoreRepository.fetchProducts()).called(1);
  });

  test('storeAdminControllerProvider can create, update, and delete products', () async {
    final newProductData = <String, dynamic>{
      'slug': 'new-cap',
      'name': 'New Cap',
      'category': 'cap',
      'price': 15.0,
      'currency': 'USD',
      'active': true,
    };

    when(() => mockStoreRepository.createProduct(newProductData))
        .thenAnswer((_) async => testProducts[0]);
    when(() => mockStoreRepository.updateProduct(1, newProductData))
        .thenAnswer((_) async => testProducts[0]);
    when(() => mockStoreRepository.deleteProduct(1))
        .thenAnswer((_) async => null);

    final controller = container.read(storeAdminControllerProvider.notifier);

    // Create
    final createSuccess = await controller.createProduct(newProductData);
    expect(createSuccess, isTrue);
    verify(() => mockStoreRepository.createProduct(newProductData)).called(1);

    // Update
    final updateSuccess = await controller.updateProduct(1, newProductData);
    expect(updateSuccess, isTrue);
    verify(() => mockStoreRepository.updateProduct(1, newProductData)).called(1);

    // Delete
    final deleteSuccess = await controller.deleteProduct(1);
    expect(deleteSuccess, isTrue);
    verify(() => mockStoreRepository.deleteProduct(1)).called(1);
  });
}
