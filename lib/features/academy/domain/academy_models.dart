class AcademyFeature {
  final int id;
  final String slug;
  final String? label;

  const AcademyFeature({required this.id, required this.slug, this.label});

  factory AcademyFeature.fromJson(Map<String, dynamic> json) {
    return AcademyFeature(
      id: json['id'] as int,
      slug: json['slug'] as String,
      label: json['label'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'slug': slug, 'label': label};
}

class AcademyPlan {
  final int id;
  final String slug;
  final String? name;
  final String? subtitle;
  final double priceRegular;
  final double? priceOffer;
  final String currency;
  final List<AcademyFeature> features;

  const AcademyPlan({
    required this.id,
    required this.slug,
    this.name,
    this.subtitle,
    required this.priceRegular,
    this.priceOffer,
    required this.currency,
    required this.features,
  });

  factory AcademyPlan.fromJson(Map<String, dynamic> json) {
    return AcademyPlan(
      id: json['id'] as int,
      slug: json['slug'] as String,
      name: json['name'] as String?,
      subtitle: json['subtitle'] as String?,
      priceRegular: (json['priceRegular'] as num).toDouble(),
      priceOffer: json['priceOffer'] != null
          ? (json['priceOffer'] as num).toDouble()
          : null,
      currency: json['currency'] as String,
      features: (json['features'] as List<dynamic>)
          .map((e) => AcademyFeature.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class AcademyPlanTranslation {
  final String locale;
  final String name;
  final String? subtitle;

  const AcademyPlanTranslation({
    required this.locale,
    required this.name,
    this.subtitle,
  });

  factory AcademyPlanTranslation.fromJson(Map<String, dynamic> json) {
    return AcademyPlanTranslation(
      locale: json['locale'] as String,
      name: json['name'] as String,
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'locale': locale,
    'name': name,
    'subtitle': subtitle,
  };
}

class AcademyPlanAdmin {
  final int id;
  final String slug;
  final double priceRegular;
  final double? priceOffer;
  final String currency;
  final int sortOrder;
  final bool isActive;
  final List<AcademyPlanTranslation> translations;
  final List<int> featureIds;

  const AcademyPlanAdmin({
    required this.id,
    required this.slug,
    required this.priceRegular,
    this.priceOffer,
    required this.currency,
    required this.sortOrder,
    required this.isActive,
    required this.translations,
    required this.featureIds,
  });

  factory AcademyPlanAdmin.fromJson(Map<String, dynamic> json) {
    return AcademyPlanAdmin(
      id: json['id'] as int,
      slug: json['slug'] as String,
      priceRegular: (json['priceRegular'] as num).toDouble(),
      priceOffer: json['priceOffer'] != null
          ? (json['priceOffer'] as num).toDouble()
          : null,
      currency: json['currency'] as String,
      sortOrder: json['sortOrder'] as int,
      isActive: json['isActive'] as bool,
      translations: (json['translations'] as List<dynamic>)
          .map(
            (e) => AcademyPlanTranslation.fromJson(e as Map<String, dynamic>),
          )
          .toList(),
      featureIds: (json['featureIds'] as List<dynamic>)
          .map((e) => e as int)
          .toList(),
    );
  }
}
