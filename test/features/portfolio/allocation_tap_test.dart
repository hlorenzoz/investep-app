import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/portfolio/presentation/portfolio_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

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

Widget _app() {
  final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (c, s) => const PortfolioScreen()),
      GoRoute(
        path: '/account/:id',
        builder: (c, s) =>
            Scaffold(body: Text('ACCOUNT_ROUTE:${s.pathParameters['id']}')),
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
  testWidgets('tap en una tarjeta navega a /account', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_PopulatedCapital.new),
        ],
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('ACCOUNT_ROUTE'), findsNothing);

    await tester.tap(find.text('ibkr'));
    await tester.pumpAndSettle();

    // Navega a /account/:id con el id de la allocation.
    expect(find.text('ACCOUNT_ROUTE:a1'), findsOneWidget);
  });
}
