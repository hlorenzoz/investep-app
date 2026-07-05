enum CompoundInterestGrouping {
  daily,
  weekly,
  monthly,
  yearly;

  String get displayName {
    switch (this) {
      case CompoundInterestGrouping.daily:
        return 'Diario';
      case CompoundInterestGrouping.weekly:
        return 'Semanal';
      case CompoundInterestGrouping.monthly:
        return 'Mensual';
      case CompoundInterestGrouping.yearly:
        return 'Anual';
    }
  }
}

class CompoundInterestPeriodResult {
  final int periodIndex;
  final String label;
  final double startBalance;
  final double yieldAmount;
  final double endBalance;
  final DateTime date;

  const CompoundInterestPeriodResult({
    required this.periodIndex,
    required this.label,
    required this.startBalance,
    required this.yieldAmount,
    required this.endBalance,
    required this.date,
  });

  @override
  String toString() {
    return 'PeriodResult($periodIndex, $label, Start: $startBalance, Yield: $yieldAmount, End: $endBalance, Date: $date)';
  }
}


