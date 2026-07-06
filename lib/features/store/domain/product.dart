import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/config/app_config.dart';

enum ProductCategory {
  book,
  tshirt,
  cap,
  unknown;

  static ProductCategory fromString(String? value) {
    switch (value) {
      case 'book':
        return ProductCategory.book;
      case 'tshirt':
        return ProductCategory.tshirt;
      case 'cap':
        return ProductCategory.cap;
      default:
        return ProductCategory.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case ProductCategory.book:
        return 'book';
      case ProductCategory.tshirt:
        return 'tshirt';
      case ProductCategory.cap:
        return 'cap';
      default:
        return 'unknown';
    }
  }
}

enum ProductGender {
  men,
  women,
  unknown;

  static ProductGender? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'men':
        return ProductGender.men;
      case 'women':
        return ProductGender.women;
      default:
        return ProductGender.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case ProductGender.men:
        return 'men';
      case ProductGender.women:
        return 'women';
      default:
        return 'unknown';
    }
  }
}

enum ProductTheme {
  light,
  dark,
  unknown;

  static ProductTheme? fromString(String? value) {
    if (value == null) return null;
    switch (value) {
      case 'light':
        return ProductTheme.light;
      case 'dark':
        return ProductTheme.dark;
      default:
        return ProductTheme.unknown;
    }
  }

  String toJson() {
    switch (this) {
      case ProductTheme.light:
        return 'light';
      case ProductTheme.dark:
        return 'dark';
      default:
        return 'unknown';
    }
  }
}

class Product {
  final int id;
  final String slug;
  final String name;
  final String? description;
  final ProductCategory category;
  final ProductGender? gender;
  final ProductTheme? theme;
  final double? price;
  final String currency;
  final String? amazonUrl;
  final String? image;
  final bool active;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Product({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.category,
    this.gender,
    this.theme,
    this.price,
    this.currency = 'USD',
    this.amazonUrl,
    this.image,
    required this.active,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      category: ProductCategory.fromString(json['category'] as String?),
      gender: ProductGender.fromString(json['gender'] as String?),
      theme: ProductTheme.fromString(json['theme'] as String?),
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      currency: json['currency'] as String? ?? 'USD',
      amazonUrl: json['amazonUrl'] as String?,
      image: json['image'] as String?,
      active: json['active'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'name': name,
      'description': description,
      'category': category.toJson(),
      'gender': gender?.toJson(),
      'theme': theme?.toJson(),
      'price': price,
      'currency': currency,
      'amazonUrl': amazonUrl,
      'image': image,
      'active': active,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  /// Resuelve la URL de la imagen del producto usando la URL base de R2
  /// o fallback para el catálogo local web si es necesario.
  String get imageUrl {
    if (image == null || image!.isEmpty) return '';
    if (image!.startsWith('http://') || image!.startsWith('https://')) {
      return image!;
    }

    // Si estamos en web y no tenemos R2AssetsBaseUrl configurado, usar fallback
    // reescribiendo el path store/ => assets/images/ para resolver localmente.
    if (kIsWeb && AppConfig.r2AssetsBaseUrl.isEmpty) {
      if (image!.startsWith('store/')) {
        return image!.replaceFirst('store/', 'assets/images/');
      }
      return 'assets/images/$image';
    }

    final baseUrl = AppConfig.r2AssetsBaseUrl.isEmpty
        ? 'https://assets.investepacademy.com'
        : AppConfig.r2AssetsBaseUrl;
    return '$baseUrl/$image';
  }

  Product copyWith({
    int? id,
    String? slug,
    String? name,
    String? description,
    ProductCategory? category,
    ProductGender? gender,
    ProductTheme? theme,
    double? price,
    String? currency,
    String? amazonUrl,
    String? image,
    bool? active,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      name: name ?? this.name,
      description: description ?? this.description,
      category: category ?? this.category,
      gender: gender ?? this.gender,
      theme: theme ?? this.theme,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      amazonUrl: amazonUrl ?? this.amazonUrl,
      image: image ?? this.image,
      active: active ?? this.active,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
