import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/account/presentation/account_detail_screen.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:investep_app/features/operations/data/operations_repository.dart';
import 'package:investep_app/features/operations/domain/operation.dart';
import 'package:investep_app/features/plans/data/projection_repository.dart';
import 'package:investep_app/features/plans/domain/compound_interest_calculator.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationsRepository extends Mock implements OperationsRepository {}

class MockProjectionRepository extends Mock implements ProjectionRepository {}

class _PopulatedCapital extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: Capital(totalCapital: 10000, currency: 'USD'),
    allocations: [
      Allocation(
        id: 'a1',
        brokerId: 7,
        brokerSlug: 'ibkr',
        accountType: AccountType.equity,
        investmentPlanId: 3,
        targetMonthlyPct: 2.5,
        initialDeposit: 1000,
        currency: 'USD',
      ),
    ],
    totalAllocated: 1000,
    available: 9000,
  );
}

Widget _app(String id) {
  final router = GoRouter(
    initialLocation: '/account/$id',
    routes: [
      GoRoute(
        path: '/account/:id',
        builder: (c, s) =>
            AccountDetailScreen(allocationId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: '/account/:id/edit',
        builder: (c, s) =>
            Scaffold(body: Text('EDIT_ROUTE:${s.pathParameters['id']}')),
      ),
    ],
  );
  return MaterialApp.router(
    locale: const Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  );
}

void main() {
  late MockOperationsRepository mockOpsRepo;
  late MockProjectionRepository mockProjRepo;

  setUpAll(() {
    registerFallbackValue(CompoundInterestGrouping.monthly);
  });

  setUp(() {
    mockOpsRepo = MockOperationsRepository();
    mockProjRepo = MockProjectionRepository();

    when(
      () => mockOpsRepo.getOperations(
        allocationId: any(named: 'allocationId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => <Operation>[]);

    when(
      () => mockProjRepo.getProjection(
        planId: any(named: 'planId'),
        baseAmount: any(named: 'baseAmount'),
        startDate: any(named: 'startDate'),
        grouping: any(named: 'grouping'),
      ),
    ).thenAnswer(
      (_) async => <CompoundInterestPeriodResult>[
        CompoundInterestPeriodResult(
          periodIndex: 1,
          label: 'Jul 26',
          date: DateTime(2026, 7, 1),
          startBalance: 1000,
          yieldAmount: 25,
          endBalance: 1025,
        ),
      ],
    );
  });

  testWidgets('id válido → muestra broker vivo + botón abre la edición', (
    tester,
  ) async {
    // Configura un tamaño de pantalla adecuado para evitar RenderFlex overflows por la altura del PlanChart
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_PopulatedCapital.new),
          operationsRepositoryProvider.overrideWithValue(mockOpsRepo),
          projectionRepositoryProvider.overrideWithValue(mockProjRepo),
        ],
        child: _app('a1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('ibkr'), findsOneWidget); // título del AppBar (vivo)

    // Por defecto se abre la pestaña "Plan". Hacemos tap en "Registros" para ver el listado
    await tester.tap(find.text('Registros'));
    await tester.pumpAndSettle();
    expect(find.text('Registro de Trades'), findsOneWidget);

    await tester.tap(find.byTooltip('Editar cuenta'));
    await tester.pumpAndSettle();

    expect(find.text('EDIT_ROUTE:a1'), findsOneWidget);
  });

  testWidgets('id inexistente → sin botón de configuración', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_PopulatedCapital.new),
          operationsRepositoryProvider.overrideWithValue(mockOpsRepo),
          projectionRepositoryProvider.overrideWithValue(mockProjRepo),
        ],
        child: _app('nope'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('Editar cuenta'), findsNothing);
  });
}
