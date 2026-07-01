/// Representa un activo financiero (Ticker) en el sistema.
class Ticker {
  final int id;
  final String symbol;
  final String name;
  final String assetClass; // stock, etf, index, crypto, commodity, currency
  final String? exchange;
  final String? sector;
  final String? industry;
  final String? country;
  final double? price;
  final double? changePct;
  final double? prevClose;
  final int? volume;
  final int? avgVolume;
  final double? fiftyTwoWHigh;
  final double? fiftyTwoWLow;
  final double? marketCap;
  final double? peRatio;
  final double? forwardPe;
  final double? pegRatio;
  final double? psRatio;
  final double? pbRatio;
  final double? dividendYield;
  final Map<String, dynamic> financials;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Ticker({
    required this.id,
    required this.symbol,
    required this.name,
    required this.assetClass,
    this.exchange,
    this.sector,
    this.industry,
    this.country,
    this.price,
    this.changePct,
    this.prevClose,
    this.volume,
    this.avgVolume,
    this.fiftyTwoWHigh,
    this.fiftyTwoWLow,
    this.marketCap,
    this.peRatio,
    this.forwardPe,
    this.pegRatio,
    this.psRatio,
    this.pbRatio,
    this.dividendYield,
    required this.financials,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Ticker.fromJson(Map<String, dynamic> json) {
    return Ticker(
      id: (json['id'] as num).toInt(),
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      assetClass: json['assetClass'] as String? ?? 'stock',
      exchange: json['exchange'] as String?,
      sector: json['sector'] as String?,
      industry: json['industry'] as String?,
      country: json['country'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      changePct: (json['changePct'] as num?)?.toDouble(),
      prevClose: (json['prevClose'] as num?)?.toDouble(),
      volume: (json['volume'] as num?)?.toInt(),
      avgVolume: (json['avgVolume'] as num?)?.toInt(),
      fiftyTwoWHigh: (json['fiftyTwoWHigh'] as num?)?.toDouble(),
      fiftyTwoWLow: (json['fiftyTwoWLow'] as num?)?.toDouble(),
      marketCap: (json['marketCap'] as num?)?.toDouble(),
      peRatio: (json['peRatio'] as num?)?.toDouble(),
      forwardPe: (json['forwardPe'] as num?)?.toDouble(),
      pegRatio: (json['pegRatio'] as num?)?.toDouble(),
      psRatio: (json['psRatio'] as num?)?.toDouble(),
      pbRatio: (json['pbRatio'] as num?)?.toDouble(),
      dividendYield: (json['dividendYield'] as num?)?.toDouble(),
      financials: json['financials'] as Map<String, dynamic>? ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'symbol': symbol,
      'name': name,
      'assetClass': assetClass,
      'exchange': exchange,
      'sector': sector,
      'industry': industry,
      'country': country,
      'price': price,
      'changePct': changePct,
      'prevClose': prevClose,
      'volume': volume,
      'avgVolume': avgVolume,
      'fiftyTwoWHigh': fiftyTwoWHigh,
      'fiftyTwoWLow': fiftyTwoWLow,
      'marketCap': marketCap,
      'peRatio': peRatio,
      'forwardPe': forwardPe,
      'pegRatio': pegRatio,
      'psRatio': psRatio,
      'pbRatio': pbRatio,
      'dividendYield': dividendYield,
      'financials': financials,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

/// Representa la información de una relación financiera entre activos.
class TickerRelationInfo {
  final String symbol;
  final String name;
  final String
  relationType; // leveraged_long, leveraged_short, inverse, underlying, peer
  final double multiplier;

  const TickerRelationInfo({
    required this.symbol,
    required this.name,
    required this.relationType,
    required this.multiplier,
  });

  factory TickerRelationInfo.fromJson(Map<String, dynamic> json) {
    return TickerRelationInfo(
      symbol: json['symbol'] as String,
      name: json['name'] as String,
      relationType: json['relationType'] as String,
      multiplier: (json['multiplier'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'relationType': relationType,
      'multiplier': multiplier,
    };
  }
}

/// Detalle completo de un activo, incluyendo sus relaciones y planes asociados.
class TickerDetail {
  final Ticker ticker;
  final List<TickerRelationInfo> relations;
  final List<String> plans; // Slugs de los planes (ej: ["gold", "platinum"])

  const TickerDetail({
    required this.ticker,
    required this.relations,
    required this.plans,
  });

  factory TickerDetail.fromJson(Map<String, dynamic> json) {
    final ticker = Ticker.fromJson(json);
    final relationsList = json['relations'] as List<dynamic>? ?? [];
    final plansList = json['plans'] as List<dynamic>? ?? [];

    return TickerDetail(
      ticker: ticker,
      relations: relationsList
          .map((e) => TickerRelationInfo.fromJson(e as Map<String, dynamic>))
          .toList(),
      plans: plansList.map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      ...ticker.toJson(),
      'relations': relations.map((e) => e.toJson()).toList(),
      'plans': plans,
    };
  }
}

/// Respuesta paginada que contiene un listado de tickers y metadatos de paginación.
class PaginatedTickers {
  final List<Ticker> tickers;
  final int page;
  final int limit;
  final int total;

  const PaginatedTickers({
    required this.tickers,
    required this.page,
    required this.limit,
    required this.total,
  });

  factory PaginatedTickers.fromJson(Map<String, dynamic> json) {
    final list = json['tickers'] as List<dynamic>? ?? [];
    final pagination = json['pagination'] as Map<String, dynamic>? ?? {};

    return PaginatedTickers(
      tickers: list
          .map((e) => Ticker.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: (pagination['page'] as num? ?? 1).toInt(),
      limit: (pagination['limit'] as num? ?? 20).toInt(),
      total: (pagination['total'] as num? ?? 0).toInt(),
    );
  }
}
