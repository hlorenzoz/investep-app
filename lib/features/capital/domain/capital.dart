/// Capital total declarado por el usuario, en una moneda.
class Capital {
  final num totalCapital;
  final String currency;

  const Capital({required this.totalCapital, required this.currency});

  /// Parsea el objeto `capital` del contrato: `{ totalCapital, currency }`.
  factory Capital.fromJson(Map<String, dynamic> json) => Capital(
    totalCapital: json['totalCapital'] as num,
    currency: json['currency'] as String,
  );
}
