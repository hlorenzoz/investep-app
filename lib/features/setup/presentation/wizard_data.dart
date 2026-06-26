import '../../capital/domain/account_type.dart';

/// Cómo se expresa el depósito de una allocation en el wizard.
enum DepositMode { percentOfCapital, amount }

/// Entrada del depósito (slide 4). Siempre se envía un monto a la API
/// (`initialDeposit`); si el usuario eligió `%`, se calcula sobre el capital.
class DepositInput {
  final DepositMode mode;
  final num? pct;
  final num? amount;

  const DepositInput({this.mode = DepositMode.amount, this.pct, this.amount});

  /// Monto resuelto: en `%` es `totalCapital * pct / 100`; en monto, el monto.
  num resolved(num totalCapital) => switch (mode) {
    DepositMode.percentOfCapital => totalCapital * (pct ?? 0) / 100,
    DepositMode.amount => amount ?? 0,
  };

  DepositInput copyWith({DepositMode? mode, num? pct, num? amount}) =>
      DepositInput(
        mode: mode ?? this.mode,
        pct: pct ?? this.pct,
        amount: amount ?? this.amount,
      );
}

/// Datos acumulados a lo largo del wizard. Inmutable; cada slide produce una
/// copia vía [copyWith]. La moneda de la allocation = la del capital.
class WizardData {
  final num? totalCapital;
  final String currency;
  final int? brokerId;
  final AccountType? accountType;
  final int? investmentPlanId;
  final DepositInput deposit;

  const WizardData({
    this.totalCapital,
    this.currency = 'USD',
    this.brokerId,
    this.accountType,
    this.investmentPlanId,
    this.deposit = const DepositInput(),
  });

  /// Monto de depósito resuelto contra el capital actual.
  num get resolvedDeposit => deposit.resolved(totalCapital ?? 0);

  /// El depósito es válido si es > 0 y no supera el disponible.
  bool depositIsValid(num available) {
    final d = resolvedDeposit;
    return d > 0 && d <= available;
  }

  /// `clearAccountType`/`clearPlan` permiten limpiar esos campos (al cambiar de
  /// broker o de tipo de cuenta), algo que un `copyWith` con `??` no puede hacer.
  WizardData copyWith({
    num? totalCapital,
    String? currency,
    int? brokerId,
    AccountType? accountType,
    int? investmentPlanId,
    DepositInput? deposit,
    bool clearAccountType = false,
    bool clearPlan = false,
  }) {
    return WizardData(
      totalCapital: totalCapital ?? this.totalCapital,
      currency: currency ?? this.currency,
      brokerId: brokerId ?? this.brokerId,
      accountType: clearAccountType ? null : (accountType ?? this.accountType),
      investmentPlanId: clearPlan
          ? null
          : (investmentPlanId ?? this.investmentPlanId),
      deposit: deposit ?? this.deposit,
    );
  }
}
