import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/core/auth/auth_gate.dart';
import 'package:investep_app/features/auth/presentation/splash_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

/// Gate fake que devuelve un estado fijo (sin suscribirse a Supabase).
class _RetryGate extends AuthGate {
  @override
  AuthGateState build() => const GateRetrying503('El servidor no responde.');
}

Widget _scope({required AuthGate Function() gate}) => ProviderScope(
  overrides: [authGateProvider.overrideWith(gate)],
  child: const MaterialApp(
    locale: Locale('es'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: SplashScreen(),
  ),
);

void main() {
  goldenTest(
    'SplashScreen',
    fileName: 'splash_screen',
    builder: () => GoldenTestGroup(
      columns: 1,
      children: [
        GoldenTestScenario(
          name: 'retrying_503',
          constraints: const BoxConstraints.tightFor(width: 360, height: 640),
          child: _scope(gate: _RetryGate.new),
        ),
      ],
    ),
  );
}
