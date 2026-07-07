import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:investep_app/features/books/data/books_repository.dart';
import 'package:investep_app/features/books/domain/recommended_book.dart';
import 'package:investep_app/features/books/presentation/admin_book_form_screen.dart';
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
    registerFallbackValue(<String, dynamic>{});
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
    url: 'https://amazon.com/habitos-atomicos',
    image: 'books/habitos-atomicos.webp',
    sortOrder: 10,
  );

  Widget createTestWidget({int? bookId, RecommendedBook? book}) {
    final router = GoRouter(
      initialLocation: '/admin/books/form',
      routes: [
        GoRoute(
          path: '/admin/books',
          builder: (context, state) => const Scaffold(body: Text('BOOKS_LIST')),
        ),
        GoRoute(
          path: '/admin/books/form',
          builder: (context, state) =>
              AdminBookFormScreen(bookId: bookId, book: book),
        ),
      ],
    );

    // To allow context.pop() to work, we must push the form route above the base books list route
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
  }

  testWidgets('AdminBookFormScreen renders form fields and validates input', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Verify Title of Form
    expect(
      find.text('Crear Libro'),
      findsNWidgets(2),
    ); // AppBar and Submit Button

    // Click Submit Button to trigger validations
    final submitButton = find.widgetWithText(ElevatedButton, 'Crear Libro');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Check validation messages
    expect(find.text('El slug es obligatorio.'), findsOneWidget);
    expect(find.text('El título es obligatorio.'), findsOneWidget);
    expect(find.text('El autor es obligatorio.'), findsOneWidget);
    expect(find.text('La descripción es obligatoria.'), findsOneWidget);
    expect(find.text('El enlace es obligatorio.'), findsOneWidget);
    expect(find.text('La ruta de la imagen es obligatoria.'), findsOneWidget);
  });

  testWidgets('AdminBookFormScreen successfully submits creation payload', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    when(
      () => mockBooksRepository.createRecommendedBook(any()),
    ).thenAnswer((_) async => testBook);

    // Setup router with base books route
    final router = GoRouter(
      initialLocation: '/admin/books',
      routes: [
        GoRoute(
          path: '/admin/books',
          builder: (context, state) => const Scaffold(body: Text('BOOKS_LIST')),
        ),
        GoRoute(
          path: '/admin/books/form',
          builder: (context, state) => const AdminBookFormScreen(),
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

    await router.push('/admin/books/form');
    await tester.pumpAndSettle();

    // Enter valid inputs
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Slug'),
      'test-slug',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Título'),
      'Test Title',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Autor'),
      'Test Author',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Descripción'),
      'Test Description',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Enlace externo (URL)'),
      'https://test.com/book',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Ruta de la imagen'),
      'books/test.webp',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Orden de visualización (sortOrder)'),
      '5',
    );

    await tester.pumpAndSettle();

    // Click Submit
    final submitButton = find.widgetWithText(ElevatedButton, 'Crear Libro');
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    // Verify repository call
    verify(
      () => mockBooksRepository.createRecommendedBook({
        'slug': 'test-slug',
        'title': 'Test Title',
        'author': 'Test Author',
        'description': 'Test Description',
        'url': 'https://test.com/book',
        'image': 'books/test.webp',
        'sortOrder': 5,
      }),
    ).called(1);
  });

  testWidgets(
    'AdminBookFormScreen populates fields in edit mode and submits update payload',
    (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      when(
        () => mockBooksRepository.updateRecommendedBook(1, any()),
      ).thenAnswer((_) async => testBook);

      final router = GoRouter(
        initialLocation: '/admin/books',
        routes: [
          GoRoute(
            path: '/admin/books',
            builder: (context, state) =>
                const Scaffold(body: Text('BOOKS_LIST')),
          ),
          GoRoute(
            path: '/admin/books/form',
            builder: (context, state) =>
                const AdminBookFormScreen(bookId: 1, book: testBook),
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

      await router.push('/admin/books/form');
      await tester.pumpAndSettle();

      // Verify Title of Form and populated text
      expect(find.text('Editar Libro'), findsOneWidget);
      expect(find.text('Hábitos Atómicos'), findsOneWidget);

      // Modify Title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título'),
        'Hábitos Modificados',
      );

      await tester.pumpAndSettle();

      // Click Submit
      final submitButton = find.widgetWithText(
        ElevatedButton,
        'Guardar Cambios',
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      // Verify repository update call
      verify(
        () => mockBooksRepository.updateRecommendedBook(1, {
          'slug': 'habitos-atomicos',
          'title': 'Hábitos Modificados',
          'author': 'James Clear',
          'description': 'Un gran libro sobre hábitos.',
          'url': 'https://amazon.com/habitos-atomicos',
          'image': 'books/habitos-atomicos.webp',
          'sortOrder': 10,
        }),
      ).called(1);
    },
  );
}
