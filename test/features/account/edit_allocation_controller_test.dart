import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/account/presentation/edit_allocation_controller.dart';
import 'package:investep_app/features/capital/data/capital_repository.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/setup/presentation/wizard_data.dart';
import 'package:mocktail/mocktail.dart';

class MockCapitalRepository extends Mock implements CapitalRepository {}

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

CapitalOverview overviewFixture() => CapitalOverview(
  capital: const Capital(totalCapital: 10000, currency: 'USD'),
  allocations: [allocationFixture()],
  totalAllocated: 1000,
  available: 9000,
);

/// Fake del capitalController: ya cargado con una allocation, cuenta refreshes.
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

void main() {
  late MockCapitalRepository repo;
  late ProviderContainer container;

  setUp(() async {
    repo = MockCapitalRepository();
    container = ProviderContainer(
      overrides: [
        capitalRepositoryProvider.overrideWithValue(repo),
        capitalControllerProvider.overrideWith(FakeCapitalController.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(capitalControllerProvider.future);
  });

  final alloc = allocationFixture();

  EditAllocationController notifier(String id) =>
      container.read(editAllocationControllerProvider(id).notifier);
  EditState state(String id) =>
      container.read(editAllocationControllerProvider(id));
  FakeCapitalController fakeCapital() =>
      container.read(capitalControllerProvider.notifier)
          as FakeCapitalController;

  void stubPatchOk() {
    when(
      () => repo.patchAllocation(
        any(),
        investmentPlanId: any(named: 'investmentPlanId'),
        initialDeposit: any(named: 'initialDeposit'),
        currency: any(named: 'currency'),
      ),
    ).thenAnswer((_) async => allocationFixture());
  }

  group('build (seed)', () {
    test('siembra el plan y el depósito (monto) de la allocation recibida', () {
      final s = state(alloc.id);
      expect(s, isA<EditIdle>());
      expect(s.investmentPlanId, 3);
      expect(s.deposit.mode, DepositMode.amount);
      expect(s.deposit.amount, 1000);
    });
  });

  group('setters', () {
    test('setPlan y setDeposit actualizan el estado', () {
      final n = notifier(alloc.id)
        ..setPlan(5)
        ..setDeposit(
          const DepositInput(mode: DepositMode.amount, amount: 2000),
        );
      final s = state(alloc.id);
      expect(s.investmentPlanId, 5);
      expect(s.deposit.amount, 2000);
      expect(n, isNotNull);
    });
  });

  group('submit', () {
    test(
      '200 → PATCH con plan + depósito resuelto, refresca y completa',
      () async {
        stubPatchOk();

        final n = notifier(alloc.id)
          ..setPlan(5)
          ..setDeposit(
            const DepositInput(mode: DepositMode.percentOfCapital, pct: 20),
          );
        await n.submit();

        // 20% de 10000 = 2000.
        final captured = verify(
          () => repo.patchAllocation(
            alloc.id,
            investmentPlanId: 5,
            initialDeposit: captureAny(named: 'initialDeposit'),
            currency: any(named: 'currency'),
          ),
        ).captured.single;
        expect(captured, 2000);

        expect(fakeCapital().refreshCalls, greaterThanOrEqualTo(1));
        expect(state(alloc.id), isA<EditCompleted>());
      },
    );

    test('409 → EditError con el message', () async {
      when(
        () => repo.patchAllocation(
          any(),
          investmentPlanId: any(named: 'investmentPlanId'),
          initialDeposit: any(named: 'initialDeposit'),
          currency: any(named: 'currency'),
        ),
      ).thenAnswer(
        (_) async =>
            throw const ApiException(409, 'CONFLICT', 'Supera capital'),
      );

      final n = notifier(alloc.id)
        ..setDeposit(
          const DepositInput(mode: DepositMode.amount, amount: 50000),
        );
      await n.submit();

      final s = state(alloc.id);
      expect(s, isA<EditError>());
      expect((s as EditError).message, 'Supera capital');
    });

    test(
      'error NO-ApiException → EditError (no queda en Submitting)',
      () async {
        // p. ej. un 200 con body inesperado que rompe el parseo.
        when(
          () => repo.patchAllocation(
            any(),
            investmentPlanId: any(named: 'investmentPlanId'),
            initialDeposit: any(named: 'initialDeposit'),
            currency: any(named: 'currency'),
          ),
        ).thenAnswer((_) async => throw StateError('boom'));

        final n = notifier(alloc.id)..setPlan(5);
        await n.submit();

        expect(state(alloc.id), isA<EditError>());
      },
    );

    test(
      'guard de reentrada: un segundo submit tras completar NO repite',
      () async {
        stubPatchOk();

        final n = notifier(alloc.id)..setPlan(5);
        await n.submit();
        expect(state(alloc.id), isA<EditCompleted>());

        await n.submit();

        verify(
          () => repo.patchAllocation(
            any(),
            investmentPlanId: any(named: 'investmentPlanId'),
            initialDeposit: any(named: 'initialDeposit'),
            currency: any(named: 'currency'),
          ),
        ).called(1);
      },
    );
  });
}
