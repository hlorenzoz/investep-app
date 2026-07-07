import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/core/network/api_exception.dart';
import 'package:investep_app/features/books/data/books_repository.dart';
import 'package:mocktail/mocktail.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio dio;
  late BooksRepository repo;

  setUp(() {
    dio = MockDio();
    repo = BooksRepository(dio, retryBaseDelay: Duration.zero);
  });

  Response<Map<String, dynamic>> ok(Map<String, dynamic> data) => Response(
    requestOptions: RequestOptions(path: '/'),
    statusCode: 200,
    data: data,
  );

  DioException dioErr(int status, String code, String message) => DioException(
    requestOptions: RequestOptions(path: '/'),
    type: DioExceptionType.badResponse,
    response: Response(
      requestOptions: RequestOptions(path: '/'),
      statusCode: status,
      data: {
        'error': {'code': code, 'message': message},
      },
    ),
  );

  final testBookJson = {
    'id': 1,
    'slug': 'habitos-atomicos',
    'title': 'Hábitos Atómicos',
    'author': 'James Clear',
    'description': 'Un gran libro sobre hábitos.',
    'url': 'https://amazon.com/habitos-atomicos',
    'image': 'books/habitos-atomicos.webp',
    'sortOrder': 10,
  };

  test('fetchRecommendedBooks parses the recommended books list', () async {
    when(() => dio.get<Map<String, dynamic>>('/recommended-books')).thenAnswer(
      (_) async => ok({
        'recommendedBooks': [testBookJson],
      }),
    );

    final books = await repo.fetchRecommendedBooks();

    expect(books, hasLength(1));
    final b = books.first;
    expect(b.id, 1);
    expect(b.slug, 'habitos-atomicos');
    expect(b.title, 'Hábitos Atómicos');
    expect(b.author, 'James Clear');
    expect(b.description, 'Un gran libro sobre hábitos.');
    expect(b.url, 'https://amazon.com/habitos-atomicos');
    expect(b.image, 'books/habitos-atomicos.webp');
    expect(b.sortOrder, 10);
  });

  test('getRecommendedBook parses a single recommended book details', () async {
    when(
      () =>
          dio.get<Map<String, dynamic>>('/recommended-books/habitos-atomicos'),
    ).thenAnswer((_) async => ok({'recommendedBook': testBookJson}));

    final b = await repo.getRecommendedBook('habitos-atomicos');

    expect(b.id, 1);
    expect(b.slug, 'habitos-atomicos');
    expect(b.title, 'Hábitos Atómicos');
    expect(b.author, 'James Clear');
    expect(b.description, 'Un gran libro sobre hábitos.');
    expect(b.url, 'https://amazon.com/habitos-atomicos');
    expect(b.image, 'books/habitos-atomicos.webp');
    expect(b.sortOrder, 10);
  });

  test('401 error throws ApiException without retries', () async {
    when(() => dio.get<Map<String, dynamic>>('/recommended-books')).thenAnswer(
      (_) async => throw dioErr(401, 'UNAUTHORIZED', 'Token inválido'),
    );

    await expectLater(
      repo.fetchRecommendedBooks(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
    verify(() => dio.get<Map<String, dynamic>>('/recommended-books')).called(1);
  });

  test('retries on 503 and succeeds on second attempt', () async {
    var calls = 0;
    when(() => dio.get<Map<String, dynamic>>('/recommended-books')).thenAnswer((
      _,
    ) async {
      calls++;
      if (calls == 1) throw dioErr(503, 'SERVICE_UNAVAILABLE', 'caído');
      return ok({
        'recommendedBooks': [testBookJson],
      });
    });

    final books = await repo.fetchRecommendedBooks();

    expect(calls, 2);
    expect(books, hasLength(1));
  });

  group('CRUD operations', () {
    test(
      'createRecommendedBook sends POST to /admin/recommended-books',
      () async {
        final payload = {
          'slug': 'test-book',
          'title': 'Test Book',
          'author': 'Test Author',
          'description': 'Test Desc',
          'url': 'https://test.com',
          'image': 'books/test.webp',
          'sortOrder': 20,
        };

        when(
          () => dio.post<Map<String, dynamic>>(
            '/admin/recommended-books',
            data: payload,
          ),
        ).thenAnswer(
          (_) async => ok({
            'recommendedBook': {'id': 2, ...payload},
          }),
        );

        final book = await repo.createRecommendedBook(payload);

        expect(book.id, 2);
        expect(book.slug, 'test-book');
        expect(book.title, 'Test Book');
        verify(
          () => dio.post<Map<String, dynamic>>(
            '/admin/recommended-books',
            data: payload,
          ),
        ).called(1);
      },
    );

    test(
      'updateRecommendedBook sends PATCH to /admin/recommended-books/{id}',
      () async {
        final payload = {'title': 'Updated Title'};

        when(
          () => dio.patch<Map<String, dynamic>>(
            '/admin/recommended-books/1',
            data: payload,
          ),
        ).thenAnswer(
          (_) async => ok({
            'recommendedBook': {
              'id': 1,
              'slug': 'habitos-atomicos',
              'title': 'Updated Title',
              'author': 'James Clear',
              'description': 'Un gran libro sobre hábitos.',
              'url': 'https://amazon.com/habitos-atomicos',
              'image': 'books/habitos-atomicos.webp',
              'sortOrder': 10,
            },
          }),
        );

        final book = await repo.updateRecommendedBook(1, payload);

        expect(book.id, 1);
        expect(book.title, 'Updated Title');
        verify(
          () => dio.patch<Map<String, dynamic>>(
            '/admin/recommended-books/1',
            data: payload,
          ),
        ).called(1);
      },
    );

    test(
      'deleteRecommendedBook sends DELETE to /admin/recommended-books/{id}',
      () async {
        when(
          () => dio.delete<Map<String, dynamic>>('/admin/recommended-books/1'),
        ).thenAnswer((_) async => ok({'deleted': true}));

        final deleted = await repo.deleteRecommendedBook(1);

        expect(deleted, isTrue);
        verify(
          () => dio.delete<Map<String, dynamic>>('/admin/recommended-books/1'),
        ).called(1);
      },
    );
  });
}
