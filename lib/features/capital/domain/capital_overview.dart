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
    final capital = cap == null
        ? null
        : Capital.fromJson(cap as Map<String, dynamic>);
    final allocations = (json['allocations'] as List<dynamic>)
        .map((e) => Allocation.fromJson(e as Map<String, dynamic>))
        .toList();
    final totalAllocated = json['totalAllocated'] as num;

    // Deriva 'available' o usa fallback a 0 si no viene de la API
    final totalCap = capital?.totalCapital ?? 0;
    final availableVal =
        (json['available'] as num?) ?? (totalCap - totalAllocated);
    final available = availableVal < 0 ? 0 : availableVal;

    return CapitalOverview(
      capital: capital,
      allocations: allocations,
      totalAllocated: totalAllocated,
      available: available,
    );
  }
}
