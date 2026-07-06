import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/store_repository.dart';
import '../domain/product.dart';

class PublicCategoryFilterNotifier extends Notifier<ProductCategory?> {
  @override
  ProductCategory? build() => null;

  void setFilter(ProductCategory? filter) {
    state = filter;
  }
}

/// Filtro seleccionado en la vista pública: null (Todos), 'book' (Libros), 'tshirt' (Remeras), 'cap' (Gorras).
final publicCategoryFilterProvider =
    NotifierProvider<PublicCategoryFilterNotifier, ProductCategory?>(() {
      return PublicCategoryFilterNotifier();
    });

/// Carga los productos activos filtrados por categoría.
final publicProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(storeRepositoryProvider);
  final filter = ref.watch(publicCategoryFilterProvider);

  // Mapear ProductCategory enum a String para la query
  String? categoryQuery;
  if (filter != null && filter != ProductCategory.unknown) {
    categoryQuery = filter.toJson();
  }

  return repository.fetchProducts(category: categoryQuery, active: true);
});

/// Carga la lista completa de productos para administración (incluyendo inactivos).
final adminProductsProvider = FutureProvider<List<Product>>((ref) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.fetchProducts(); // Devuelve todos sin filtrar active
});

/// Carga un producto por su id o slug.
final productDetailProvider = FutureProvider.family<Product, String>((
  ref,
  idOrSlug,
) async {
  final repository = ref.watch(storeRepositoryProvider);
  return repository.getProduct(idOrSlug);
});

/// Controlador para las operaciones de escritura/modificación del catálogo (admin).
class StoreAdminController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> createProduct(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(storeRepositoryProvider);
      await repository.createProduct(data);
      state = const AsyncValue.data(null);
      // Invalidamos el catálogo de administración y el público para que se recarguen
      ref.invalidate(adminProductsProvider);
      ref.invalidate(publicProductsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateProduct(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(storeRepositoryProvider);
      await repository.updateProduct(id, data);
      state = const AsyncValue.data(null);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(publicProductsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteProduct(int id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(storeRepositoryProvider);
      await repository.deleteProduct(id);
      state = const AsyncValue.data(null);
      ref.invalidate(adminProductsProvider);
      ref.invalidate(publicProductsProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final storeAdminControllerProvider =
    NotifierProvider<StoreAdminController, AsyncValue<void>>(() {
      return StoreAdminController();
    });
