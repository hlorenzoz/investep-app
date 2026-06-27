import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../capital/data/capital_repository.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../../setup/presentation/wizard_data.dart';

/// Estado de la edición de una allocation. Sólo posee los campos editables vía
/// `PATCH /capital/allocations/{id}`: el plan y el depósito. El broker y el tipo
/// de cuenta son inmutables; la moneda queda atada a la del capital.
sealed class EditState {
  final int? investmentPlanId;
  final DepositInput deposit;
  const EditState(this.investmentPlanId, this.deposit);
}

class EditIdle extends EditState {
  const EditIdle(super.investmentPlanId, super.deposit);
}

class EditSubmitting extends EditState {
  const EditSubmitting(super.investmentPlanId, super.deposit);
}

class EditError extends EditState {
  final String message;
  final bool retryable;
  const EditError(
    super.investmentPlanId,
    super.deposit, {
    required this.message,
    required this.retryable,
  });
}

/// El PATCH se aplicó: la vista cierra la edición y vuelve atrás.
class EditCompleted extends EditState {
  const EditCompleted(super.investmentPlanId, super.deposit);
}

/// Controlador de la edición de una allocation, parametrizado por su `id`.
///
/// Siembra el plan y el depósito (en modo monto) a partir de la allocation
/// VIVA de [capitalControllerProvider]. Las pantallas que lo consumen gatean su
/// construcción tras `capitalControllerProvider.when(data: ...)`, de modo que el
/// overview ya está resuelto cuando corre `build` (sin carrera de primer frame)
/// y la siembra refleja siempre el último valor guardado. `submit` hace el PATCH
/// con el depósito resuelto contra el capital actual y refresca el dashboard.
class EditAllocationController extends Notifier<EditState> {
  EditAllocationController(this.allocationId);

  /// Id de la allocation a editar (arg de la family, vía constructor).
  final String allocationId;

  bool _disposed = false;

  void _set(EditState next) {
    if (_disposed) return;
    state = next;
  }

  Allocation? _findAllocation() {
    final overview = ref.read(capitalControllerProvider).value;
    if (overview == null) return null;
    for (final a in overview.allocations) {
      if (a.id == allocationId) return a;
    }
    return null;
  }

  @override
  EditState build() {
    ref.onDispose(() => _disposed = true);

    final alloc = _findAllocation();
    final deposit = alloc != null
        ? DepositInput(mode: DepositMode.amount, amount: alloc.initialDeposit)
        : const DepositInput();
    return EditIdle(alloc?.investmentPlanId, deposit);
  }

  void setPlan(int investmentPlanId) {
    state = EditIdle(investmentPlanId, state.deposit);
  }

  void setDeposit(DepositInput deposit) {
    state = EditIdle(state.investmentPlanId, deposit);
  }

  /// `PATCH /capital/allocations/{id}` con plan + depósito resuelto. NO envía la
  /// moneda (inmutable a nivel allocation). Éxito → refresca capital y completa.
  Future<void> submit() async {
    // Guard de reentrada: tras completar, la navegación de vuelta es async; un
    // segundo submit no debe repetir el PATCH.
    if (state is EditSubmitting || state is EditCompleted) return;
    final planId = state.investmentPlanId;
    final deposit = state.deposit;
    final totalCapital =
        ref.read(capitalControllerProvider).value?.capital?.totalCapital ?? 0;
    final resolved = deposit.resolved(totalCapital);

    _set(EditSubmitting(planId, deposit));
    try {
      await ref
          .read(capitalRepositoryProvider)
          .patchAllocation(
            allocationId,
            investmentPlanId: planId,
            initialDeposit: resolved,
          );
      await ref.read(capitalControllerProvider.notifier).refresh();
      _set(EditCompleted(planId, deposit));
    } on ApiException catch (e) {
      _set(
        EditError(
          planId,
          deposit,
          message: e.message,
          retryable: e.isRetryable,
        ),
      );
    } catch (_) {
      // Cualquier error fuera del contrato de la API (p. ej. un 200 con body
      // inesperado que rompe el parseo) NO debe dejar el estado clavado en
      // EditSubmitting (spinner perpetuo). Mismo fallback que ApiException.
      _set(
        EditError(
          planId,
          deposit,
          message: 'Ocurrió un error inesperado.',
          retryable: true,
        ),
      );
    }
  }

  /// `DELETE /capital/allocations/{id}`. Éxito → refresca capital y completa.
  Future<void> delete() async {
    if (state is EditSubmitting || state is EditCompleted) return;
    final planId = state.investmentPlanId;
    final deposit = state.deposit;

    _set(EditSubmitting(planId, deposit));
    try {
      await ref.read(capitalRepositoryProvider).deleteAllocation(allocationId);
      await ref.read(capitalControllerProvider.notifier).refresh();
      _set(EditCompleted(planId, deposit));
    } on ApiException catch (e) {
      _set(
        EditError(
          planId,
          deposit,
          message: e.message,
          retryable: e.isRetryable,
        ),
      );
    } catch (_) {
      _set(
        EditError(
          planId,
          deposit,
          message: 'Ocurrió un error inesperado al eliminar la cuenta.',
          retryable: true,
        ),
      );
    }
  }
}

final editAllocationControllerProvider = NotifierProvider.autoDispose
    .family<EditAllocationController, EditState, String>(
      EditAllocationController.new,
    );
