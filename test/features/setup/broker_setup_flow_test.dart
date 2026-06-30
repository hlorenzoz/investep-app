import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/brokers/domain/broker.dart';
import 'package:investep_app/features/brokers/presentation/brokers_provider.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/setup/presentation/broker_setup_flow.dart';
import 'package:investep_app/features/setup/presentation/setup_mode.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

class _FakeCapitalController extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: Capital(totalCapital: 10000, currency: 'USD'),
    allocations: [],
    totalAllocated: 0,
    available: 10000,
  );
}

Widget _appFor(SetupMode mode) => MaterialApp(
  locale: const Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BrokerSetupFlow(mode: mode),
);

void main() {
  testWidgets('initialSetup arranca en el slide de broker', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_FakeCapitalController.new),
          brokersProvider.overrideWith(
            (ref) async => const [
              Broker(id: 7, slug: 'ibkr', name: 'Interactive Brokers'),
            ],
          ),
        ],
        child: _appFor(SetupMode.initialSetup),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elegí tu broker'), findsOneWidget);
    expect(find.text('Tu capital inicial'), findsNothing);
    expect(find.text('Configurar más tarde'), findsOneWidget);
  });

  testWidgets('addBroker omite capital y arranca en el slide de broker', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_FakeCapitalController.new),
          brokersProvider.overrideWith(
            (ref) async => const [
              Broker(id: 7, slug: 'ibkr', name: 'Interactive Brokers'),
            ],
          ),
        ],
        child: _appFor(SetupMode.addBroker),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Elegí tu broker'), findsOneWidget);
    expect(find.text('Tu capital inicial'), findsNothing);
    expect(find.text('Interactive Brokers'), findsOneWidget);
    expect(find.text('Configurar más tarde'), findsOneWidget);
  });

  testWidgets(
    'error de /brokers → estado bloqueante con reintento (sin hardcode)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capitalControllerProvider.overrideWith(_FakeCapitalController.new),
            brokersProvider.overrideWith(
              (ref) async =>
                  throw const ApiException(404, 'NOT_FOUND', 'no existe'),
            ),
          ],
          child: _appFor(SetupMode.addBroker),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No pudimos cargar los brokers'), findsOneWidget);
      expect(find.text('Reintentar'), findsOneWidget);
      expect(find.text('Interactive Brokers'), findsNothing);
    },
  );
}
