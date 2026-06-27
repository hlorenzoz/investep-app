# Especificaciones: Calculadora de Interés Compuesto y Pantalla de Plan Interactiva

Este documento define el comportamiento esperado del calculador de interés compuesto y la interfaz de usuario para la proyección de planes.

## Requerimientos Funcionales

1. **Cálculo del Interés Compuesto**:
   - Tasa diaria: $r_d = \frac{\text{monthlyRate}}{30}$.
   - Composición diaria del balance.
   - Para activos, se simula el comportamiento partiendo del 100% del `baseAmount` (depósito inicial).

2. **Gráfico Superior Interactivo**:
   - MUST ir en la parte superior del detalle de cuenta (`AccountDetailScreen`).
   - MUST representar el comportamiento del plan a lo largo del tiempo de forma dinámica en color **verde**.
   - MUST representar la posición del balance actual real de la cuenta del broker en color **azul** con respecto al plan (un punto/marcador en la posición temporal actual).
   - MUST cambiar dinámicamente según el período seleccionado.

3. **Estructura de Pestañas**:
   - Debajo del gráfico MUST haber 2 pestañas:
     - **Registros**: Placeholder elegante de futura implementación.
     - **Plan**: Muestra la tabla detallada del comportamiento simulado a partir del saldo inicial del plan (columnas: Período, Saldo Inicial, Rendimiento, Saldo Final).

4. **Reglas de Períodos y Rangos**:
   - **Diario**: MUST mostrar la proyección/comportamiento de la **semana actual** (7 días).
   - **Semanal**: MUST mostrar la proyección/comportamiento del **mes actual** (4 semanas).
   - **Mensual**: MUST mostrar el comportamiento del **año actual** o histórico desde el inicio.
   - **Anual**: MUST mostrar la proyección completa de **3 años**.

5. **Interactividad y Drill-down**:
   - Si se selecciona la vista **Anual** y se hace tap en un mes específico, la UI MUST cambiar al agrupamiento **Diario** para ese mes en específico.
   - Si se selecciona la vista **Mensual** y se hace tap en una semana específica, la UI MUST cambiar al agrupamiento **Semanal** para esa semana en específico.
   - La tabla y el gráfico SHALL actualizarse de forma sincronizada con el nuevo período y rango temporal.

---

## Escenarios de Prueba (Specs)

### Escenario 1: Navegación Drill-down Anual -> Diario
- **Given** que el usuario está visualizando el detalle de una cuenta con plan del 25% mensual
- **And** tiene seleccionado el período `Anual`
- **When** el usuario hace tap en la barra/punto correspondiente al mes de `Febrero`
- **Then** el gráfico y la tabla deben transicionar a la granularidad `Diario`
- **And** mostrar únicamente los días correspondientes a ese mes de Febrero.

### Escenario 2: Visualización de Comparación (Verde vs Azul)
- **Given** un plan con depósito inicial de `$900`
- **And** el balance actual del broker real es `$1150`
- **When** se renderiza la pantalla de detalle de cuenta
- **Then** la curva teórica del plan de color verde debe terminar en el saldo proyectado para el periodo actual
- **And** debe aparecer un marcador azul claro con el valor `$1150` en el punto temporal del día de hoy.
