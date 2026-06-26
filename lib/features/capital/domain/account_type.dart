/// Tipo de cuenta de una allocation. El backend lo DERIVA del plan elegido; el
/// cliente nunca lo envía en el body de `POST /capital/allocations`.
enum AccountType {
  equity,
  options;

  /// Mapea el valor del contrato (`"equity"` / `"options"`) al enum.
  static AccountType fromApi(String value) => switch (value) {
    'equity' => AccountType.equity,
    'options' => AccountType.options,
    _ => throw ArgumentError('AccountType desconocido: $value'),
  };

  /// Valor para query params (`GET /plans?accountType=...`).
  String toApi() => name;
}
