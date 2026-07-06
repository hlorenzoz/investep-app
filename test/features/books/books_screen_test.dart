import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/books/presentation/books_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';

Widget _app() => const MaterialApp(
  locale: Locale('es'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: BooksScreen(),
);

void main() {
  testWidgets('BooksScreen renders correct title and implementation text', (
    tester,
  ) async {
    await tester.pumpWidget(_app());
    await tester.pumpAndSettle();

    expect(find.text('Books'), findsNWidgets(2)); // Title and Card text
    expect(find.text('Esta sección está por implementar.'), findsOneWidget);
  });
}
