import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investep_app/features/tickers/data/ticker_repository.dart';
import 'package:investep_app/features/tickers/presentation/favorites_controller.dart';
import 'package:mocktail/mocktail.dart';

class MockTickerRepository extends Mock implements TickerRepository {}

void main() {
  late MockTickerRepository repo;
  late ProviderContainer container;

  setUp(() {
    repo = MockTickerRepository();
    when(() => repo.getFavorites()).thenAnswer((_) async => []);
    container = ProviderContainer(
      overrides: [tickerRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
  });

  FavoritesOverride notifier() =>
      container.read(favoritesOverrideProvider.notifier);
  Map<String, bool> overrideState() =>
      container.read(favoritesOverrideProvider);

  test('isFavorite usa el overlay por encima del fallback del dato', () {
    expect(notifier().isFavorite('AAPL', false), isFalse);
    container.read(favoritesOverrideProvider.notifier).state = {'AAPL': true};
    expect(notifier().isFavorite('AAPL', false), isTrue);
  });

  test('toggle marca el overlay al instante (optimista)', () async {
    when(() => repo.addFavorite('AAPL')).thenAnswer((_) async => true);

    final future = notifier().toggle('AAPL', true);

    // Antes de resolver la llamada, el overlay ya refleja el cambio.
    expect(overrideState()['AAPL'], isTrue);

    await future;
    expect(overrideState()['AAPL'], isTrue);
    verify(() => repo.addFavorite('AAPL')).called(1);
  });

  test('toggle revierte el overlay y relanza si la llamada falla', () async {
    when(() => repo.addFavorite('AAPL')).thenThrow(Exception('boom'));

    await expectLater(notifier().toggle('AAPL', true), throwsException);

    // Rollback: la clave vuelve a no existir (valor previo era null).
    expect(overrideState().containsKey('AAPL'), isFalse);
  });

  test('toggle a false revierte al valor previo si falla', () async {
    // Estado previo: AAPL marcado como favorito en el overlay.
    container.read(favoritesOverrideProvider.notifier).state = {'AAPL': true};
    when(() => repo.removeFavorite('AAPL')).thenThrow(Exception('boom'));

    await expectLater(notifier().toggle('AAPL', false), throwsException);

    // Rollback al valor previo (true), no se pierde.
    expect(overrideState()['AAPL'], isTrue);
  });
}
