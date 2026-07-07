import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/books/data/books_repository.dart';
import 'package:investep_app/features/books/domain/recommended_book.dart';
import 'package:investep_app/features/books/presentation/book_detail_screen.dart';
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

  const testBook = RecommendedBook(
    id: 1,
    slug: 'habitos-atomicos',
    title: 'Hábitos Atómicos',
    author: 'James Clear',
    description: 'Un gran libro sobre hábitos.',
    url: 'https://youtube.com/results?search_query=habitos+atomicos',
    image: 'books/habitos-atomicos.webp',
    sortOrder: 10,
  );

  testWidgets(
    'BookDetailScreen renders correctly with loading and loaded data',
    (tester) async {
      when(
        () => mockBooksRepository.getRecommendedBook('habitos-atomicos'),
      ).thenAnswer((_) async => testBook);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            locale: Locale('es'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BookDetailScreen(idOrSlug: 'habitos-atomicos'),
          ),
        ),
      );

      // Shows loading first
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verifies metadata rendered
      expect(find.text('Detalle del Libro'), findsOneWidget);
      expect(find.text('Hábitos Atómicos'), findsOneWidget);
      expect(find.text('Autor: James Clear'), findsOneWidget);
      expect(find.text('Un gran libro sobre hábitos.'), findsOneWidget);
      expect(find.text('Escucha el audio libro en YouTube'), findsOneWidget);
    },
  );

  testWidgets(
    'BookDetailScreen renders correctly when GoRouter extra is a serialized Map (web history restoration)',
    (tester) async {
      final Map<String, dynamic> serializedBook = testBook.toJson();

      final router = GoRouter(
        initialLocation: '/books',
        routes: [
          GoRoute(
            path: '/books',
            builder: (context, state) => const Scaffold(body: Text('Root')),
            routes: [
              GoRoute(
                path: ':idOrSlug',
                builder: (context, state) {
                  final idOrSlug = state.pathParameters['idOrSlug']!;
                  final extra = state.extra;
                  final book = extra is RecommendedBook
                      ? extra
                      : (extra is Map
                            ? RecommendedBook.fromJson(
                                Map<String, dynamic>.from(extra),
                              )
                            : null);
                  return BookDetailScreen(idOrSlug: idOrSlug, book: book);
                },
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

      // Navigate to detail route passing the serialized map as extra
      router.go('/books/habitos-atomicos', extra: serializedBook);
      await tester.pumpAndSettle();

      // Verify it deserialized the Map and rendered the details immediately without loading indicator
      expect(find.text('Hábitos Atómicos'), findsOneWidget);
      expect(find.text('Autor: James Clear'), findsOneWidget);
      expect(find.text('Un gran libro sobre hábitos.'), findsOneWidget);
    },
  );
}
