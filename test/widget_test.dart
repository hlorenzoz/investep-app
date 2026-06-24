import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:investep_app/app/app.dart';

void main() {
  testWidgets('arranca en la pantalla de Login', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InvestepApp()));
    await tester.pumpAndSettle();

    // La pantalla inicial muestra el título de la app y la tarjeta de inicio de sesión.
    expect(find.text('Investep Auth'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
    expect(find.byIcon(LucideIcons.shieldCheck), findsOneWidget);
  });
}
