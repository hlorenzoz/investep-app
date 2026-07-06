import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/operations/data/operations_repository.dart';
import 'package:investep_app/features/operations/domain/operation.dart';
import 'package:investep_app/features/operations/presentation/operations_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationsRepository extends Mock implements OperationsRepository {}

Operation _op() => Operation(
  id: 'op-1',
  allocationId: 'alloc-1',
  accountType: AccountType.equity,
  ticker: 'AAPL',
  openedAt: DateTime(2026, 7, 1),
  quantity: 10,
  buyPrice: 100,
  status: 'open',
  totalInvested: 1000,
);

void main() {
  late MockOperationsRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockOperationsRepository();
    when(
      () => repo.getOperations(
        allocationId: any(named: 'allocationId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => [_op()]);
    container = ProviderContainer(
      overrides: [operationsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  OperationsController notifier() =>
      container.read(operationsControllerProvider('alloc-1').notifier);

  test('registerSale envía soldAt como YYYY-MM-DD + sellPrice', () async {
    await container.read(operationsControllerProvider('alloc-1').future);
    when(
      () => repo.patchOperation(any(), any()),
    ).thenAnswer((_) async => _op());

    await notifier().registerSale(
      'op-1',
      soldAt: DateTime(2026, 7, 10),
      sellPrice: 120,
    );

    final captured =
        verify(() => repo.patchOperation('op-1', captureAny())).captured.single
            as Map<String, dynamic>;

    expect(captured['soldAt'], '2026-07-10'); // fecha sola, sin 'T'
    expect(captured['sellPrice'], 120);
  });

  test(
    'reopenOperation deshace la venta con soldAt y sellPrice en null',
    () async {
      await container.read(operationsControllerProvider('alloc-1').future);
      when(
        () => repo.patchOperation(any(), any()),
      ).thenAnswer((_) async => _op());

      await notifier().reopenOperation('op-1');

      final captured =
          verify(
                () => repo.patchOperation('op-1', captureAny()),
              ).captured.single
              as Map<String, dynamic>;

      expect(captured.containsKey('soldAt'), isTrue);
      expect(captured['soldAt'], isNull);
      expect(captured['sellPrice'], isNull);
    },
  );
}
