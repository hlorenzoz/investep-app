# Diseño Técnico: Calculadora de Interés Compuesto y Pantalla de Plan Interactiva

Este documento detalla la arquitectura de software y el diseño de interfaz de usuario para el cálculo e interactividad de planes de inversión en `AccountDetailScreen`.

## Diseño de Clases y Enums

### 1. `CompoundInterestGrouping` (Enum)
Define los tipos de agrupamiento permitidos.
```dart
enum CompoundInterestGrouping {
  daily,
  weekly,
  monthly,
  yearly;

  /// Retorna la etiqueta para el selector o periodo.
  String get displayName {
    switch (this) {
      case CompoundInterestGrouping.daily:
        return 'Diario';
      case CompoundInterestGrouping.weekly:
        return 'Semanal';
      case CompoundInterestGrouping.monthly:
        return 'Mensual';
      case CompoundInterestGrouping.yearly:
        return 'Anual';
    }
  }
}
```

### 2. Clase de Datos `CompoundInterestPeriodResult`
Contiene la proyección de un período agrupado específico.
```dart
class CompoundInterestPeriodResult {
  final int periodIndex;
  final String label;
  final double startBalance;
  final double yieldAmount;
  final double endBalance;
  final DateTime date; // Fecha del periodo para navegación/drill-down

  const CompoundInterestPeriodResult({
    required this.periodIndex,
    required this.label,
    required this.startBalance,
    required this.yieldAmount,
    required this.endBalance,
    required this.date,
  });
}
```

---

## Interfaz de Usuario y Drill-down

### 1. Gestión de Estado: `AccountDetailState`
Para soportar la navegación interactiva y la interactividad del gráfico/tabla, crearemos un controlador para `AccountDetailScreen` que gestione:
- Pestaña activa (Registros / Plan).
- Período de agrupamiento seleccionado (`CompoundInterestGrouping`).
- Filtro temporal o contexto del drill-down (ej. si está filtrado a un mes específico en la vista diaria, se guarda el `DateTime` de referencia del mes seleccionado).

```dart
class AccountDetailState {
  final CompoundInterestGrouping grouping;
  final DateTime? drillDownDate; // Null si es vista global
  final int activeTab; // 0 para Registros, 1 para Plan

  const AccountDetailState({
    required this.grouping,
    this.drillDownDate,
    required this.activeTab,
  });

  AccountDetailState copyWith({
    CompoundInterestGrouping? grouping,
    DateTime? drillDownDate,
    int? activeTab,
    bool clearDrillDown = false,
  }) {
    return AccountDetailState(
      grouping: grouping ?? this.grouping,
      drillDownDate: clearDrillDown ? null : (drillDownDate ?? this.drillDownDate),
      activeTab: activeTab ?? this.activeTab,
    );
  }
}
```

### 2. Componente de Gráfico Premium: `PlanChartPainter`
Usaremos un `CustomPainter` dentro de un `GestureDetector` para pintar y detectar pulsaciones en los puntos del gráfico:
- **Eje X**: Eje temporal (fechas formateadas).
- **Eje Y**: Balance (con gradiente bajo la línea).
- **Línea Verde**: La curva teórica del interés compuesto acumulativo.
- **Punto/Línea Azul**: Balance actual en el broker con respecto al plan. El balance se ubicará en la fecha actual (hoy) en el eje X y con el saldo actual en el eje Y.
- **Interacción**:
  - Un `LayoutBuilder` proporcionará el tamaño del widget.
  - Al hacer un tap en el gráfico, calculamos qué punto del eje X está más cerca del `tapPosition.dx` para identificar la sección pulsada y disparar el drill-down si corresponde.

---

## Lógica de Rangos y Granularidad de Datos

1. **Diario**: Muestra los datos día a día de la semana actual (7 días de proyección).
2. **Semanal**: Muestra los datos de las semanas del mes actual (4 semanas / 28 o 30 días de proyección).
3. **Mensual**: Muestra los datos mes a mes del año actual (12 meses) o el histórico acumulativo.
4. **Anual**: Muestra el comportamiento anual (3 años, 36 meses agrupados en 3 bloques de 12 meses).

Drill-down:
- En vista **Anual**: al hacer tap en un mes, cambiamos a `grouping: daily` y `drillDownDate: mesSeleccionado`. El calculador entonces generará las proyecciones diarias solo para los días de ese mes.
- En vista **Mensual**: al hacer tap en una semana, cambiamos a `grouping: weekly` o `daily` para los días de esa semana.
- Un botón "Volver" o indicador de filtro permitirá limpiar el drill-down para regresar a la vista global.
