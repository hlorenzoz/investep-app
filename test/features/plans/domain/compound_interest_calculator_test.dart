import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/plans/domain/compound_interest_calculator.dart';

void main() {
  group('CompoundInterestCalculator Tests', () {
    final startDate = DateTime(2026, 6, 1);

    void verifySeriesIntegrity(List<CompoundInterestPeriodResult> series) {
      for (int i = 0; i < series.length; i++) {
        final p = series[i];
        // 1. Integridad aritmética interna: Saldo Inicial + Rendimiento == Saldo Final (con tolerancia de 0.01 por redondeo de moneda)
        final expectedEnd = double.parse((p.startBalance + p.yieldAmount).toStringAsFixed(2));
        expect(p.endBalance, equals(expectedEnd),
            reason: 'Error aritmético en el período ${p.label} (${p.periodIndex})');

        // 2. Continuidad entre períodos consecutivos: Saldo Final(i) == Saldo Inicial(i+1)
        if (i > 0) {
          final prev = series[i - 1];
          expect(p.startBalance, equals(prev.endBalance),
              reason: 'Discrepancia de continuidad entre ${prev.label} y ${p.label}');
        }
      }
    }

    test('Cálculo Diario: verificación de fórmula, crecimiento e integridad de serie', () {
      final daily = CompoundInterestCalculator.calculate(
        baseAmount: 12000.0,
        monthlyRatePct: 25.0,
        grouping: CompoundInterestGrouping.daily,
        accountCreationDate: startDate,
        years: 1,
      );

      expect(daily.length, equals(240)); // 12 meses * 20 días operativos

      // Día 1: 12,000 * 1.25% (0.0125) = 150.0 -> Final 12,150.0
      expect(daily[0].startBalance, equals(12000.0));
      expect(daily[0].yieldAmount, equals(150.0));
      expect(daily[0].endBalance, equals(12150.0));

      // Día 2: Saldo Inicial es 12,150.0, Rendimiento es 12,150 * 1.25% = 151.88 -> Final 12,301.88
      expect(daily[1].startBalance, equals(12150.0));
      expect(daily[1].yieldAmount, equals(151.88));
      expect(daily[1].endBalance, equals(12301.88));

      expect(daily[1].yieldAmount > daily[0].yieldAmount, isTrue);

      verifySeriesIntegrity(daily);
    });

    test('Cálculo Semanal: verificación de fórmula, crecimiento e integridad de serie', () {
      final weekly = CompoundInterestCalculator.calculate(
        baseAmount: 10000.0,
        monthlyRatePct: 25.0,
        grouping: CompoundInterestGrouping.weekly,
        accountCreationDate: startDate,
        years: 1,
      );

      expect(weekly.length, equals(48)); // 12 meses * 4 semanas

      // Semana 1: 10,000 * 6.25% (0.0625) = 625.0 -> Final 10,625.0
      expect(weekly[0].startBalance, equals(10000.0));
      expect(weekly[0].yieldAmount, equals(625.0));
      expect(weekly[0].endBalance, equals(10625.0));

      // Semana 2: Saldo Inicial 10,625.0, Rendimiento 10,625 * 6.25% = 664.06 -> Final 11,289.06
      expect(weekly[1].startBalance, equals(10625.0));
      expect(weekly[1].yieldAmount, equals(664.06));
      expect(weekly[1].endBalance, equals(11289.06));

      expect(weekly[1].yieldAmount > weekly[0].yieldAmount, isTrue);

      verifySeriesIntegrity(weekly);
    });

    test('Proyección Mensual y Anual con verificación exacta de valores e integridad', () {
      final monthly = CompoundInterestCalculator.calculate(
        baseAmount: 10000.0,
        monthlyRatePct: 25.0,
        grouping: CompoundInterestGrouping.monthly,
        accountCreationDate: startDate,
        years: 1,
      );

      expect(monthly.length, equals(12));

      // Mes 1 (Jun 26)
      expect(monthly[0].label, equals('Jun 26'));
      expect(monthly[0].startBalance, equals(10000.0));
      expect(monthly[0].yieldAmount, equals(2500.0));
      expect(monthly[0].endBalance, equals(12500.0));

      // Mes 2 (Jul 26)
      expect(monthly[1].label, equals('Jul 26'));
      expect(monthly[1].startBalance, equals(12500.0));
      expect(monthly[1].yieldAmount, equals(3125.0));
      expect(monthly[1].endBalance, equals(15625.0));

      // Mes 12 (May 27)
      expect(monthly[11].label, equals('May 27'));
      expect(monthly[11].startBalance, equals(116415.36));
      expect(monthly[11].endBalance, equals(145519.20));

      verifySeriesIntegrity(monthly);

      // Proyección Anual
      final yearly = CompoundInterestCalculator.calculate(
        baseAmount: 10000.0,
        monthlyRatePct: 25.0,
        grouping: CompoundInterestGrouping.yearly,
        accountCreationDate: startDate,
        years: 1,
      );

      expect(yearly.length, equals(1));
      expect(yearly[0].label, equals('2026'));
      expect(yearly[0].startBalance, equals(10000.0));
      expect(yearly[0].endBalance, equals(145519.20));
      expect(yearly[0].yieldAmount, equals(135519.20));

      verifySeriesIntegrity(yearly);
    });
  });
}
