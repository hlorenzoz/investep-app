import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/recommended_book.dart';

class BooksRepository {
  BooksRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /recommended-books` → Listar libros recomendados.
  Future<List<RecommendedBook>> fetchRecommendedBooks() {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/recommended-books');
        final rawBooks = res.data?['recommendedBooks'];
        if (rawBooks is List) {
          return rawBooks
              .whereType<Map<String, dynamic>>()
              .map(RecommendedBook.fromJson)
              .toList();
        }
        return const [];
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /recommended-books/{idOrSlug}` → Detalle de un libro.
  Future<RecommendedBook> getRecommendedBook(String idOrSlug) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/recommended-books/$idOrSlug',
        );
        final json = res.data!['recommendedBook'] as Map<String, dynamic>;
        return RecommendedBook.fromJson(json);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/recommended-books` → Crear un libro (admin).
  Future<RecommendedBook> createRecommendedBook(
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/recommended-books',
        data: data,
      );
      final json = res.data!['recommendedBook'] as Map<String, dynamic>;
      return RecommendedBook.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /admin/recommended-books/{id}` → Actualizar un libro (admin).
  Future<RecommendedBook> updateRecommendedBook(
    int id,
    Map<String, dynamic> data,
  ) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/admin/recommended-books/$id',
        data: data,
      );
      final json = res.data!['recommendedBook'] as Map<String, dynamic>;
      return RecommendedBook.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/recommended-books/{id}` → Eliminar un libro (admin).
  Future<bool> deleteRecommendedBook(int id) async {
    try {
      final res = await _dio.delete<Map<String, dynamic>>(
        '/admin/recommended-books/$id',
      );
      return res.data?['deleted'] as bool? ?? false;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final booksRepositoryProvider = Provider<BooksRepository>((ref) {
  return BooksRepository(ref.watch(apiClientProvider));
});
