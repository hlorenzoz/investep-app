import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/portfolio/presentation/portfolio_screen.dart';
import 'package:investep_app/features/setup/presentation/setup_deferred_provider.dart';
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

class _DeferredOn extends SetupDeferred {
  @override
  bool build() => true;
}

Widget _app() => const MaterialApp(
  locale: Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: PortfolioScreen(),
);

void main() {
  testWidgets('capital == null → empty-state con CTA', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [capitalControllerProvider.overrideWith(_EmptyCapital.new)],
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurá tu capital'), findsOneWidget);
    expect(find.text('Configurar mi capital'), findsOneWidget);
  });

  testWidgets(
    'deferred && capital == null → banner "Completá tu configuración"',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capitalControllerProvider.overrideWith(_EmptyCapital.new),
            setupDeferredProvider.overrideWith(_DeferredOn.new),
          ],
          child: _app(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Completá tu configuración'), findsOneWidget);
    },
  );

  testWidgets('con allocations → lista + FAB agregar broker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_PopulatedCapital.new),
        ],
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    // Muestra la allocation (broker slug) y el % del capital (1000/10000 = 10%).
    expect(find.textContaining('ibkr'), findsOneWidget);
    expect(find.textContaining('10'), findsWidgets);
    // FAB para agregar otra cuenta.
    expect(find.text('Agregar cuenta de broker'), findsOneWidget);
    expect(find.text('Configurá tu capital'), findsNothing);
  });
}
