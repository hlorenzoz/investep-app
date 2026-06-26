import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/brokers/domain/broker.dart';
import 'package:investep_app/features/brokers/presentation/brokers_provider.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/plans/domain/investment_plan.dart';
import 'package:investep_app/features/plans/presentation/plans_provider.dart';
import 'package:investep_app/features/setup/presentation/setup_mode.dart';
import 'package:investep_app/features/setup/presentation/slides/summary_slide.dart';
import 'package:investep_app/features/setup/presentation/wizard_controller.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

class _FakeCapital extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: Capital(totalCapital: 10000, currency: 'USD'),
    allocations: [],
    totalAllocated: 0,
    available: 10000,
  );
}

void main() {
  testWidgets('tocar la fila de Plan navega al slide de plan (edición)', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        capitalControllerProvider.overrideWith(_FakeCapital.new),
        brokersProvider.overrideWith(
          (ref) async => const [Broker(id: 7, slug: 'ibkr', name: 'IBKR')],
        ),
        plansProvider(AccountType.equity).overrideWith(
          (ref) async => const [
            InvestmentPlan(
              id: 3,
              accountType: AccountType.equity,
              targetMonthlyPct: 25,
              label: 'Activos 25%',
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(capitalControllerProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SummarySlide(mode: SetupMode.addBroker)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // addBroker arranca en el slide de broker.
    expect(
      container.read(wizardControllerProvider(SetupMode.addBroker)).slideIndex,
      WizardSlide.broker,
    );

    await tester.tap(find.widgetWithText(InkWell, 'Plan'));
    await tester.pump();

    expect(
      container.read(wizardControllerProvider(SetupMode.addBroker)).slideIndex,
      WizardSlide.plan,
    );
  });
}
