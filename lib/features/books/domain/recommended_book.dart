import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/config/app_config.dart';

class RecommendedBook {
  final int id;
  final String slug;
  final String title;
  final String author;
  final String description;
  final String url;
  final String image;
  final int sortOrder;

  const RecommendedBook({
    required this.id,
    required this.slug,
    required this.title,
    required this.author,
    required this.description,
    required this.url,
    required this.image,
    required this.sortOrder,
  });

  factory RecommendedBook.fromJson(Map<String, dynamic> json) {
    return RecommendedBook(
      id: json['id'] as int? ?? 0,
      slug: json['slug'] as String? ?? '',
      title: json['title'] as String? ?? '',
      author: json['author'] as String? ?? '',
      description: json['description'] as String? ?? '',
      url: json['url'] as String? ?? '',
      image: json['image'] as String? ?? '',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'slug': slug,
      'title': title,
      'author': author,
      'description': description,
      'url': url,
      'image': image,
      'sortOrder': sortOrder,
    };
  }

  String get imageUrl {
    if (image.isEmpty) return '';
    if (image.startsWith('http://') || image.startsWith('https://')) {
      return image;
    }

    if (kIsWeb && AppConfig.r2AssetsBaseUrl.isEmpty) {
      return 'assets/images/$image';
    }

    final baseUrl = AppConfig.r2AssetsBaseUrl.isEmpty
        ? 'https://assets.investepacademy.com'
        : AppConfig.r2AssetsBaseUrl;
    return '$baseUrl/$image';
  }

  RecommendedBook copyWith({
    int? id,
    String? slug,
    String? title,
    String? author,
    String? description,
    String? url,
    String? image,
    int? sortOrder,
  }) {
    return RecommendedBook(
      id: id ?? this.id,
      slug: slug ?? this.slug,
      title: title ?? this.title,
      author: author ?? this.author,
      description: description ?? this.description,
      url: url ?? this.url,
      image: image ?? this.image,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }
}
