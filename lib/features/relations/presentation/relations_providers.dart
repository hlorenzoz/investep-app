import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/relations_repository.dart';
import '../domain/relations_overview.dart';

/// Provider de la vista de relaciones entre activos. Una sola llamada al
/// endpoint agregado; sin caché ni estado extra (igual que el resto de
/// endpoints de tickers).
final relationsOverviewProvider = FutureProvider.autoDispose<RelationsOverview>(
  (ref) {
    return ref.watch(relationsRepositoryProvider).fetchRelationsOverview();
  },
);
