import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticker_repository.dart';
import '../domain/ticker.dart';

/// Overlay optimista de favoritos.
///
/// Es la fuente de verdad INMEDIATA del estado favorito de un símbolo: guarda
/// solo los símbolos togglados en la sesión con su estado deseado. Las estrellas
/// de toda la app leen `override[symbol] ?? item.isFavorite`, de modo que un
/// toggle se refleja al instante en TODAS las superficies (relaciones, chips y la
/// sección de favoritos) sin recargar la pantalla.
class FavoritesOverride extends Notifier<Map<String, bool>> {
  @override
  Map<String, bool> build() => const {};

  /// Estado favorito efectivo combinando el overlay con el valor base del dato.
  bool isFavorite(String symbol, bool fallback) => state[symbol] ?? fallback;

  /// Marca/desmarca de forma optimista y sincroniza con el backend.
  ///
  /// - Actualiza el overlay al instante.
  /// - En éxito invalida la lista de favoritos (reconcilia la sección superior).
  /// - En error revierte el overlay y RELANZA para que la UI avise al usuario.
  ///   401 lo maneja el interceptor global; 503 ya se reintenta en el repo.
  Future<void> toggle(String symbol, bool next) async {
    final previous = state[symbol];
    state = {...state, symbol: next};

    try {
      final repo = ref.read(tickerRepositoryProvider);
      if (next) {
        await repo.addFavorite(symbol);
      } else {
        await repo.removeFavorite(symbol);
      }
      ref.invalidate(favoriteTickersProvider);
    } catch (_) {
      // Rollback: restaurar el valor previo (o quitar la clave si no existía).
      final reverted = {...state};
      if (previous == null) {
        reverted.remove(symbol);
      } else {
        reverted[symbol] = previous;
      }
      state = reverted;
      rethrow;
    }
  }
}

final favoritesOverrideProvider =
    NotifierProvider<FavoritesOverride, Map<String, bool>>(
      FavoritesOverride.new,
    );

/// Lista de activos favoritos del usuario (`GET /tickers?favorite=true`).
/// Alimenta la sección "Favoritos" fija encima del listado.
final favoriteTickersProvider = FutureProvider.autoDispose<List<Ticker>>((ref) {
  return ref.watch(tickerRepositoryProvider).getFavorites();
});
