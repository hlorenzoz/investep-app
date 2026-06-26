import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/account/presentation/edit_allocation_screen.dart';
import 'package:investep_app/features/capital/data/capital_repository.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/plans/domain/investment_plan.dart';
import 'package:investep_app/features/plans/presentation/plans_provider.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockCapitalRepository extends Mock implements CapitalRepository {}

const _alloc = Allocation(
  id: 'a1',
  brokerId: 7,
  brokerSlug: 'ibkr',
  accountType: AccountType.equity,
  investmentPlanId: 3,
  targetMonthlyPct: 2.5,
  initialDeposit: 1000,
  currency: 'USD',
);

class _PopulatedCapital extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: Capital(totalCapital: 10000, currency: 'USD'),
    allocations: [_alloc],
    totalAllocated: 1000,
    available: 9000,
  );
}

final _plans = [
  const InvestmentPlan(
    id: 3,
    accountType: AccountType.equity,
    targetMonthlyPct: 2.5,
    label: 'Plan Conservador',
  ),
  const InvestmentPlan(
    id: 5,
    accountType: AccountType.equity,
    targetMonthlyPct: 5,
    label: 'Plan Agresivo',
  ),
];

Widget _app(MockCapitalRepository repo) => ProviderScope(
  overrides: [
    capitalRepositoryProvider.overrideWithValue(repo),
    capitalControllerProvider.overrideWith(_PopulatedCapital.new),
    plansProvider(AccountType.equity).overrideWith((ref) async => _plans),
  ],
  child: const MaterialApp(
    locale: Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: EditAllocationScreen(allocationId: 'a1'),
  ),
);

void main() {
  late MockCapitalRepository repo;

  setUp(() => repo = MockCapitalRepository());

  testWidgets('precarga el depósito actual y el broker', (tester) async {
    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    expect(find.text('ibkr'), findsOneWidget);
    // Depósito precargado (monto) = 1000.
    expect(find.widgetWithText(TextField, '1000'), findsOneWidget);
    expect(find.text('Plan Conservador'), findsOneWidget);
  });

  testWidgets('Guardar invoca patchAllocation con plan + depósito', (
    tester,
  ) async {
    // Ventana alta para que el botón "Guardar" entre en el viewport.
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Falla a propósito (no navega) → verifica wiring y muestra el error.
    when(
      () => repo.patchAllocation(
        any(),
        investmentPlanId: any(named: 'investmentPlanId'),
        initialDeposit: any(named: 'initialDeposit'),
        currency: any(named: 'currency'),
      ),
    ).thenAnswer(
      (_) async => throw const ApiException(409, 'CONFLICT', 'Supera capital'),
    );

    await tester.pumpWidget(_app(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    verify(
      () => repo.patchAllocation(
        'a1',
        investmentPlanId: 3,
        initialDeposit: 1000,
        currency: any(named: 'currency'),
      ),
    ).called(1);
    expect(find.text('Supera capital'), findsOneWidget);
  });
}
