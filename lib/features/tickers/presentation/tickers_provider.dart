import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/ticker_repository.dart';
import '../domain/ticker.dart';

/// Notifier para la consulta de búsqueda debounced.
class TickerSearchNotifier extends Notifier<String> {
  Timer? _debounceTimer;

  @override
  String build() {
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    return '';
  }

  void search(String query) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      state = query;
    });
  }
}

final tickerSearchQueryProvider =
    NotifierProvider.autoDispose<TickerSearchNotifier, String>(() {
      return TickerSearchNotifier();
    });

/// Notifier para el filtro de tipo de activo (assetClass).
class TickerAssetClassFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setFilter(String? val) {
    state = val;
  }
}

final tickerAssetClassFilterProvider =
    NotifierProvider.autoDispose<TickerAssetClassFilterNotifier, String?>(() {
      return TickerAssetClassFilterNotifier();
    });

/// Notifier para el filtro de sector.
class TickerSectorFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  
  void setFilter(String? val) {
    state = val;
  }
}

final tickerSectorFilterProvider =
    NotifierProvider.autoDispose<TickerSectorFilterNotifier, String?>(() {
      return TickerSectorFilterNotifier();
    });

/// Notifier para el control de página.
class TickerPageNotifier extends Notifier<int> {
  @override
  int build() => 1;
  
  void setPage(int val) {
    state = val;
  }

  void increment() {
    state++;
  }

  void decrement() {
    state--;
  }
}

final tickerPageProvider =
    NotifierProvider.autoDispose<TickerPageNotifier, int>(() {
      return TickerPageNotifier();
    });

/// Provider que expone la lista paginada de activos reaccionando a los filtros.
final tickersListProvider = FutureProvider.autoDispose<PaginatedTickers>((ref) {
  final query = ref.watch(tickerSearchQueryProvider);
  final assetClass = ref.watch(tickerAssetClassFilterProvider);
  final sector = ref.watch(tickerSectorFilterProvider);
  final page = ref.watch(tickerPageProvider);

  return ref.watch(tickerRepositoryProvider).getTickers(
    q: query.trim().isEmpty ? null : query.trim(),
    assetClass: assetClass,
    sector: sector,
    page: page,
  );
});

/// Provider para obtener el detalle de un activo por símbolo.
final tickerDetailProvider =
    FutureProvider.autoDispose.family<TickerDetail, String>((ref, symbol) {
      return ref.watch(tickerRepositoryProvider).getTickerDetail(symbol);
    });

/// Notifier para las mutaciones administrativas de activos (creación, edición, borrado, relaciones, planes).
class AdminTickersNotifier extends AsyncNotifier<void> {
  @override
  FutureOr<void> build() {}

  Future<void> createTicker(Map<String, dynamic> data) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).createTicker(data);
      ref.invalidate(tickersListProvider);
    });
  }

  Future<void> updateTicker(int id, Map<String, dynamic> data, String symbolForInvalidate) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).updateTicker(id, data);
      ref.invalidate(tickersListProvider);
      ref.invalidate(tickerDetailProvider(symbolForInvalidate));
    });
  }

  Future<void> deleteTicker(int id) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).deleteTicker(id);
      ref.invalidate(tickersListProvider);
    });
  }

  Future<void> addRelation(
    int id, {
    required int relatedTickerId,
    required String relationType,
    required double multiplier,
    required String symbolForInvalidate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).addRelation(
        id,
        relatedTickerId: relatedTickerId,
        relationType: relationType,
        multiplier: multiplier,
      );
      ref.invalidate(tickerDetailProvider(symbolForInvalidate));
    });
  }

  Future<void> deleteRelation(
    int id, {
    required int relatedTickerId,
    required String relationType,
    required String symbolForInvalidate,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).deleteRelation(
        id,
        relatedTickerId: relatedTickerId,
        relationType: relationType,
      );
      ref.invalidate(tickerDetailProvider(symbolForInvalidate));
    });
  }

  Future<void> addPlan(int id, int planId, String symbolForInvalidate) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).addPlan(id, planId);
      ref.invalidate(tickerDetailProvider(symbolForInvalidate));
    });
  }

  Future<void> deletePlan(int id, int planId, String symbolForInvalidate) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await ref.read(tickerRepositoryProvider).deletePlan(id, planId);
      ref.invalidate(tickerDetailProvider(symbolForInvalidate));
    });
  }
}

final adminTickersProvider =
    AsyncNotifierProvider<AdminTickersNotifier, void>(
      AdminTickersNotifier.new,
    );
