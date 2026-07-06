import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/operations/data/operations_repository.dart';
import 'package:investep_app/features/operations/domain/operation.dart';
import 'package:investep_app/features/operations/presentation/operation_form_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationsRepository extends Mock implements OperationsRepository {}

Allocation equityAllocationFixture() => const Allocation(
  id: 'alloc-equity',
  brokerId: 1,
  brokerSlug: 'eTrade',
  accountType: AccountType.equity,
  investmentPlanId: 2,
  targetMonthlyPct: 2.0,
  initialDeposit: 5000,
  currency: 'USD',
);

Allocation optionsAllocationFixture() => const Allocation(
  id: 'alloc-options',
  brokerId: 2,
  brokerSlug: 'tastytrade',
  accountType: AccountType.options,
  investmentPlanId: 3,
  targetMonthlyPct: 4.0,
  initialDeposit: 10000,
  currency: 'USD',
);

CapitalOverview capitalOverviewFixture() => CapitalOverview(
  capital: const Capital(totalCapital: 15000, currency: 'USD'),
  allocations: [equityAllocationFixture(), optionsAllocationFixture()],
  totalAllocated: 15000,
  available: 0,
);

class FakeCapitalController extends CapitalController {
  @override
  Future<CapitalOverview> build() async => capitalOverviewFixture();

  @override
  Future<void> refresh() async {
    state = AsyncData(capitalOverviewFixture());
  }
}

Operation mockOperationFixture() => Operation(
  id: 'op-123',
  allocationId: 'alloc-options',
  accountType: AccountType.options,
  ticker: 'AAPL',
  openedAt: DateTime(2026, 7, 1, 10),
  quantity: 5.0,
  buyPrice: 3.5,
  limitPrice: 6.0,
  soldAt: null,
  sellPrice: null,
  strategy: 'Wheel',
  notes: 'Pre-loaded option',
  url: 'https://finance.yahoo.com/quote/AAPL/options',
  status: 'open',
  totalInvested: 1750.0,
  strike: 150.0,
  expirationDate: '2026-07-17',
  contractType: 'call',
);

