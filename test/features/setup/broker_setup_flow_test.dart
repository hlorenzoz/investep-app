import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/brokers/domain/broker.dart';
import 'package:investep_app/features/brokers/presentation/brokers_provider.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
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

  testWidgets(
    'muestra badges de cuentas configuradas por broker con sus respectivas cantidades',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capitalControllerProvider.overrideWith(
              _FakeCapitalControllerWithAllocations.new,
            ),
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

      expect(find.text('Acciones (2)'), findsOneWidget);
      expect(find.text('Opciones (1)'), findsOneWidget);
    },
  );

  testWidgets(
    'en el slide de tipo de cuenta, ambas opciones están habilitadas aunque ya estén configuradas',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            capitalControllerProvider.overrideWith(
              _FakeCapitalControllerWithAllocations.new,
            ),
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

      // Seleccionar broker y avanzar
      await tester.tap(find.text('Interactive Brokers'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();

      // Debería estar en el slide de tipo de cuenta
      expect(find.text('Tipo de cuenta'), findsOneWidget);

      // Ambos SegmentedButtons deben estar habilitados.
      // En Flutter, SegmentedButton contiene ButtonSegment widgets.
      // Podemos verificar que no estén inhabilitados encontrando el texto y validando interactividad
      expect(find.text('Acciones'), findsOneWidget);
      expect(find.text('Opciones'), findsOneWidget);

      // Verificamos que al seleccionarlos responda e interactúe
      await tester.tap(find.text('Acciones'));
      await tester.pumpAndSettle();

      // El botón de siguiente debe estar habilitado
      final nextButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Siguiente'),
      );
      expect(nextButton.onPressed, isNotNull);
    },
  );
}

class _FakeCapitalControllerWithAllocations extends CapitalController {
  @override
  Future<CapitalOverview> build() async => const CapitalOverview(
    capital: Capital(totalCapital: 10000, currency: 'USD'),
    allocations: [
      Allocation(
        id: '1',
        brokerId: 7,
        brokerSlug: 'ibkr',
        accountType: AccountType.equity,
        targetMonthlyPct: 2,
        initialDeposit: 2000,
        currency: 'USD',
      ),
      Allocation(
        id: '2',
        brokerId: 7,
        brokerSlug: 'ibkr',
        accountType: AccountType.equity,
        targetMonthlyPct: 2.5,
        initialDeposit: 3000,
        currency: 'USD',
      ),
      Allocation(
        id: '3',
        brokerId: 7,
        brokerSlug: 'ibkr',
        accountType: AccountType.options,
        targetMonthlyPct: 3,
        initialDeposit: 1500,
        currency: 'USD',
      ),
    ],
    totalAllocated: 6500,
    available: 3500,
  );
}
