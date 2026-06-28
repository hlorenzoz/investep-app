import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/l10n/locale_provider.dart';
import 'package:investep_app/shared/widgets/language_selector.dart';

void main() {
  testWidgets('LanguageSelector alterna entre ES y EN al presionar', (
    tester,
  ) async {
    late ProviderContainer container;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container = ProviderContainer(),
        child: MaterialApp(
          home: Scaffold(appBar: AppBar(actions: const [LanguageSelector()])),
        ),
      ),
    );

    // Inicialmente debe estar en 'es' (ES)
    expect(container.read(localeProvider).languageCode, 'es');
    expect(find.text('ES'), findsOneWidget);

    // Al presionar debe cambiar a 'en' (EN)
    await tester.tap(find.byType(LanguageSelector));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider).languageCode, 'en');
    expect(find.text('EN'), findsOneWidget);

    // Al presionar de nuevo vuelve a 'es' (ES)
    await tester.tap(find.byType(LanguageSelector));
    await tester.pumpAndSettle();

    expect(container.read(localeProvider).languageCode, 'es');
    expect(find.text('ES'), findsOneWidget);

    container.dispose();
  });
}
