import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/setup/presentation/wizard_data.dart';

void main() {
  group('DepositInput.resolved', () {
    test('modo monto → devuelve el monto tal cual', () {
      const d = DepositInput(mode: DepositMode.amount, amount: 1500);
      expect(d.resolved(10000), 1500);
    });

    test('modo % → totalCapital * pct / 100', () {
      const d = DepositInput(mode: DepositMode.percentOfCapital, pct: 25);
      expect(d.resolved(8000), 2000);
    });

    test('valores nulos → 0', () {
      const d = DepositInput(mode: DepositMode.amount);
      expect(d.resolved(8000), 0);
      const p = DepositInput(mode: DepositMode.percentOfCapital);
      expect(p.resolved(8000), 0);
    });
  });

  group('WizardData', () {
    test('resolvedDeposit usa el totalCapital propio', () {
      const data = WizardData(
        totalCapital: 4000,
        deposit: DepositInput(mode: DepositMode.percentOfCapital, pct: 10),
      );
      expect(data.resolvedDeposit, 400);
    });

    test('depositIsValid: > 0 sin restricción de disponible', () {
      const data = WizardData(
        totalCapital: 10000,
        deposit: DepositInput(mode: DepositMode.amount, amount: 3000),
      );
      expect(data.depositIsValid(4000), isTrue);
      expect(data.depositIsValid(3000), isTrue);
      expect(data.depositIsValid(2999), isTrue);
    });

    test('depositIsValid: 0 o negativo es inválido', () {
      const zero = WizardData(
        deposit: DepositInput(mode: DepositMode.amount, amount: 0),
      );
      expect(zero.depositIsValid(5000), isFalse);
    });

    test('copyWith(clearPlan) limpia el plan; copyWith normal lo conserva', () {
      const data = WizardData(
        accountType: AccountType.equity,
        investmentPlanId: 3,
      );
      expect(data.copyWith(brokerId: 9).investmentPlanId, 3);
      expect(data.copyWith(clearPlan: true).investmentPlanId, isNull);
    });
  });
}
