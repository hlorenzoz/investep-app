import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/capital/data/capital_repository.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/setup/presentation/setup_mode.dart';
import 'package:investep_app/features/setup/presentation/wizard_controller.dart';
import 'package:investep_app/features/setup/presentation/wizard_data.dart';
import 'package:mocktail/mocktail.dart';

class MockCapitalRepository extends Mock implements CapitalRepository {}

CapitalOverview overviewFixture() => const CapitalOverview(
  capital: Capital(totalCapital: 10000, currency: 'USD'),
  allocations: [],
  totalAllocated: 6000,
  available: 4000,
);

/// Fake del capitalController: ya cargado, cuenta refreshes.
class FakeCapitalController extends CapitalController {
  int refreshCalls = 0;

  @override
  Future<CapitalOverview> build() async => overviewFixture();

  @override
  Future<void> refresh() async {
    refreshCalls++;
    state = AsyncData(overviewFixture());
  }
}

Allocation allocationFixture() => const Allocation(
  id: 'alloc-1',
  brokerId: 7,
  brokerSlug: 'ibkr',
  accountType: AccountType.equity,
  investmentPlanId: 3,
  targetMonthlyPct: 2.5,
  initialDeposit: 1000,
  currency: 'USD',
);

void main() {
  late MockCapitalRepository capitalRepo;
  late ProviderContainer container;

  setUp(() async {
    capitalRepo = MockCapitalRepository();
    container = ProviderContainer(
      overrides: [
        capitalRepositoryProvider.overrideWithValue(capitalRepo),
        capitalControllerProvider.overrideWith(FakeCapitalController.new),
      ],
    );
    addTearDown(container.dispose);
    // Aseguramos el capital cargado (para el seed de addBroker).
    await container.read(capitalControllerProvider.future);
  });

  WizardController notifier(SetupMode mode) =>
      container.read(wizardControllerProvider(mode).notifier);
  WizardState state(SetupMode mode) =>
      container.read(wizardControllerProvider(mode));
  FakeCapitalController fakeCapital() =>
      container.read(capitalControllerProvider.notifier)
          as FakeCapitalController;

  group('navegación inicial', () {
    test('initialSetup arranca en el slide 1 (broker)', () {
      expect(state(SetupMode.initialSetup).slideIndex, 1);
    });

    test('addBroker arranca en el slide 1 (broker) y omite capital', () {
      expect(state(SetupMode.addBroker).slideIndex, 1);
    });

    test('addBroker siembra totalCapital y currency del capital existente', () {
      final data = state(SetupMode.addBroker).data;
      expect(data.totalCapital, 10000);
      expect(data.currency, 'USD');
    });

    test('back en addBroker no baja del slide 1', () {
      notifier(SetupMode.addBroker).back();
      expect(state(SetupMode.addBroker).slideIndex, 1);
    });
  });

  group('setters', () {
    test('setAccountType limpia el plan elegido', () {
      final n = notifier(SetupMode.initialSetup)
        ..setPlan(3)
        ..setAccountType(AccountType.options);
      expect(state(SetupMode.initialSetup).data.investmentPlanId, isNull);
      expect(
        state(SetupMode.initialSetup).data.accountType,
        AccountType.options,
      );
      expect(n, isNotNull);
    });

    test(
      'setBroker limpia el tipo de cuenta y el plan (combo depende del broker)',
      () {
        notifier(SetupMode.addBroker)
          ..setBroker(7)
          ..setAccountType(AccountType.equity)
          ..setPlan(3)
          // El usuario vuelve y cambia de broker:
          ..setBroker(9);

        final data = state(SetupMode.addBroker).data;
        expect(data.brokerId, 9);
        expect(data.accountType, isNull);
        expect(data.investmentPlanId, isNull);
      },
    );
  });

  group('submitAllocation', () {
    void stubCreateOk() {
      when(
        () => capitalRepo.createAllocation(
          brokerId: any(named: 'brokerId'),
          investmentPlanId: any(named: 'investmentPlanId'),
          initialDeposit: any(named: 'initialDeposit'),
          currency: any(named: 'currency'),
        ),
      ).thenAnswer((_) async => allocationFixture());
    }

    test(
      '200 → crea allocation con el depósito resuelto, refresca y completa',
      () async {
        stubCreateOk();

        final n = notifier(SetupMode.addBroker)
          ..setBroker(7)
          ..setAccountType(AccountType.equity)
          ..setPlan(3)
          ..setDeposit(
            const DepositInput(mode: DepositMode.percentOfCapital, pct: 10),
          );
        await n.submitAllocation();

        // 10% de 10000 = 1000.
        final captured = verify(
          () => capitalRepo.createAllocation(
            brokerId: 7,
            investmentPlanId: 3,
            initialDeposit: captureAny(named: 'initialDeposit'),
            currency: 'USD',
          ),
        ).captured.single;
        expect(captured, 1000);

        expect(fakeCapital().refreshCalls, greaterThanOrEqualTo(1));
        // Éxito → WizardCompleted (la vista cierra y vuelve al dashboard).
        expect(state(SetupMode.addBroker), isA<WizardCompleted>());
      },
    );

    test('409 → WizardStepError(allocation)', () async {
      when(
        () => capitalRepo.createAllocation(
          brokerId: any(named: 'brokerId'),
          investmentPlanId: any(named: 'investmentPlanId'),
          initialDeposit: any(named: 'initialDeposit'),
          currency: any(named: 'currency'),
        ),
      ).thenAnswer(
        (_) async => throw const ApiException(409, 'CONFLICT', 'Duplicado'),
      );

      final n = notifier(SetupMode.addBroker)
        ..setBroker(7)
        ..setAccountType(AccountType.equity)
        ..setPlan(3)
        ..setDeposit(const DepositInput(mode: DepositMode.amount, amount: 500));
      await n.submitAllocation();

      final s = state(SetupMode.addBroker);
      expect(s, isA<WizardStepError>());
      expect((s as WizardStepError).step, WizardStep.allocation);
    });

    test(
      'guard de reentrada: un segundo submit tras completar NO repite el POST',
      () async {
        stubCreateOk();

        final n = notifier(SetupMode.addBroker)
          ..setBroker(7)
          ..setAccountType(AccountType.equity)
          ..setPlan(3)
          ..setDeposit(
            const DepositInput(mode: DepositMode.amount, amount: 500),
          );
        await n.submitAllocation();
        expect(state(SetupMode.addBroker), isA<WizardCompleted>());

        // Doble-tap / swipe en el resumen antes de que navegue al dashboard.
        await n.submitAllocation();

        verify(
          () => capitalRepo.createAllocation(
            brokerId: any(named: 'brokerId'),
            investmentPlanId: any(named: 'investmentPlanId'),
            initialDeposit: any(named: 'initialDeposit'),
            currency: any(named: 'currency'),
          ),
        ).called(1);
      },
    );
  });

  group('navegación de edición (desde el resumen)', () {
    test('goTo salta a un slide específico (clamp al rango del modo)', () {
      final n = notifier(SetupMode.addBroker);
      n.goTo(WizardSlide.plan);
      expect(state(SetupMode.addBroker).slideIndex, WizardSlide.plan);
      // addBroker no baja del slide de broker.
      n.goTo(WizardSlide.capital);
      expect(state(SetupMode.addBroker).slideIndex, WizardSlide.broker);
    });
  });
}
