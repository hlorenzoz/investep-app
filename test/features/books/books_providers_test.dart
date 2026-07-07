import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:investep_app/features/books/data/books_repository.dart';
import 'package:investep_app/features/books/domain/recommended_book.dart';
import 'package:investep_app/features/books/presentation/books_providers.dart';
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
  ];

  test('publicBooksProvider fetches recommended books list', () async {
    when(
      () => mockBooksRepository.fetchRecommendedBooks(),
    ).thenAnswer((_) async => testBooks);

    final books = await container.read(publicBooksProvider.future);

    expect(books, testBooks);
    verify(() => mockBooksRepository.fetchRecommendedBooks()).called(1);
  });

  test('adminBooksProvider fetches recommended books list', () async {
    when(
      () => mockBooksRepository.fetchRecommendedBooks(),
    ).thenAnswer((_) async => testBooks);

    final books = await container.read(adminBooksProvider.future);

    expect(books, testBooks);
    verify(() => mockBooksRepository.fetchRecommendedBooks()).called(1);
  });

  test('bookDetailProvider fetches single book by id/slug', () async {
    when(
      () => mockBooksRepository.getRecommendedBook('habitos-atomicos'),
    ).thenAnswer((_) async => testBooks[0]);

    final book = await container.read(
      bookDetailProvider('habitos-atomicos').future,
    );

    expect(book, testBooks[0]);
    verify(
      () => mockBooksRepository.getRecommendedBook('habitos-atomicos'),
    ).called(1);
  });

  test(
    'BooksAdminController can create, update, and delete recommended books',
    () async {
      final payload = {
        'slug': 'test-book',
        'title': 'Test Book',
        'author': 'Test Author',
        'description': 'Test Desc',
        'url': 'https://test.com',
        'image': 'books/test.webp',
        'sortOrder': 30,
      };

      when(
        () => mockBooksRepository.createRecommendedBook(payload),
      ).thenAnswer((_) async => testBooks[0]);
      when(
        () => mockBooksRepository.updateRecommendedBook(1, payload),
      ).thenAnswer((_) async => testBooks[0]);
      when(
        () => mockBooksRepository.deleteRecommendedBook(1),
      ).thenAnswer((_) async => true);

      final controller = container.read(booksAdminControllerProvider.notifier);

      // Create
      final createSuccess = await controller.createRecommendedBook(payload);
      expect(createSuccess, isTrue);
      verify(
        () => mockBooksRepository.createRecommendedBook(payload),
      ).called(1);

      // Update
      final updateSuccess = await controller.updateRecommendedBook(1, payload);
      expect(updateSuccess, isTrue);
      verify(
        () => mockBooksRepository.updateRecommendedBook(1, payload),
      ).called(1);

      // Delete
      final deleteSuccess = await controller.deleteRecommendedBook(1);
      expect(deleteSuccess, isTrue);
      verify(() => mockBooksRepository.deleteRecommendedBook(1)).called(1);
    },
  );
}
