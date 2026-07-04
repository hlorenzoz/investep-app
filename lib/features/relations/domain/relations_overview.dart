/// Modelos de la vista de referencia "Relaciones entre Activos".
///
/// Consumen el contrato de solo lectura `GET /tickers/relations-overview`, que
/// devuelve TODO agregado y agrupado por el backend. La app únicamente parsea y
/// renderiza: no reagrupa ni recalcula signos.
///
/// El parseo es DEFENSIVO a propósito (enums tolerantes a valores desconocidos,
/// `multiplier` que puede llegar como número o como string): un contrato que
/// evoluciona no debe tumbar la pantalla.
library;

/// Clase del activo base. El backend garantiza `stock` | `index` en `assets`,
/// pero se contempla [AssetClass.unknown] como fallback seguro.
///
/// Nota: el valor de índice se llama [indexAsset] (no `index`) porque todo enum
/// de Dart ya expone un getter `.index` (el ordinal) y colisionaría.
enum AssetClass {
  stock,
  indexAsset,
  unknown;

  static AssetClass fromString(String? value) {
    switch (value) {
      case 'stock':
        return AssetClass.stock;
      case 'index':
        return AssetClass.indexAsset;
      default:
        return AssetClass.unknown;
    }
  }
}

/// Tipo de relación entre un activo y su ETF asociado.
///
/// ⚠️ El backend usa exclusivamente `x2` | `x3` | `inverso`. Los antiguos
/// `leveraged_long` / `leveraged_short` / `inverse` están OBSOLETOS. Cualquier
/// valor no reconocido cae en [RelationType.unknown] (nunca crashea).
enum RelationType {
  x2,
  x3,
  inverso,
  unknown;

  static RelationType fromString(String? value) {
    switch (value) {
      case 'x2':
        return RelationType.x2;
      case 'x3':
        return RelationType.x3;
      case 'inverso':
        return RelationType.inverso;
      default:
        return RelationType.unknown;
    }
  }
}

/// Un ETF relacionado (long apalancado o inverso) dentro de una fila.
class RelationLink {
  final String symbol;
  final String name;
  final RelationType relationType;

  /// Número con signo: > 0 apalancado alcista, < 0 inverso/bajista.
  final double multiplier;
  final bool isFavorite;

  const RelationLink({
    required this.symbol,
    required this.name,
    required this.relationType,
    required this.multiplier,
    this.isFavorite = false,
  });

  factory RelationLink.fromJson(Map<String, dynamic> json) {
    return RelationLink(
      symbol: json['symbol'] as String,
      name: json['name'] as String? ?? '',
      relationType: RelationType.fromString(json['relationType'] as String?),
      multiplier: _parseMultiplier(json['multiplier']),
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  RelationLink copyWith({bool? isFavorite}) {
    return RelationLink(
      symbol: symbol,
      name: name,
      relationType: relationType,
      multiplier: multiplier,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Fila de la tabla de activos: activo principal + sus ETFs long e inversos.
class AssetRelation {
  final String symbol;
  final String name;
  final AssetClass assetClass;
  final bool isFavorite;
  final List<RelationLink> longEtfs;
  final List<RelationLink> inverseEtfs;

  const AssetRelation({
    required this.symbol,
    required this.name,
    required this.assetClass,
    required this.longEtfs,
    required this.inverseEtfs,
    this.isFavorite = false,
  });

  factory AssetRelation.fromJson(Map<String, dynamic> json) {
    return AssetRelation(
      symbol: json['symbol'] as String,
      name: json['name'] as String? ?? '',
      assetClass: AssetClass.fromString(json['assetClass'] as String?),
      isFavorite: json['isFavorite'] as bool? ?? false,
      longEtfs: _parseLinks(json['longEtfs']),
      inverseEtfs: _parseLinks(json['inverseEtfs']),
    );
  }

  AssetRelation copyWith({bool? isFavorite}) {
    return AssetRelation(
      symbol: symbol,
      name: name,
      assetClass: assetClass,
      longEtfs: longEtfs,
      inverseEtfs: inverseEtfs,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Fila de la tabla de sectores: ETF sectorial + su(s) ETF(s) inverso(s).
class SectorRelation {
  final String etf;
  final String sectorName;
  final bool isFavorite;
  final List<RelationLink> inverseEtfs;

  const SectorRelation({
    required this.etf,
    required this.sectorName,
    required this.inverseEtfs,
    this.isFavorite = false,
  });

  factory SectorRelation.fromJson(Map<String, dynamic> json) {
    return SectorRelation(
      etf: json['etf'] as String,
      sectorName: json['sectorName'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
      inverseEtfs: _parseLinks(json['inverseEtfs']),
    );
  }

  SectorRelation copyWith({bool? isFavorite}) {
    return SectorRelation(
      etf: etf,
      sectorName: sectorName,
      inverseEtfs: inverseEtfs,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}

/// Respuesta completa del endpoint. `assets` y `sectors` siempre presentes; los
/// arrays pueden venir vacíos pero nunca null.
class RelationsOverview {
  final List<AssetRelation> assets;
  final List<SectorRelation> sectors;

  const RelationsOverview({required this.assets, required this.sectors});

  factory RelationsOverview.fromJson(Map<String, dynamic> json) {
    final rawAssets = json['assets'];
    final rawSectors = json['sectors'];
    return RelationsOverview(
      assets: rawAssets is List
          ? rawAssets
                .whereType<Map<String, dynamic>>()
                .map(AssetRelation.fromJson)
                .toList()
          : const [],
      sectors: rawSectors is List
          ? rawSectors
                .whereType<Map<String, dynamic>>()
                .map(SectorRelation.fromJson)
                .toList()
          : const [],
    );
  }

  bool get isEmpty => assets.isEmpty && sectors.isEmpty;
}

/// `multiplier` puede llegar como número (2.0) o como string ("-1.00") según el
/// serializador del backend. Se parsea de forma tolerante.
double _parseMultiplier(dynamic raw) {
  if (raw is num) return raw.toDouble();
  if (raw is String) return double.tryParse(raw) ?? 0.0;
  return 0.0;
}

List<RelationLink> _parseLinks(dynamic raw) {
  if (raw is! List) return const [];
  return raw
      .whereType<Map<String, dynamic>>()
      .map(RelationLink.fromJson)
      .toList();
}
