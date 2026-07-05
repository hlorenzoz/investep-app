import '../../capital/domain/account_type.dart';

/// Formatea una fecha como `YYYY-MM-DD` (día calendario local) para el contrato
/// de operaciones. El backend acepta esta forma y la normaliza a medianoche UTC.
///
/// Mandar el datetime completo local (`toIso8601String()` → sin `Z`) rompía la
/// validación ISO del servidor y devolvía 422. Usamos el día calendario que el
/// usuario eligió en el date-picker, que es también la unidad con la que el
/// backend compara "venta ≥ compra".
String operationApiDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Modelo de datos para representar una operación de trading (Journal).
class Operation {
  final String id;
  final String allocationId;
  final AccountType accountType;
  final String ticker;
  final DateTime openedAt;
  final double quantity;
  final double buyPrice;
  final double? limitPrice;
  final DateTime? soldAt;
  final double? sellPrice;
  final String? strategy;
  final String? notes;
  final String? url;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Campos Derivados por la API (Solo Lectura)
  final String status;
  final double totalInvested;
  final double? totalSale;
  final double? gainAmount;
  final double? gainPct;

  // Campos Exclusivos de Opciones (Null en Activos)
  final double? strike;
  final String? expirationDate; // Formato YYYY-MM-DD
  final String? contractType;   // 'call' | 'put'

  const Operation({
    required this.id,
    required this.allocationId,
    required this.accountType,
    required this.ticker,
    required this.openedAt,
    required this.quantity,
    required this.buyPrice,
    this.limitPrice,
    this.soldAt,
    this.sellPrice,
    this.strategy,
    this.notes,
    this.url,
    this.createdAt,
    this.updatedAt,
    required this.status,
    required this.totalInvested,
    this.totalSale,
    this.gainAmount,
    this.gainPct,
    this.strike,
    this.expirationDate,
    this.contractType,
  });

  bool get isOpen => soldAt == null;
  bool get isClosed => soldAt != null;

  factory Operation.fromJson(Map<String, dynamic> json) {
    return Operation(
      id: json['id'] as String,
      allocationId: json['allocationId'] as String,
      accountType: AccountType.fromApi(json['accountType'] as String),
      ticker: json['ticker'] as String,
      openedAt: DateTime.parse(json['openedAt'] as String),
      quantity: (json['quantity'] as num).toDouble(),
      buyPrice: (json['buyPrice'] as num).toDouble(),
      limitPrice: json['limitPrice'] != null ? (json['limitPrice'] as num).toDouble() : null,
      soldAt: json['soldAt'] != null ? DateTime.parse(json['soldAt'] as String) : null,
      sellPrice: json['sellPrice'] != null ? (json['sellPrice'] as num).toDouble() : null,
      strategy: json['strategy'] as String?,
      notes: json['notes'] as String?,
      url: json['url'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
      
      // Campos derivados
      status: json['status'] as String? ?? (json['soldAt'] == null ? 'open' : 'closed'),
      totalInvested: (json['totalInvested'] as num).toDouble(),
      totalSale: json['totalSale'] != null ? (json['totalSale'] as num).toDouble() : null,
      gainAmount: json['gainAmount'] != null ? (json['gainAmount'] as num).toDouble() : null,
      gainPct: json['gainPct'] != null ? (json['gainPct'] as num).toDouble() : null,
      
      // Campos de opciones
      strike: json['strike'] != null ? (json['strike'] as num).toDouble() : null,
      expirationDate: json['expirationDate'] as String?,
      contractType: json['contractType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'allocationId': allocationId,
      'accountType': accountType.toApi(),
      'ticker': ticker,
      'openedAt': openedAt.toIso8601String(),
      'quantity': quantity,
      'buyPrice': buyPrice,
      'limitPrice': limitPrice,
      'soldAt': soldAt?.toIso8601String(),
      'sellPrice': sellPrice,
      'strategy': strategy,
      'notes': notes,
      'url': url,
      'strike': strike,
      'expirationDate': expirationDate,
      'contractType': contractType,
    };
  }
}
