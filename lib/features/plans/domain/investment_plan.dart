import '../../capital/domain/account_type.dart';

/// Un plan de inversión. `targetMonthlyPct` es el target de GANANCIA mensual del
/// plan. `label` puede venir nulo.
class InvestmentPlan {
  final int id;
  final AccountType accountType;
  final num targetMonthlyPct;
  final num? targetDailyPct;
  final String? label;

  const InvestmentPlan({
    required this.id,
    required this.accountType,
    required this.targetMonthlyPct,
    this.targetDailyPct,
    this.label,
  });

  num get effectiveDailyPct {
    if (targetDailyPct != null) return targetDailyPct!;
    final val = targetMonthlyPct / 20;
    return val % 1 == 0 ? val.toInt() : double.parse(val.toStringAsFixed(2));
  }

  factory InvestmentPlan.fromJson(Map<String, dynamic> json) => InvestmentPlan(
    id: (json['id'] as num).toInt(),
    accountType: AccountType.fromApi(json['accountType'] as String),
    targetMonthlyPct: json['targetMonthlyPct'] as num,
    targetDailyPct: json['targetDailyPct'] as num?,
    label: json['label'] as String?,
  );
}
