# Propuesta de Cambio: Calculadora de Interés Compuesto Variable y UI de Proyección Interactiva

## 1. Motivación y Contexto
El usuario requiere un método de cálculo financiero reutilizable para proyectar el comportamiento de planes de inversión con interés compuesto diario a lo largo de un período de tiempo (por ejemplo, 3 años).
Además, se debe implementar una interfaz gráfica dinámica y detallada en la pantalla de detalle de cuenta (`AccountDetailScreen`), la cual:
1. En la parte superior, muestre un gráfico lineal dinámico del comportamiento del plan (línea verde) y la posición del balance real actual de la cuenta del broker (punto/línea azul).
2. Debajo, ofrezca dos pestañas: **Registros** (futura implementación, placeholder con diseño coherente) y **Plan** (visualización de la tabla del comportamiento simulado a partir del saldo inicial).
3. Permita alternar dinámicamente entre agrupamientos de tiempo: diario, semanal, mensual y anual.
4. Soporte navegación interactiva (drill-down):
   - Al hacer clic en un mes de la vista anual, se desglosa a la vista diaria de ese mes.
   - Al hacer clic en una semana de la vista mensual, se desglosa a la vista semanal de esa semana.

## 2. Alcance
- **Mapeo matemático**:
  - Tasa diaria nominal: $r_d = \frac{\text{targetMonthlyPct}}{30}$.
  - Simulación diaria del interés compuesto.
- **Visualización Gráfica**:
  - Gráfico interactivo premium personalizado implementado con `CustomPainter` (para mantener la consistencia con el diseño de Glassmorphism, rendimiento web/nativo libre de dependencias pesadas y look and feel moderno).
  - Proyección en color verde; estado actual de la cuenta (broker balance) en azul.
- **Rangos de Período**:
  - **Diario**: Muestra la semana actual (7 días).
  - **Semanal**: Muestra el mes actual (4 semanas).
  - **Mensual**: Muestra el año actual o histórico desde el inicio.
  - **Anual**: Proyecta los 3 años completos.
- **Interacción (Drill-down)**:
  - Taps en el gráfico para zoom de granularidad (Anual -> Diario del mes, Mensual -> Semanal de la semana).

## 3. Arquitectura y Archivos Afectados
Siguiendo Clean/Feature-first Architecture:
- `[NEW]` [compound_interest_calculator.dart](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/lib/features/plans/domain/compound_interest_calculator.dart): Lógica del dominio y cálculo financiero.
- `[NEW]` [compound_interest_calculator_test.dart](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/test/features/plans/domain/compound_interest_calculator_test.dart): Pruebas de lógica matemática.
- `[NEW]` [plan_chart_painter.dart](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/lib/features/plans/presentation/widgets/plan_chart_painter.dart): CustomPainter para el gráfico interactivo.
- `[MODIFY]` [account_detail_screen.dart](file:///Users/hlorenzoz/databank/COD3/Antigravity/projects/apps/investep-app/investep-app/lib/features/account/presentation/account_detail_screen.dart): Rediseño de la pantalla con el gráfico superior, selector de períodos, tabs e interactividad.

## 4. Plan de Mitigación y Riesgos
- **Riesgo**: Jank de renderizado por el dibujo en CustomPainter en dispositivos web.
- **Mitigación**: Minimizar las repintadas innecesarias guardando los puntos procesados en memoria (caching) y limitando el número de elementos dibujados en pantalla.
- **Riesgo**: Datos mock de balance real que confundan al usuario.
- **Mitigación**: Simular el balance actual a partir del saldo inicial sumando un porcentaje realista, dejando cableado el punto de inserción para el balance real del broker.