void main() {
  late MockOperationsRepository repo;
  late ProviderContainer container;

  setUp(() async {
    repo = MockOperationsRepository();
    container = ProviderContainer(
      overrides: [
        operationsRepositoryProvider.overrideWithValue(repo),
        capitalControllerProvider.overrideWith(FakeCapitalController.new),
      ],
    );
    addTearDown(container.dispose);
    await container.read(capitalControllerProvider.future);
  });

  OperationFormController notifier(OperationFormParam param) =>
      container.read(operationFormControllerProvider(param).notifier);

  OperationFormState state(OperationFormParam param) =>
      container.read(operationFormControllerProvider(param));

  group('build', () {
    test('sin operationId → inicializa vacío', () {
      const param = OperationFormParam(allocationId: 'alloc-equity');
      final s = state(param);

      expect(s.ticker, '');
      expect(s.quantity, '');
      expect(s.buyPrice, '');
      expect(s.isLoading, isFalse);
    });

    test('con operationId → carga la operación asíncronamente', () async {
      final op = mockOperationFixture();
      when(
        () => repo.getOperationDetails('op-123'),
      ).thenAnswer((_) async => op);

      const param = OperationFormParam(
        allocationId: 'alloc-options',
        operationId: 'op-123',
      );

      // Mantenemos una suscripción activa para evitar auto-dispose inmediato durante la carga asíncrona
      final sub = container.listen(
        operationFormControllerProvider(param),
        (prev, next) {},
      );

      var s = state(param);
      expect(s.isLoading, isTrue);

      // Esperamos el microtask
      await Future<void>.delayed(Duration.zero);

      s = state(param);
      expect(s.isLoading, isFalse);
      expect(s.ticker, 'AAPL');
      expect(s.quantity, '5.0');
      expect(s.buyPrice, '3.5');
      expect(s.strike, '150.0');
      expect(s.expirationDate, '2026-07-17');
      expect(s.contractType, 'call');

      sub.close();
    });
  });

  group('payload (contrato de la API)', () {
    test(
      'equity → openedAt como YYYY-MM-DD, sin accountType ni campos de opciones',
      () async {
        const param = OperationFormParam(allocationId: 'alloc-equity');
        final n = notifier(param);

        n.setTicker('aapl');
        n.setOpenedAt(DateTime(2026, 7, 4));
        n.setQuantity('10.5');
        n.setBuyPrice('150.0');

        when(
          () => repo.createOperation(any()),
        ).thenAnswer((_) async => mockOperationFixture());

        await n.submit();

        final payload =
            verify(() => repo.createOperation(captureAny())).captured.single
                as Map<String, dynamic>;

        expect(payload['openedAt'], '2026-07-04'); // fecha sola, sin 'T'
        expect(payload['ticker'], 'AAPL'); // normalizado a mayúsculas
        expect(payload['quantity'], 10.5); // decimal permitido en equity
        expect(payload.containsKey('accountType'), isFalse);
        expect(payload.containsKey('strike'), isFalse);
        expect(payload.containsKey('expirationDate'), isFalse);
        expect(payload.containsKey('contractType'), isFalse);
      },
    );

    test(
      'options → incluye strike/expiration/contractType y quantity entera',
      () async {
        const param = OperationFormParam(allocationId: 'alloc-options');
        final n = notifier(param);

        n.setTicker('AAPL');
        n.setOpenedAt(DateTime(2026, 7, 4));
        n.setQuantity('12');
        n.setBuyPrice('3.5');
        n.setStrike('150');
        n.setExpirationDate('2026-08-15');
        n.setContractType('call');

        when(
          () => repo.createOperation(any()),
        ).thenAnswer((_) async => mockOperationFixture());

        await n.submit();

        final payload =
            verify(() => repo.createOperation(captureAny())).captured.single
                as Map<String, dynamic>;

        expect(payload['openedAt'], '2026-07-04');
        expect(payload['quantity'], 12); // entera (int) en options
        expect(payload['quantity'], isA<int>());
        expect(payload['strike'], 150.0);
        expect(payload['expirationDate'], '2026-08-15');
        expect(payload['contractType'], 'call');
        expect(payload.containsKey('accountType'), isFalse);
      },
    );
  });

  group('validations', () {
    test(
      'cuenta de activos (equity) → cantidad decimal permitida y omite campos de opciones',
      () async {
        const param = OperationFormParam(allocationId: 'alloc-equity');
        final n = notifier(param);

        n.setTicker('AAPL');
        n.setQuantity('10.5'); // fraccional
        n.setBuyPrice('150.0');

        when(
          () => repo.createOperation(any()),
        ).thenAnswer((_) async => mockOperationFixture());

        await n.submit();

        final s = state(param);
        expect(s.errorMessage, isNull);
        expect(s.tickerError, isNull);
        expect(s.quantityError, isNull);
        expect(s.buyPriceError, isNull);
        expect(s.isSuccess, isTrue);
      },
    );

    test(
      'cuenta de opciones (options) → cantidad decimal arroja error y requiere strike/expiracion/tipo',
      () async {
        const param = OperationFormParam(allocationId: 'alloc-options');
        final n = notifier(param);

        n.setTicker('AAPL');
        n.setQuantity('10.5'); // fraccional en opciones → inválido
        n.setBuyPrice('3.5');
        n.setStrike('0'); // strike 0 → inválido
        n.setExpirationDate(''); // vacío → inválido

        await n.submit();

        final s = state(param);
        expect(s.isSuccess, isFalse);
        expect(s.quantityError, 'La cantidad en opciones debe ser entera');
        expect(s.strikeError, 'El strike es obligatorio y mayor a 0');
        expect(s.expirationDateError, 'Fecha de expiración es obligatoria');
      },
    );
  });
}
