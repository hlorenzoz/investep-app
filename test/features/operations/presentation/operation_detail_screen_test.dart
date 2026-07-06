import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/operations/data/operations_repository.dart';
import 'package:investep_app/features/operations/domain/operation.dart';
import 'package:investep_app/features/operations/presentation/operation_detail_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockOperationsRepository extends Mock implements OperationsRepository {}

class _PopulatedCapital extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: Capital(totalCapital: 10000, currency: 'USD'),
    allocations: [
      Allocation(
        id: 'a1',
        brokerId: 7,
        brokerSlug: 'tastytrade',
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

Operation _closedTrade() => Operation(
  id: 'op1',
  allocationId: 'a1',
  accountType: AccountType.equity,
  ticker: 'GOOG',
  openedAt: DateTime(2026, 7, 1),
  quantity: 1,
  buyPrice: 1234,
  soldAt: DateTime(2026, 7, 4),
  sellPrice: 1345,
  status: 'closed',
  totalInvested: 1234,
  totalSale: 1345,
  gainAmount: 111,
  gainPct: 9,
);

Widget _app(GlobalKey<NavigatorState> navKey) {
  final router = GoRouter(
    navigatorKey: navKey,
    initialLocation: '/account/a1/operations/op1',
    routes: [
      GoRoute(
        path: '/account/:id/operations/:operationId',
        builder: (c, s) => OperationDetailScreen(
          allocationId: s.pathParameters['id']!,
          operationId: s.pathParameters['operationId']!,
        ),
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

  setUp(() {
    mockOpsRepo = MockOperationsRepository();
    when(
      () => mockOpsRepo.getOperations(
        allocationId: any(named: 'allocationId'),
        status: any(named: 'status'),
      ),
    ).thenAnswer((_) async => <Operation>[_closedTrade()]);
  });

  testWidgets('trade cerrado → muestra estadísticas de venta y ganancia', (
    tester,
  ) async {
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
        ],
        child: _app(GlobalKey<NavigatorState>()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('GOOG'), findsOneWidget);
    expect(find.text('Cerrada'), findsOneWidget);
    // Sección de venta
    expect(find.text('Venta'), findsOneWidget);
    expect(find.text('Precio de venta'), findsOneWidget);
    expect(find.text('2026-07-04'), findsOneWidget); // fecha de venta
    // Ganancia con signo y porcentaje
    expect(find.textContaining('+9.00%'), findsOneWidget);
    expect(find.text('Ganancia'), findsOneWidget);
  });
}
