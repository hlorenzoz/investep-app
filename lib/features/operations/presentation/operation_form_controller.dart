import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../capital/domain/account_type.dart';
import '../../capital/domain/allocation.dart';
import '../../capital/presentation/capital_controller.dart';
import '../data/operations_repository.dart';
import '../domain/operation.dart';
import 'operations_controller.dart';

class OperationFormState {
  final String ticker;
  final DateTime openedAt;
  final String quantity;
  final String buyPrice;
  final String limitPrice;
  final String strike;
  final String expirationDate;
  final String? contractType; // 'call' | 'put'
  final String strategy;
  final String notes;
  final String url;

  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final bool isSuccess;

  // Errores de validación locales
  final String? tickerError;
  final String? quantityError;
  final String? buyPriceError;
  final String? strikeError;
  final String? expirationDateError;

  const OperationFormState({
    this.ticker = '',
    required this.openedAt,
    this.quantity = '',
    this.buyPrice = '',
    this.limitPrice = '',
    this.strike = '',
    this.expirationDate = '',
    this.contractType,
    this.strategy = '',
    this.notes = '',
    this.url = '',
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
    this.isSuccess = false,
    this.tickerError,
    this.quantityError,
    this.buyPriceError,
    this.strikeError,
    this.expirationDateError,
  });

  OperationFormState copyWith({
    String? ticker,
    DateTime? openedAt,
    String? quantity,
    String? buyPrice,
    String? limitPrice,
    String? strike,
    String? expirationDate,
    String? contractType,
    String? strategy,
    String? notes,
    String? url,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool? isSuccess,
    String? tickerError,
    String? quantityError,
    String? buyPriceError,
    String? strikeError,
    String? expirationDateError,
    bool clearContractType = false,
    bool clearErrors = false,
  }) {
    return OperationFormState(
      ticker: ticker ?? this.ticker,
      openedAt: openedAt ?? this.openedAt,
      quantity: quantity ?? this.quantity,
      buyPrice: buyPrice ?? this.buyPrice,
      limitPrice: limitPrice ?? this.limitPrice,
      strike: strike ?? this.strike,
      expirationDate: expirationDate ?? this.expirationDate,
      contractType: clearContractType
          ? null
          : (contractType ?? this.contractType),
      strategy: strategy ?? this.strategy,
      notes: notes ?? this.notes,
      url: url ?? this.url,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
      tickerError: clearErrors ? null : (tickerError ?? this.tickerError),
      quantityError: clearErrors ? null : (quantityError ?? this.quantityError),
      buyPriceError: clearErrors ? null : (buyPriceError ?? this.buyPriceError),
      strikeError: clearErrors ? null : (strikeError ?? this.strikeError),
      expirationDateError: clearErrors
          ? null
          : (expirationDateError ?? this.expirationDateError),
    );
  }
}

class OperationFormParam {
  final String allocationId;
  final String? operationId;

  const OperationFormParam({required this.allocationId, this.operationId});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OperationFormParam &&
          runtimeType == other.runtimeType &&
          allocationId == other.allocationId &&
          operationId == other.operationId;

  @override
  int get hashCode => allocationId.hashCode ^ operationId.hashCode;
}

class OperationFormController extends Notifier<OperationFormState> {
  OperationFormController(this.param);

  final OperationFormParam param;

  @override
  OperationFormState build() {
    // Si estamos editando, cargamos de forma asíncrona los detalles de la operación
    if (param.operationId != null) {
      Future.microtask(() => _loadOperation(param.operationId!));
      return OperationFormState(openedAt: DateTime.now(), isLoading: true);
    }
    return OperationFormState(openedAt: DateTime.now());
  }

  /// Busca la allocation correspondiente en el capital controller.
  Allocation? _getAllocation() {
    final overview = ref.read(capitalControllerProvider).value;
    if (overview == null) return null;
    for (final a in overview.allocations) {
      if (a.id == param.allocationId) return a;
    }
    return null;
  }

  Future<void> _loadOperation(String opId) async {
    try {
      final op = await ref
          .read(operationsRepositoryProvider)
          .getOperationDetails(opId);
      if (!ref.mounted) return;
      state = OperationFormState(
        ticker: op.ticker,
        openedAt: op.openedAt,
        quantity: op.quantity.toString(),
        buyPrice: op.buyPrice.toString(),
        limitPrice: op.limitPrice?.toString() ?? '',
        strike: op.strike?.toString() ?? '',
        expirationDate: op.expirationDate ?? '',
        contractType: op.contractType,
        strategy: op.strategy ?? '',
        notes: op.notes ?? '',
        url: op.url ?? '',
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar la operación: $e',
      );
    }
  }

  void setTicker(String value) {
    state = state.copyWith(ticker: value, tickerError: null);
  }

  void setOpenedAt(DateTime value) {
    state = state.copyWith(openedAt: value);
  }

  void setQuantity(String value) {
    state = state.copyWith(quantity: value, quantityError: null);
  }

  void setBuyPrice(String value) {
    state = state.copyWith(buyPrice: value, buyPriceError: null);
  }

  void setLimitPrice(String value) {
    state = state.copyWith(limitPrice: value);
  }

  void setStrike(String value) {
    state = state.copyWith(strike: value, strikeError: null);
  }

  void setExpirationDate(String value) {
    state = state.copyWith(expirationDate: value, expirationDateError: null);
  }

