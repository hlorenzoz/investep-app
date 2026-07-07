import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/features/capital/domain/account_type.dart';
import 'package:investep_app/features/capital/domain/allocation.dart';
import 'package:investep_app/features/capital/domain/capital.dart';
import 'package:investep_app/features/capital/domain/capital_overview.dart';
import 'package:investep_app/features/capital/presentation/capital_controller.dart';
import 'package:investep_app/features/dashboard/presentation/dashboard_screen.dart';
import 'package:investep_app/features/dashboard/presentation/dashboard_providers.dart';
import 'package:investep_app/core/auth/auth_gate.dart';
import 'package:investep_app/features/auth/domain/auth_user.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:investep_app/shared/format/money.dart';

class FakeAuthGate extends AuthGate {
  final AuthGateState initialState;
  FakeAuthGate(this.initialState);

  @override
  AuthGateState build() => initialState;
}

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
            initialDeposit: 4000,
            currency: 'USD',
          ),
          Allocation(
            id: 'a2',
            brokerId: 8,
            brokerSlug: 'tastytrade',
            accountType: AccountType.options,
            investmentPlanId: 4,
            targetMonthlyPct: 3.0,
            initialDeposit: 6000,
            currency: 'USD',
          ),
        ],
        totalAllocated: 10000,
        available: 0,
      );
}

Widget _app() => const MaterialApp(
      locale: Locale('es'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: DashboardScreen(),
    );

void main() {
  testWidgets('DashboardScreen renders empty state when capital is null', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_EmptyCapital.new),
          authGateProvider.overrideWith(
            () => FakeAuthGate(
              GateAuthenticated(
                AuthUser(
                  id: 'u1',
                  email: 'test@example.com',
                  role: 'user',
                  mustResetPassword: false,
                  planSlug: 'gold',
                ),
              ),
            ),
          ),
        ],
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configurá tu capital'), findsOneWidget);
    expect(find.text('Configurar mi capital'), findsOneWidget);
  });

  testWidgets('DashboardScreen renders metrics, charts and active count when populated', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          capitalControllerProvider.overrideWith(_PopulatedCapital.new),
          authGateProvider.overrideWith(
            () => FakeAuthGate(
              GateAuthenticated(
                AuthUser(
                  id: 'u1',
                  email: 'test@example.com',
                  role: 'user',
                  mustResetPassword: false,
                  planSlug: 'gold',
                ),
              ),
            ),
          ),
          dashboardAssetsCountProvider.overrideWith((ref) => Future.value(45)),
        ],
        child: _app(),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Validar visualización de saldo total estimado con factor de crecimiento (10000 * 1.06 = 10600)
    expect(find.textContaining(formatMoney(10600, 'USD')), findsOneWidget);

    // 2. Validar visualización de plan y activos accesibles
    expect(find.text('GOLD'), findsOneWidget);
    expect(find.text('45 activos habilitados en tu plan'), findsOneWidget);

    // Hacer scroll hacia abajo para revelar el detalle por broker
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    // 3. Validar gráficos y desglose por broker
    expect(find.text('Distribución por Bróker'), findsOneWidget);
    expect(find.text('IBKR'), findsOneWidget);
    expect(find.text('TASTYTRADE'), findsOneWidget);
    expect(find.text('Tipo de Cuenta (Consolidado)'), findsOneWidget);
  });
}
