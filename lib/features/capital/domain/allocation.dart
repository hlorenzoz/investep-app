import 'account_type.dart';

/// Una cuenta de broker configurada (allocation de capital).
///
/// `brokerId` e `investmentPlanId` son numéricos en el contrato. La moneda
/// siempre coincide con la del capital (no editable a nivel allocation).
class Allocation {
  final String id;
  final int brokerId;
  final String brokerSlug;
  final AccountType accountType;
  final int investmentPlanId;
  final num targetMonthlyPct;
  final num initialDeposit;
  final String currency;
  final DateTime? createdAt;

  const Allocation({
    required this.id,
    required this.brokerId,
    required this.brokerSlug,
    required this.accountType,
    required this.investmentPlanId,
    required this.targetMonthlyPct,
    required this.initialDeposit,
    required this.currency,
    this.createdAt,
  });

  factory Allocation.fromJson(Map<String, dynamic> json) => Allocation(
    id: json['id'] as String,
    brokerId: (json['brokerId'] as num).toInt(),
    brokerSlug: json['brokerSlug'] as String,
    accountType: AccountType.fromApi(json['accountType'] as String),
    investmentPlanId: (json['investmentPlanId'] as num).toInt(),
    targetMonthlyPct: json['targetMonthlyPct'] as num,
    initialDeposit: json['initialDeposit'] as num,
    currency: json['currency'] as String,
    createdAt: json['createdAt'] != null
        ? DateTime.tryParse(json['createdAt'] as String)
        : null,
  );
}