  void setContractType(String? value) {
    state = state.copyWith(contractType: value);
  }

  void setStrategy(String value) {
    state = state.copyWith(strategy: value);
  }

  void setNotes(String value) {
    state = state.copyWith(notes: value);
  }

  void setUrl(String value) {
    state = state.copyWith(url: value);
  }

  /// Valida los campos localmente según el tipo de cuenta.
  bool _validate(AccountType accountType) {
    bool isValid = true;
    String? tickerErr;
    String? qtyErr;
    String? buyPriceErr;
    String? strikeErr;
    String? expDateErr;

    if (state.ticker.trim().isEmpty) {
      tickerErr = 'El ticker es obligatorio';
      isValid = false;
    }

    final qtyNum = double.tryParse(state.quantity);
    if (qtyNum == null || qtyNum <= 0) {
      qtyErr = 'Cantidad debe ser mayor a 0';
      isValid = false;
    } else if (accountType == AccountType.options) {
      // Opciones: debe ser entero
      final qtyInt = int.tryParse(state.quantity);
      if (qtyInt == null) {
        qtyErr = 'La cantidad en opciones debe ser entera';
        isValid = false;
      }
    }

    final priceNum = double.tryParse(state.buyPrice);
    if (priceNum == null || priceNum <= 0) {
      buyPriceErr = 'Precio de compra debe ser mayor a 0';
      isValid = false;
    }

    if (accountType == AccountType.options) {
      final strikeNum = double.tryParse(state.strike);
      if (strikeNum == null || strikeNum <= 0) {
        strikeErr = 'El strike es obligatorio y mayor a 0';
        isValid = false;
      }

      if (state.expirationDate.trim().isEmpty) {
        expDateErr = 'Fecha de expiración es obligatoria';
        isValid = false;
      } else {
        final dateRegExp = RegExp(r'^\d{4}-\d{2}-\d{2}$');
        if (!dateRegExp.hasMatch(state.expirationDate)) {
          expDateErr = 'Formato inválido (debe ser YYYY-MM-DD)';
          isValid = false;
        }
      }

      if (state.contractType == null) {
        state = state.copyWith(errorMessage: 'Debe seleccionar Call o Put');
        isValid = false;
      }
    }

    state = state.copyWith(
      tickerError: tickerErr,
      quantityError: qtyErr,
      buyPriceError: buyPriceErr,
      strikeError: strikeErr,
      expirationDateError: expDateErr,
    );

    return isValid;
  }

  Future<void> submit() async {
    final allocation = _getAllocation();
    if (allocation == null) {
      state = state.copyWith(errorMessage: 'Cuenta de broker no encontrada');
      return;
    }

    state = state.copyWith(errorMessage: null, clearErrors: true);

    if (!_validate(allocation.accountType)) {
      return;
    }

    state = state.copyWith(isSubmitting: true);

    try {
      final isOptions = allocation.accountType == AccountType.options;
      final isEdit = param.operationId != null;

      final payload = <String, dynamic>{
        // `allocationId` NO va en PATCH: no es un campo del UpdateOperationRequest.
        if (!isEdit) 'allocationId': param.allocationId,
        'ticker': state.ticker.trim().toUpperCase(),
        // Fecha sola (YYYY-MM-DD); mandar datetime completo daba 422.
        'openedAt': operationApiDate(state.openedAt),
        // En options la cantidad es entera; en equity admite decimales.
        'quantity': isOptions
            ? int.parse(state.quantity)
            : double.parse(state.quantity),
        'buyPrice': double.parse(state.buyPrice),
      };

      // Opcionales: en CREATE son `optional` NO-nullable → si están vacíos se
      // OMITEN (mandar `null` da 422). En PATCH son `nullable` → un `null`
      // explícito limpia el campo.
      void putOptional(String key, String raw, {bool asNumber = false}) {
        final value = raw.trim();
        if (value.isNotEmpty) {
          payload[key] = asNumber ? double.parse(value) : value;
        } else if (isEdit) {
          payload[key] = null;
        }
      }

      putOptional('limitPrice', state.limitPrice, asNumber: true);
      putOptional('strategy', state.strategy);
      putOptional('notes', state.notes);
      putOptional('url', state.url);

      // `accountType` NO se envía: la API lo deriva de la cuenta. Los campos de
      // options solo van en cuentas options (ausentes en equity).
      if (isOptions) {
        payload['strike'] = double.parse(state.strike);
        payload['expirationDate'] = state.expirationDate.trim();
        payload['contractType'] = state.contractType;
      }

      if (isEdit) {
        await ref
            .read(operationsRepositoryProvider)
            .patchOperation(param.operationId!, payload);
      } else {
        await ref.read(operationsRepositoryProvider).createOperation(payload);
      }

      if (!ref.mounted) return;

      // Refrescamos la lista de operaciones
      ref.invalidate(operationsControllerProvider(param.allocationId));

      state = state.copyWith(isSubmitting: false, isSuccess: true);
    } catch (e) {
      if (!ref.mounted) return;
      // El contrato pide mostrar `error.message`; ApiException ya lo normaliza.
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: e is ApiException ? e.message : e.toString(),
      );
    }
  }
}

final operationFormControllerProvider = NotifierProvider.autoDispose
    .family<OperationFormController, OperationFormState, OperationFormParam>(
      OperationFormController.new,
    );
