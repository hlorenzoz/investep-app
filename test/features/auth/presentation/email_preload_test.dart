import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/auth/presentation/last_email_provider.dart';
import 'package:investep_app/features/auth/presentation/login_screen.dart';

import 'package:investep_app/l10n/gen/app_localizations.dart';

/// Notifier de prueba que arranca con un email ya recordado.
class _SeededLastEmail extends LastEmail {
  _SeededLastEmail(this.seed);
  final String seed;

  @override
  String? build() => seed;
}

void main() {
  testWidgets(
    'LoginScreen precarga el email recordado (tras change-password)',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            lastEmailProvider.overrideWith(
              () => _SeededLastEmail('user@example.com'),
            ),
          ],
          child: const MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: LoginScreen(),
          ),
        ),
      );

      expect(find.text('user@example.com'), findsOneWidget);
    },
  );

  testWidgets('LoginScreen sin email recordado → campo vacío', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('user@example.com'), findsNothing);
  });
}
