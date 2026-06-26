/// Un broker disponible para configurar una cuenta.
///
/// `id` es numérico (coincide con `brokerId` de las allocations). Los assets
/// (logo/icon/favicon/url) son opcionales.
class Broker {
  final int id;
  final String slug;
  final String name;
  final String? url;
  final String? urlSecondary;
  final String? logo;
  final String? icon;
  final String? favicon;

  const Broker({
    required this.id,
    required this.slug,
    required this.name,
    this.url,
    this.urlSecondary,
    this.logo,
    this.icon,
    this.favicon,
  });

  factory Broker.fromJson(Map<String, dynamic> json) => Broker(
    id: (json['id'] as num).toInt(),
    slug: json['slug'] as String,
    name: json['name'] as String,
    url: json['url'] as String?,
    urlSecondary: json['urlSecondary'] as String?,
    logo: json['logo'] as String?,
    icon: json['icon'] as String?,
    favicon: json['favicon'] as String?,
  );
}
