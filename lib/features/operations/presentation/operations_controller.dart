import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/operations_repository.dart';
import '../domain/operation.dart';

/// Controlador para la lista de operaciones de una cuenta (allocation) específica.
class OperationsController extends AsyncNotifier<List<Operation>> {
  OperationsController(this.allocationId);

  final String allocationId;

  @override
  Future<List<Operation>> build() {
    return ref.read(operationsRepositoryProvider).getOperations(allocationId: allocationId);
  }

  /// Recarga la lista de operaciones desde el backend.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(operationsRepositoryProvider).getOperations(allocationId: allocationId),
    );
  }

  /// Registra la venta de una operación abierta.
  Future<void> registerSale(
    String operationId, {
    required DateTime soldAt,
    required double sellPrice,
  }) async {
    await ref.read(operationsRepositoryProvider).patchOperation(
      operationId,
      {
        // Fecha sola (YYYY-MM-DD); el backend compara "venta ≥ compra" por día.
        'soldAt': operationApiDate(soldAt),
        'sellPrice': sellPrice,
      },
    );
    await refresh();
  }

  /// Reabre una operación cerrada (estableciendo `soldAt` y `sellPrice` en null).
  Future<void> reopenOperation(String operationId) async {
    await ref.read(operationsRepositoryProvider).patchOperation(
      operationId,
      {
        'soldAt': null,
        'sellPrice': null,
      },
    );
    await refresh();
  }

  /// Elimina una operación.
  Future<void> delete(String operationId) async {
    await ref.read(operationsRepositoryProvider).deleteOperation(operationId);
    await refresh();
  }
}

final operationsControllerProvider = AsyncNotifierProvider.autoDispose
    .family<OperationsController, List<Operation>, String>(
      OperationsController.new,
    );
