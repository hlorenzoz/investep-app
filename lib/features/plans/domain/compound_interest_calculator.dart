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

/// Registro diario intermedio para la simulación de interés compuesto.
class _DailyProjection {
  final DateTime date;
  final double startBalance;
  final double yieldAmount;
  final double endBalance;

  const _DailyProjection({
    required this.date,
    required this.startBalance,
    required this.yieldAmount,
    required this.endBalance,
  });
}

class CompoundInterestCalculator {
  /// Proyecta el comportamiento del plan sumando el interés compuesto diario.
  ///
  /// - [baseAmount]: Monto inicial de la simulación.
  /// - [monthlyRatePct]: Porcentaje mensual del plan (ej. 25.0).
  /// - [grouping]: El agrupamiento de salida (diario, semanal, mensual, anual).
  /// - [startDate]: Fecha de inicio de la simulación (por defecto hoy).
  /// - [accountCreationDate]: Fecha de creación de la cuenta del bróker.
  /// - [years]: Años de proyección total (por defecto 3).
  /// - [filterStartDate]: Fecha de inicio del filtro visible.
  /// - [filterEndDate]: Fecha de fin del filtro visible.
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
    final totalDays = years * 365;
    final dailyRate = (monthlyRatePct / 100) / 30;

    final creation = accountCreationDate ?? start;
    final creationDay = DateTime(creation.year, creation.month, creation.day);

    // 1. Simulación diaria base
    final dailyProjections = <_DailyProjection>[];
    double currentBalance = 0.0;
    bool isActive = false;

    for (int d = 0; d < totalDays; d++) {
      final date = start.add(Duration(days: d));
      final currentDay = DateTime(date.year, date.month, date.day);

      if (currentDay.isBefore(creationDay)) {
        dailyProjections.add(_DailyProjection(
          date: date,
          startBalance: 0.0,
          yieldAmount: 0.0,
          endBalance: 0.0,
        ));
      } else {
        if (!isActive) {
          isActive = true;
          currentBalance = baseAmount;
        }
        final interest = currentBalance * dailyRate;
        final nextBalance = currentBalance + interest;

        dailyProjections.add(_DailyProjection(
          date: date,
          startBalance: currentBalance,
          yieldAmount: interest,
          endBalance: nextBalance,
        ));

        currentBalance = nextBalance;
      }
    }

    // 2. Filtrado de la serie diaria antes de agrupar (si se provee rango)
    var filteredDays = dailyProjections;
    if (filterStartDate != null) {
      filteredDays = filteredDays
          .where((d) => d.date.isAfter(filterStartDate) || d.date.isAtSameMomentAs(filterStartDate))
          .toList();
    }
    if (filterEndDate != null) {
      filteredDays = filteredDays
          .where((d) => d.date.isBefore(filterEndDate) || d.date.isAtSameMomentAs(filterEndDate))
          .toList();
    }

    if (filteredDays.isEmpty) return [];

    // 3. Agrupamiento de los días filtrados según la granularidad
    switch (grouping) {
      case CompoundInterestGrouping.daily:
        return _groupDaily(filteredDays);
      case CompoundInterestGrouping.weekly:
        return _groupWeekly(filteredDays);
      case CompoundInterestGrouping.monthly:
        return _groupMonthly(filteredDays);
      case CompoundInterestGrouping.yearly:
        return _groupYearly(filteredDays);
    }
  }

  static List<CompoundInterestPeriodResult> _groupDaily(List<_DailyProjection> days) {
    return List.generate(days.length, (index) {
      final d = days[index];
      final monthName = _monthAbbr(d.date.month);
      return CompoundInterestPeriodResult(
        periodIndex: index + 1,
        label: '${d.date.day} $monthName',
        startBalance: _round(d.startBalance),
        yieldAmount: _round(d.yieldAmount),
        endBalance: _round(d.endBalance),
        date: d.date,
      );
    });
  }

  static double _getBucketStartBalance(List<_DailyProjection> bucket) {
    final active = bucket.firstWhere(
      (d) => d.startBalance > 0 || d.endBalance > 0,
      orElse: () => bucket.first,
    );
    return active.startBalance;
  }

  static List<CompoundInterestPeriodResult> _groupWeekly(List<_DailyProjection> days) {
    final results = <CompoundInterestPeriodResult>[];
    int periodIdx = 1;

    // Agrupamos en bloques de 7 días
    for (int i = 0; i < days.length; i += 7) {
      final chunk = days.sublist(i, (i + 7 > days.length) ? days.length : i + 7);
      if (chunk.isEmpty) continue;

      final startDay = chunk.first;
      final endDay = chunk.last;
      final totalYield = chunk.fold<double>(0.0, (sum, d) => sum + d.yieldAmount);

      results.add(CompoundInterestPeriodResult(
        periodIndex: periodIdx++,
        label: 'Semana ${periodIdx - 1}',
        startBalance: _round(_getBucketStartBalance(chunk)),
        yieldAmount: _round(totalYield),
        endBalance: _round(endDay.endBalance),
        date: startDay.date,
      ));
    }
    return results;
  }

  static List<CompoundInterestPeriodResult> _groupMonthly(List<_DailyProjection> days) {
    final results = <CompoundInterestPeriodResult>[];
    final Map<String, List<_DailyProjection>> monthlyBuckets = {};

    // Agrupamos por clave "Año-Mes" para respetar meses calendario reales
    for (final d in days) {
      final key = '${d.date.year}-${d.date.month.toString().padLeft(2, '0')}';
      monthlyBuckets.putIfAbsent(key, () => []).add(d);
    }

    final sortedKeys = monthlyBuckets.keys.toList()..sort();
    int periodIdx = 1;

    for (final key in sortedKeys) {
      final bucket = monthlyBuckets[key]!;
      final startDay = bucket.first;
      final endDay = bucket.last;
      final totalYield = bucket.fold<double>(0.0, (sum, d) => sum + d.yieldAmount);

      final monthName = _monthAbbr(startDay.date.month);

      results.add(CompoundInterestPeriodResult(
        periodIndex: periodIdx++,
        label: '$monthName ${startDay.date.year.toString().substring(2)}',
        startBalance: _round(_getBucketStartBalance(bucket)),
        yieldAmount: _round(totalYield),
        endBalance: _round(endDay.endBalance),
        date: startDay.date,
      ));
    }
    return results;
  }

  static List<CompoundInterestPeriodResult> _groupYearly(List<_DailyProjection> days) {
    final results = <CompoundInterestPeriodResult>[];
    final Map<int, List<_DailyProjection>> yearlyBuckets = {};

    for (final d in days) {
      yearlyBuckets.putIfAbsent(d.date.year, () => []).add(d);
    }

    final sortedKeys = yearlyBuckets.keys.toList()..sort();
    int periodIdx = 1;

    for (final year in sortedKeys) {
      final bucket = yearlyBuckets[year]!;
      final startDay = bucket.first;
      final endDay = bucket.last;
      final totalYield = bucket.fold<double>(0.0, (sum, d) => sum + d.yieldAmount);

      results.add(CompoundInterestPeriodResult(
        periodIndex: periodIdx++,
        label: '$year',
        startBalance: _round(_getBucketStartBalance(bucket)),
        yieldAmount: _round(totalYield),
        endBalance: _round(endDay.endBalance),
        date: startDay.date,
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
