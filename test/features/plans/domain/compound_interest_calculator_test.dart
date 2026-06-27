import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/plans/domain/compound_interest_calculator.dart';

void main() {
  group('CompoundInterestCalculator Tests', () {
    final startDate = DateTime(2026, 1, 1);

    test('Escenario 1: Proyección Mensual de un Plan de \$900 al 25% mensual por 3 meses (90 días)', () {
      final results = CompoundInterestCalculator.calculate(
        baseAmount: 900.0,
        monthlyRatePct: 25.0,
        grouping: CompoundInterestGrouping.monthly,
        startDate: startDate,
        years: 1, // Proyecta 365 días, pero evaluaremos los primeros 3 meses
      );

      // Verificamos que se devuelvan los 12 meses del año
      expect(results.length, equals(12));

      // Primer mes (Enero 2026)
      final jan = results[0];
      expect(jan.label, equals('Ene 26'));
      expect(jan.startBalance, equals(900.0));
      // Tasa diaria: 25% / 30 = 0.008333333
      // Final Enero (31 días de Enero): 900 * (1.00833333)^31 = 1164.05
      // Rendimiento: 1164.05 - 900 = 264.05
      expect(jan.endBalance, closeTo(1164.05, 0.01));
      expect(jan.yieldAmount, closeTo(264.05, 0.01));

      // Segundo mes (Febrero 2026)
      final feb = results[1];
      expect(feb.label, equals('Feb 26'));
      expect(feb.startBalance, closeTo(1164.05, 0.01));
      // Final Febrero (28 días de Febrero): 900 * (1.00833333)^59 = 1468.54
      expect(feb.endBalance, closeTo(1468.54, 0.01));
    });

    test('Agrupamiento Diario: debe retornar 1 periodo por cada día', () {
      final results = CompoundInterestCalculator.calculate(
        baseAmount: 1000.0,
        monthlyRatePct: 10.0,
        grouping: CompoundInterestGrouping.daily,
        startDate: startDate,
        years: 1,
        filterStartDate: DateTime(2026, 1, 1),
        filterEndDate: DateTime(2026, 1, 7), // 7 días en total
      );

      expect(results.length, equals(7));
      expect(results[0].label, equals('1 Ene'));
      expect(results[6].label, equals('7 Ene'));
      expect(results[0].startBalance, equals(1000.0));
    });

    test('Agrupamiento Semanal: debe agrupar en bloques de 7 días', () {
      final results = CompoundInterestCalculator.calculate(
        baseAmount: 1000.0,
        monthlyRatePct: 10.0,
        grouping: CompoundInterestGrouping.weekly,
        startDate: startDate,
        years: 1,
        filterStartDate: DateTime(2026, 1, 1),
        filterEndDate: DateTime(2026, 1, 14), // 14 días
      );

      expect(results.length, equals(2));
      expect(results[0].label, equals('Semana 1'));
      expect(results[1].label, equals('Semana 2'));
    });

    test('Drill-down: Filtros de fecha específicos', () {
      // Si filtramos por el mes de febrero, sólo debe traer los días de febrero
      final febStart = DateTime(2026, 2, 1);
      final febEnd = DateTime(2026, 2, 28);

      final dailyFeb = CompoundInterestCalculator.calculate(
        baseAmount: 1000.0,
        monthlyRatePct: 15.0,
        grouping: CompoundInterestGrouping.daily,
        startDate: startDate,
        years: 1,
        filterStartDate: febStart,
        filterEndDate: febEnd,
      );

      expect(dailyFeb.length, equals(28));
      expect(dailyFeb.first.date, equals(febStart));
      expect(dailyFeb.last.date, equals(febEnd));
    });
  });
}
