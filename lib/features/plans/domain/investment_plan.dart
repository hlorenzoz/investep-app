import '../../capital/domain/account_type.dart';

/// Un plan de inversión. `targetMonthlyPct` es el target de GANANCIA mensual del
/// plan (NO el depósito). `label` puede venir nulo.
class InvestmentPlan {
  final int id;
  final AccountType accountType;
  final num targetMonthlyPct;
  final String? label;

  const InvestmentPlan({
    required this.id,
    required this.accountType,
    required this.targetMonthlyPct,
    this.label,
  });

  factory InvestmentPlan.fromJson(Map<String, dynamic> json) => InvestmentPlan(
    id: (json['id'] as num).toInt(),
    accountType: AccountType.fromApi(json['accountType'] as String),
    targetMonthlyPct: json['targetMonthlyPct'] as num,
    label: json['label'] as String?,
  );
}
