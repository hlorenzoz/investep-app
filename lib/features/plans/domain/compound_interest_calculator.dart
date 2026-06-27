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

class CompoundInterestCalculator {
  /// Proyecta el comportamiento del plan sumando el interés compuesto según la tasa
  /// correspondiente a cada iteración de la agrupación seleccionada.
  ///
  /// Todas las agrupaciones parten exactamente del día de creación de la cuenta
  /// (`accountCreationDate`) con el monto inicial (`baseAmount`).
  static List<CompoundInterestPeriodResult> calculate({
    required double baseAmount,
    required double monthlyRatePct,
    required CompoundInterestGrouping grouping,
    DateTime? startDate,
    DateTime? accountCreationDate,
    int years = 3,
    DateTime? filterStartDate,
    DateTime? filterEndDate,
  }) {
    final start = startDate ?? DateTime.now();
    final creation = accountCreationDate ?? start;

    List<CompoundInterestPeriodResult> rawPeriods;
    switch (grouping) {
      case CompoundInterestGrouping.daily:
        rawPeriods = _calculateDaily(
          baseAmount: baseAmount,
          monthlyRatePct: monthlyRatePct,
          creationDate: creation,
          years: years,
        );
        break;
      case CompoundInterestGrouping.weekly:
        rawPeriods = _calculateWeekly(
          baseAmount: baseAmount,
          monthlyRatePct: monthlyRatePct,
          creationDate: creation,
          years: years,
        );
        break;
      case CompoundInterestGrouping.monthly:
        rawPeriods = _calculateMonthly(
          baseAmount: baseAmount,
          monthlyRatePct: monthlyRatePct,
          creationDate: creation,
          years: years,
        );
        break;
      case CompoundInterestGrouping.yearly:
        rawPeriods = _calculateYearly(
          baseAmount: baseAmount,
          monthlyRatePct: monthlyRatePct,
          creationDate: creation,
          years: years,
        );
        break;
    }

    // Filtrado por rango de fecha si se especifica
    var filtered = rawPeriods;
    if (filterStartDate != null) {
      filtered = filtered
          .where((p) => p.date.isAfter(filterStartDate) || p.date.isAtSameMomentAs(filterStartDate))
          .toList();
    }
    if (filterEndDate != null) {
      filtered = filtered
          .where((p) => p.date.isBefore(filterEndDate) || p.date.isAtSameMomentAs(filterEndDate))
          .toList();
    }

    // Re-indexar periodIndex para presentar 1..N en la lista resultante
    return List.generate(filtered.length, (index) {
      final p = filtered[index];
      return CompoundInterestPeriodResult(
        periodIndex: index + 1,
        label: p.label,
        startBalance: p.startBalance,
        yieldAmount: p.yieldAmount,
        endBalance: p.endBalance,
        date: p.date,
      );
    });
  }

  static List<CompoundInterestPeriodResult> _calculateMonthly({
    required double baseAmount,
    required double monthlyRatePct,
    required DateTime creationDate,
    required int years,
  }) {
    final results = <CompoundInterestPeriodResult>[];
    final totalMonths = years * 12;
    final rate = monthlyRatePct / 100;

    double currentBalance = baseAmount;

    for (int m = 0; m < totalMonths; m++) {
      final date = DateTime(creationDate.year, creationDate.month + m, creationDate.day);
      final monthName = _monthAbbr(date.month);
      final label = '$monthName ${date.year.toString().substring(2)}';

      final startBal = currentBalance;
      final yieldAmt = startBal * rate;
      final endBal = startBal + yieldAmt;

      results.add(CompoundInterestPeriodResult(
        periodIndex: m + 1,
        label: label,
        startBalance: _round(startBal),
        yieldAmount: _round(yieldAmt),
        endBalance: _round(endBal),
        date: date,
      ));

      currentBalance = endBal;
    }
    return results;
  }

  static List<CompoundInterestPeriodResult> _calculateWeekly({
    required double baseAmount,
    required double monthlyRatePct,
    required DateTime creationDate,
    required int years,
  }) {
    final results = <CompoundInterestPeriodResult>[];
    final totalWeeks = years * 12 * 4;
    final weeklyRate = (monthlyRatePct / 4) / 100;

    double currentBalance = baseAmount;

    for (int w = 0; w < totalWeeks; w++) {
      final date = creationDate.add(Duration(days: w * 7));

      final startBal = currentBalance;
      final yieldAmt = startBal * weeklyRate;
      final endBal = startBal + yieldAmt;

      results.add(CompoundInterestPeriodResult(
        periodIndex: w + 1,
        label: 'Semana ${w + 1}',
        startBalance: _round(startBal),
        yieldAmount: _round(yieldAmt),
        endBalance: _round(endBal),
        date: date,
      ));

      currentBalance = endBal;
    }
    return results;
  }

  static List<CompoundInterestPeriodResult> _calculateDaily({
    required double baseAmount,
    required double monthlyRatePct,
    required DateTime creationDate,
    required int years,
  }) {
    final results = <CompoundInterestPeriodResult>[];
    final totalDays = years * 12 * 20; // 20 días operativos por mes
    final dailyRate = (monthlyRatePct / 20) / 100;

    double currentBalance = baseAmount;

    for (int d = 0; d < totalDays; d++) {
      final date = creationDate.add(Duration(days: d));
      final monthName = _monthAbbr(date.month);

      final startBal = currentBalance;
      final yieldAmt = startBal * dailyRate;
      final endBal = startBal + yieldAmt;

      results.add(CompoundInterestPeriodResult(
        periodIndex: d + 1,
        label: '${date.day} $monthName',
        startBalance: _round(startBal),
        yieldAmount: _round(yieldAmt),
        endBalance: _round(endBal),
        date: date,
      ));

      currentBalance = endBal;
    }
    return results;
  }

  static List<CompoundInterestPeriodResult> _calculateYearly({
    required double baseAmount,
    required double monthlyRatePct,
    required DateTime creationDate,
    required int years,
  }) {
    final results = <CompoundInterestPeriodResult>[];
    final monthlySeries = _calculateMonthly(
      baseAmount: baseAmount,
      monthlyRatePct: monthlyRatePct,
      creationDate: creationDate,
      years: years,
    );

    for (int y = 0; y < years; y++) {
      final yearMonths = monthlySeries.sublist(y * 12, (y + 1) * 12);
      final startBal = yearMonths.first.startBalance;
      final endBal = yearMonths.last.endBalance;
      final yieldAmt = endBal - startBal;
      final yearLabel = '${creationDate.year + y}';

      results.add(CompoundInterestPeriodResult(
        periodIndex: y + 1,
        label: yearLabel,
        startBalance: _round(startBal),
        yieldAmount: _round(yieldAmt),
        endBalance: _round(endBal),
        date: yearMonths.first.date,
      ));
    }
    return results;
  }

  static double _round(double val) {
    return double.parse(val.toStringAsFixed(2));
  }

  static String _monthAbbr(int month) {
    switch (month) {
      case 1:
        return 'Ene';
      case 2:
        return 'Feb';
      case 3:
        return 'Mar';
      case 4:
        return 'Abr';
      case 5:
        return 'May';
      case 6:
        return 'Jun';
      case 7:
        return 'Jul';
      case 8:
        return 'Ago';
      case 9:
        return 'Sep';
      case 10:
        return 'Oct';
      case 11:
        return 'Nov';
      case 12:
        return 'Dic';
      default:
        return '';
    }
  }
}
