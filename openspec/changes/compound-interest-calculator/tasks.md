# Tareas de Implementación: Calculadora de Interés Compuesto y Pantalla de Plan Interactiva

## Fase 1: Infraestructura y Modelos de Dominio
- [ ] 1.1 Crear el enum `CompoundInterestGrouping` y el modelo `CompoundInterestPeriodResult` en `lib/features/plans/domain/compound_interest_calculator.dart`.
- [ ] 1.2 Declarar y estructurar la firma de `CompoundInterestCalculator` con soporte de rangos y fechas.

## Fase 2: Implementación Matemática y Lógica de Negocio
- [ ] 2.1 Escribir la lógica de simulación diaria del interés compuesto.
- [ ] 2.2 Escribir la lógica de agrupamiento por período dinámico (diario, semanal, mensual, anual).
- [ ] 2.3 Implementar lógica de segmentación temporal (semana actual, mes actual, año actual, drill-down por mes/semana).

## Fase 3: Pruebas Unitarias de Dominio
- [ ] 3.1 Crear el archivo de pruebas `test/features/plans/domain/compound_interest_calculator_test.dart`.
- [ ] 3.2 Implementar pruebas para el Escenario 1 (plan de $900 al 25% mensual por 3 meses agrupado mensualmente) y validar que el balance se componga diariamente.
- [ ] 3.3 Implementar pruebas para los agrupamientos diario, semanal y anual.
- [ ] 3.4 Validar la segmentación de fechas y drill-downs matemáticos.
- [ ] 3.5 Ejecutar las pruebas usando `just test` y asegurar que todas pasen con éxito.

## Fase 4: Interfaz de Usuario y Gráficos (Presentation)
- [ ] 4.1 Crear el componente `PlanChartPainter` (`lib/features/plans/presentation/widgets/plan_chart_painter.dart`) para el gráfico premium con CustomPainter (línea verde para proyección, marcador azul para balance actual, áreas difuminadas de Glassmorphism).
- [ ] 4.2 Crear el controlador de estado `AccountDetailController` en `lib/features/account/presentation/account_detail_controller.dart` para gestionar el agrupamiento, el filtro de drill-down y la pestaña activa.
- [ ] 4.3 Rediseñar `AccountDetailScreen` (`lib/features/account/presentation/account_detail_screen.dart`):
  - Añadir el gráfico superior interactivo con selector de período (Diario, Semanal, Mensual, Anual).
  - Cablear gestos de tap en el gráfico para drill-down.
  - Implementar las pestañas **Registros** (placeholder elegante) y **Plan** (tabla de proyección).
- [ ] 4.4 Añadir botón de "limpiar filtro" o "volver" visible cuando se esté en un estado de drill-down.

## Fase 5: Integración y Verificación de Calidad
- [ ] 5.1 Ejecutar `just test` para validar todas las pruebas del proyecto.
- [ ] 5.2 Ejecutar `just analyze` para verificar la calidad del código y la ausencia de warnings de linter y análisis estático.
