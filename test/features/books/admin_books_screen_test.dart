import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/features/books/data/books_repository.dart';
import 'package:investep_app/features/books/domain/recommended_book.dart';
import 'package:investep_app/features/books/presentation/admin_books_screen.dart';
import 'package:investep_app/l10n/gen/app_localizations.dart';
import 'package:mocktail/mocktail.dart';

class MockBooksRepository extends Mock implements BooksRepository {}

void main() {
  late MockBooksRepository mockBooksRepository;
  late ProviderContainer container;

  setUp(() {
    mockBooksRepository = MockBooksRepository();
    container = ProviderContainer(
      overrides: [
        booksRepositoryProvider.overrideWithValue(mockBooksRepository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  final testBooks = [
    const RecommendedBook(
      id: 1,
      slug: 'habitos-atomicos',
      title: 'Hábitos Atómicos',
      author: 'James Clear',
      description: 'Un gran libro sobre hábitos.',
      url: 'https://amazon.com/habitos-atomicos',
      image: 'books/habitos-atomicos.webp',
      sortOrder: 10,
    ),
  ];

  testWidgets('AdminBooksScreen renders the list of books', (tester) async {
    when(
      () => mockBooksRepository.fetchRecommendedBooks(),
    ).thenAnswer((_) async => testBooks);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          locale: Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: AdminBooksScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Gestión de Libros'), findsOneWidget);
    expect(find.text('Hábitos Atómicos'), findsOneWidget);
    expect(find.text('Autor: James Clear'), findsOneWidget);
    expect(find.text('Slug: habitos-atomicos | Orden: 10'), findsOneWidget);
  });

  testWidgets(
    'AdminBooksScreen deletion triggers dialog and calls deleteRecommendedBook',
    (tester) async {
      when(
        () => mockBooksRepository.fetchRecommendedBooks(),
      ).thenAnswer((_) async => testBooks);
      when(
        () => mockBooksRepository.deleteRecommendedBook(1),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: AdminBooksScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Click delete icon button (trash2 icon)
      final deleteButton = find.byTooltip('Eliminar');
      expect(deleteButton, findsOneWidget);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      // Verify confirmation dialog is shown
      expect(find.text('Confirmar eliminación'), findsOneWidget);
      expect(
        find.text(
          '¿Estás seguro de que deseas eliminar el libro "Hábitos Atómicos"?',
        ),
        findsOneWidget,
      );

      // Click confirm deletion button
      final confirmButton = find.text('Eliminar').last;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // Verify deletion call was made to repository
      verify(() => mockBooksRepository.deleteRecommendedBook(1)).called(1);
    },
  );
}
