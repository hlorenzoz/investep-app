import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/capital_repository.dart';
import '../domain/capital_overview.dart';

/// Estado del capital del usuario para el dashboard y el wizard.
///
/// `build` carga `GET /capital`. `refresh` lo re-pide tras cada mutación
/// (PUT capital / POST allocation) para recalcular `available`.
class CapitalController extends AsyncNotifier<CapitalOverview> {
  @override
  Future<CapitalOverview> build() {
    return ref.read(capitalRepositoryProvider).getCapital();
  }

  /// Re-pide el capital tras una mutación (recalcula `available`).
  Future<void> refresh() async {
    state = await AsyncValue.guard(
      () => ref.read(capitalRepositoryProvider).getCapital(),
    );
  }
}

final capitalControllerProvider =
    AsyncNotifierProvider<CapitalController, CapitalOverview>(
      CapitalController.new,
    );
