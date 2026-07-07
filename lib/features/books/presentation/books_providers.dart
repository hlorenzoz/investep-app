import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/books_repository.dart';
import '../domain/recommended_book.dart';

/// Carga la lista de libros recomendados para el usuario.
final publicBooksProvider = FutureProvider<List<RecommendedBook>>((ref) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.fetchRecommendedBooks();
});

/// Carga la lista completa de libros para la administración.
final adminBooksProvider = FutureProvider<List<RecommendedBook>>((ref) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.fetchRecommendedBooks();
});

/// Carga el detalle de un libro por su id o slug.
final bookDetailProvider = FutureProvider.family<RecommendedBook, String>((
  ref,
  idOrSlug,
) async {
  final repository = ref.watch(booksRepositoryProvider);
  return repository.getRecommendedBook(idOrSlug);
});

/// Controlador de operaciones CRUD de administración de libros recomendados.
class BooksAdminController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<bool> createRecommendedBook(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(booksRepositoryProvider);
      await repository.createRecommendedBook(data);
      state = const AsyncValue.data(null);
      ref.invalidate(adminBooksProvider);
      ref.invalidate(publicBooksProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> updateRecommendedBook(int id, Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(booksRepositoryProvider);
      await repository.updateRecommendedBook(id, data);
      state = const AsyncValue.data(null);
      ref.invalidate(adminBooksProvider);
      ref.invalidate(publicBooksProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> deleteRecommendedBook(int id) async {
    state = const AsyncValue.loading();
    try {
      final repository = ref.read(booksRepositoryProvider);
      await repository.deleteRecommendedBook(id);
      state = const AsyncValue.data(null);
      ref.invalidate(adminBooksProvider);
      ref.invalidate(publicBooksProvider);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final booksAdminControllerProvider =
    NotifierProvider<BooksAdminController, AsyncValue<void>>(() {
      return BooksAdminController();
    });
