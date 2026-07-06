import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/retry.dart';
import '../domain/product.dart';

class StoreRepository {
  StoreRepository(
    this._dio, {
    Duration retryBaseDelay = const Duration(milliseconds: 500),
  }) : _retryBaseDelay = retryBaseDelay;

  final Dio _dio;
  final Duration _retryBaseDelay;
  static const _maxAttempts = 3;

  /// `GET /tienda` → Obtener catálogo de productos.
  /// Soporta filtros por category, gender, theme, active.
  Future<List<Product>> fetchProducts({
    String? category,
    String? gender,
    String? theme,
    bool? active,
  }) {
    return retryWithBackoff(
      () async {
        final queryParams = <String, dynamic>{};
        if (category != null && category.isNotEmpty) {
          queryParams['category'] = category;
        }
        if (gender != null && gender.isNotEmpty) {
          queryParams['gender'] = gender;
        }
        if (theme != null && theme.isNotEmpty) {
          queryParams['theme'] = theme;
        }
        if (active != null) {
          queryParams['active'] = active.toString();
        }

        final res = await _dio.get<Map<String, dynamic>>(
          '/tienda',
          queryParameters: queryParams,
        );

        final rawProducts = res.data?['products'];
        if (rawProducts is List) {
          return rawProducts
              .whereType<Map<String, dynamic>>()
              .map(Product.fromJson)
              .toList();
        }
        return const [];
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `GET /tienda/{idOrSlug}` → Detalle del producto.
  Future<Product> getProduct(String idOrSlug) {
    return retryWithBackoff(
      () async {
        final res = await _dio.get<Map<String, dynamic>>('/tienda/$idOrSlug');
        final json = res.data!['product'] as Map<String, dynamic>;
        return Product.fromJson(json);
      },
      baseDelay: _retryBaseDelay,
      maxAttempts: _maxAttempts,
    );
  }

  /// `POST /admin/tienda` → Crear un producto nuevo (admin).
  Future<Product> createProduct(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/admin/tienda',
        data: data,
      );
      final json = res.data!['product'] as Map<String, dynamic>;
      return Product.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /admin/tienda/{id}` → Modificar un producto (admin).
  Future<Product> updateProduct(int id, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(
        '/admin/tienda/$id',
        data: data,
      );
      final json = res.data!['product'] as Map<String, dynamic>;
      return Product.fromJson(json);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `DELETE /admin/tienda/{id}` → Eliminar un producto (admin).
  Future<void> deleteProduct(int id) async {
    try {
      await _dio.delete<void>('/admin/tienda/$id');
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}

final storeRepositoryProvider = Provider<StoreRepository>((ref) {
  return StoreRepository(ref.watch(apiClientProvider));
});
