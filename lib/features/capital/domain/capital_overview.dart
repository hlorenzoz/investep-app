import 'allocation.dart';
import 'capital.dart';

/// Respuesta completa de `GET /capital`: capital (o null si no se configuró),
/// allocations, total asignado y disponible.
class CapitalOverview {
  final Capital? capital;
  final List<Allocation> allocations;
  final num totalAllocated;
  final num available;

  const CapitalOverview({
    required this.capital,
    required this.allocations,
    required this.totalAllocated,
    required this.available,
  });

  bool get hasCapital => capital != null;
  bool get hasAllocations => allocations.isNotEmpty;

  factory CapitalOverview.fromJson(Map<String, dynamic> json) {
    final cap = json['capital'];
    return CapitalOverview(
      capital: cap == null
          ? null
          : Capital.fromJson(cap as Map<String, dynamic>),
      allocations: (json['allocations'] as List<dynamic>)
          .map((e) => Allocation.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalAllocated: json['totalAllocated'] as num,
      available: json['available'] as num,
    );
  }
}
