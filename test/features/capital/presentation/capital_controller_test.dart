import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/capital/data/capital_repository.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockCapitalRepository extends Mock implements CapitalRepository {}

CapitalOverview overview({num available = 4000}) => CapitalOverview(
  capital: const Capital(totalCapital: 5000, currency: 'USD'),
  allocations: const [],
  totalAllocated: 1000,
  available: available,
);

void main() {
  late MockCapitalRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockCapitalRepository();
    container = ProviderContainer(
      overrides: [capitalRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  test('build → carga el overview desde el repo', () async {
    when(() => repo.getCapital()).thenAnswer((_) async => overview());

    final result = await container.read(capitalControllerProvider.future);

    expect(result.available, 4000);
    verify(() => repo.getCapital()).called(1);
  });

  test('refresh → vuelve a pedir el capital (recalcula available)', () async {
    var calls = 0;
    when(() => repo.getCapital()).thenAnswer((_) async {
      calls++;
      return overview(available: calls == 1 ? 4000 : 3000);
    });

    await container.read(capitalControllerProvider.future);
    await container.read(capitalControllerProvider.notifier).refresh();

    final state = container.read(capitalControllerProvider);
    expect(state.value!.available, 3000);
    expect(calls, 2);
  });
}
