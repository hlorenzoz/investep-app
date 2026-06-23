import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:investep_app/app/app.dart';

void main() {
  testWidgets('arranca en la pantalla de Cartera', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: InvestepApp()));
    await tester.pumpAndSettle();

    // La pantalla inicial muestra el título y el ícono Lucide de la cartera.
    expect(find.text('Cartera'), findsOneWidget);
    expect(find.byIcon(LucideIcons.wallet), findsOneWidget);
  });
}
