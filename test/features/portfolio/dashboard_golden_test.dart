import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/portfolio/presentation/portfolio_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

class _EmptyCapital extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: null,
    allocations: [],
    totalAllocated: 0,
    available: 0,
  );
}

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

Widget _scope(CapitalController Function() controller) => ProviderScope(
  overrides: [capitalControllerProvider.overrideWith(controller)],
  child: const MaterialApp(
    locale: Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: PortfolioScreen(),
  ),
);

void main() {
  goldenTest(
    'Dashboard',
    fileName: 'dashboard',
    builder: () => GoldenTestGroup(
      columns: 2,
      children: [
        GoldenTestScenario(
          name: 'empty',
          constraints: const BoxConstraints.tightFor(width: 380, height: 720),
          child: _scope(_EmptyCapital.new),
        ),
        GoldenTestScenario(
          name: 'populated',
          constraints: const BoxConstraints.tightFor(width: 380, height: 720),
          child: _scope(_PopulatedCapital.new),
        ),
      ],
    ),
  );
}
