import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/books/data/books_repository.dart';
import 'package:investep_app/features/books/domain/recommended_book.dart';
import 'package:investep_app/features/books/presentation/books_screen.dart';
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
      id: 2,
      slug: 'padre-rico-padre-pobre',
      title: 'Padre Rico Padre Pobre',
      author: 'Robert Kiyosaki',
      description: 'Educación financiera.',
      url: 'https://amazon.com/padre-rico',
      image: 'books/padre-rico.webp',
      sortOrder: 20,
    ),
    const RecommendedBook(
      id: 1,
      slug: 'habitos-atomicos',
      title: 'Hábitos Atómicos',
      author: 'James Clear',
      description: 'Un gran libro sobre hábitos.',
      url: 'https://youtube.com/results?search_query=habitos+atomicos',
      image: 'books/habitos-atomicos.webp',
      sortOrder: 10,
    ),
  ];

  testWidgets(
    'BooksScreen renders loading indicator and then the sorted list of books',
    (tester) async {
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
            home: BooksScreen(),
          ),
        ),
      );

      // Initial load shows CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify books are rendered and sorted by sortOrder (10: Habitos Atomicos first, then 20: Padre Rico)
      expect(find.text('Hábitos Atómicos'), findsOneWidget);
      expect(find.text('Padre Rico Padre Pobre'), findsOneWidget);
      expect(find.text('Autor: James Clear'), findsOneWidget);
      expect(find.text('Autor: Robert Kiyosaki'), findsOneWidget);

      // Verify sort order in a layout-agnostic way (either left-to-right or top-to-bottom)
      final habitsFinder = find.text('Hábitos Atómicos');
      final richDadFinder = find.text('Padre Rico Padre Pobre');
      final habitsPos = tester.getTopLeft(habitsFinder);
      final richDadPos = tester.getTopLeft(richDadFinder);

      if (habitsPos.dy == richDadPos.dy) {
        expect(habitsPos.dx < richDadPos.dx, isTrue);
      } else {
        expect(habitsPos.dy < richDadPos.dy, isTrue);
      }
    },
  );

  testWidgets('BooksScreen card click navigates to details view', (
    tester,
  ) async {
    when(
      () => mockBooksRepository.fetchRecommendedBooks(),
    ).thenAnswer((_) async => testBooks);

    final router = GoRouter(
      initialLocation: '/books',
      routes: [
        GoRoute(
          path: '/books',
          builder: (context, state) => const BooksScreen(),
          routes: [
            GoRoute(
              path: ':idOrSlug',
              builder: (context, state) => Scaffold(
                body: Text('DETAIL:${state.pathParameters['idOrSlug']}'),
              ),
            ),
          ],
        ),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on card of 'Hábitos Atómicos' (which is the InkWell that wraps the book details)
    final cardFinder = find.text('Hábitos Atómicos');
    await tester.tap(cardFinder);
    await tester.pumpAndSettle();

    // Verify we navigated to the detail screen displaying "DETAIL:habitos-atomicos"
    expect(find.text('DETAIL:habitos-atomicos'), findsOneWidget);
  });
}
