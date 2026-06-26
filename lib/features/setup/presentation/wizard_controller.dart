import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../capital/data/capital_repository.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/presentation/capital_controller.dart';
import 'setup_mode.dart';
import 'wizard_data.dart';

/// Índices de los slides del wizard (absolutos en ambos modos).
abstract final class WizardSlide {
  static const int capital = 0;
  static const int broker = 1;
  static const int accountType = 2;
  static const int plan = 3;
  static const int deposit = 4;
  static const int summary = 5;
  static const int max = summary;
}

/// Paso de una operación de escritura del wizard.
enum WizardStep { capital, allocation }

/// Estado del wizard: datos acumulados + slide actual, con sub-estado de
/// escritura (submitting / error) superpuesto.
sealed class WizardState {
  final WizardData data;
  final int slideIndex;
  const WizardState(this.data, this.slideIndex);
}

class WizardIdle extends WizardState {
  const WizardIdle(super.data, super.slideIndex);
}

class WizardSubmitting extends WizardState {
  final WizardStep step;
  const WizardSubmitting(super.data, super.slideIndex, this.step);
}

class WizardStepError extends WizardState {
  final WizardStep step;
  final String message;
  final bool retryable;
  const WizardStepError(
    super.data,
    super.slideIndex, {
    required this.step,
    required this.message,
    required this.retryable,
  });
}

/// La allocation se creó con éxito: el wizard terminó. La vista cierra el flujo
/// y vuelve al dashboard.
class WizardCompleted extends WizardState {
  const WizardCompleted(super.data, super.slideIndex);
}

/// Controlador único del wizard, parametrizado por [SetupMode].
///
/// Los datos async de brokers/plans NO viven acá (los slides observan sus
/// `FutureProvider`s): este controlador sólo posee los datos acumulados, el
/// slide actual y las dos escrituras (PUT capital / POST allocation).
class WizardController extends Notifier<WizardState> {
  WizardController(this.mode);

  /// Modo del wizard (arg de la family, inyectado por constructor).
  final SetupMode mode;

  bool _disposed = false;

  int get _minSlide =>
      mode == SetupMode.initialSetup ? WizardSlide.capital : WizardSlide.broker;

  /// Setea el estado sólo si el notifier sigue vivo. Las escrituras (`submit*`)
  /// completan después de `await`s: si el wizard se desmontó (p. ej. el usuario
  /// navegó al dashboard) el provider autoDispose ya se liberó y un `state =`
  /// tiraría StateError.
  void _set(WizardState next) {
    if (_disposed) return;
    state = next;
  }

  @override
  WizardState build() {
    ref.onDispose(() => _disposed = true);

    var data = const WizardData();
    if (mode == SetupMode.addBroker) {
      // Sembramos capital/moneda del capital existente (no editable acá).
      final overview = ref.read(capitalControllerProvider).value;
      final capital = overview?.capital;
      if (capital != null) {
        data = data.copyWith(
          totalCapital: capital.totalCapital,
          currency: capital.currency,
        );
      }
    }
    return WizardIdle(data, _minSlide);
  }

  // --- setters por slide ---

  void setCapital(num amount, String currency) {
    state = WizardIdle(
      state.data.copyWith(totalCapital: amount, currency: currency),
      state.slideIndex,
    );
  }

  void setBroker(int brokerId) {
    // Cambiar de broker invalida el tipo de cuenta y el plan elegidos: las
    // combinaciones disponibles dependen del broker.
    state = WizardIdle(
      state.data.copyWith(
        brokerId: brokerId,
        clearAccountType: true,
        clearPlan: true,
      ),
      state.slideIndex,
    );
  }

  void setAccountType(AccountType type) {
    // Cambiar el tipo invalida el plan elegido (filtra el slide de planes).
    state = WizardIdle(
      state.data.copyWith(accountType: type, clearPlan: true),
      state.slideIndex,
    );
  }

  void setPlan(int investmentPlanId) {
    state = WizardIdle(
      state.data.copyWith(investmentPlanId: investmentPlanId),
      state.slideIndex,
    );
  }

  void setDeposit(DepositInput deposit) {
    state = WizardIdle(state.data.copyWith(deposit: deposit), state.slideIndex);
  }

  // --- navegación ---

  void goTo(int slide) {
    final clamped = slide.clamp(_minSlide, WizardSlide.max);
    state = WizardIdle(state.data, clamped);
  }

  void next() => goTo(state.slideIndex + 1);
  void back() => goTo(state.slideIndex - 1);

  // --- escrituras ---

  /// Slide 0 → `PUT /capital`. 409 → error; éxito → avanza al broker.
  Future<void> submitCapital() async {
    if (state is WizardSubmitting) return; // evita doble submit
    final data = state.data;
    _set(WizardSubmitting(data, state.slideIndex, WizardStep.capital));
    try {
      final capital = await ref
          .read(capitalRepositoryProvider)
          .putCapital(
            totalCapital: data.totalCapital ?? 0,
            currency: data.currency,
          );
      // Refrescamos el capital para que `available` refleje el monto recién
      // definido (lo usa el slide de depósito en initialSetup).
      await ref.read(capitalControllerProvider.notifier).refresh();
      _set(
        WizardIdle(
          data.copyWith(
            totalCapital: capital.totalCapital,
            currency: capital.currency,
          ),
          WizardSlide.broker,
        ),
      );
    } on ApiException catch (e) {
      _emitError(WizardStep.capital, e);
    }
  }

  /// Slide 5 → `POST /capital/allocations`. Envía el depósito resuelto y NUNCA
  /// accountType. Éxito → refresca capital y marca el wizard como completado
  /// (la vista cierra el flujo y vuelve al dashboard).
  Future<void> submitAllocation() async {
    // Guard de reentrada: tras un éxito el estado es WizardCompleted pero la
    // navegación al dashboard es async; impide un segundo POST (allocation
    // duplicada) por doble-tap o swipe en el resumen.
    if (state is WizardSubmitting || state is WizardCompleted) return;
    final data = state.data;
    _set(WizardSubmitting(data, state.slideIndex, WizardStep.allocation));
    try {
      await ref
          .read(capitalRepositoryProvider)
          .createAllocation(
            brokerId: data.brokerId!,
            investmentPlanId: data.investmentPlanId!,
            initialDeposit: data.resolvedDeposit,
            currency: data.currency,
          );
      // Recalcula available/allocations para el dashboard.
      await ref.read(capitalControllerProvider.notifier).refresh();
      _set(WizardCompleted(data, state.slideIndex));
    } on ApiException catch (e) {
      _emitError(WizardStep.allocation, e);
    }
  }

  void _emitError(WizardStep step, ApiException e) {
    _set(
      WizardStepError(
        state.data,
        state.slideIndex,
        step: step,
        message: e.message,
        retryable: e.isRetryable,
      ),
    );
  }
}

final wizardControllerProvider = NotifierProvider.autoDispose
    .family<WizardController, WizardState, SetupMode>(WizardController.new);
