import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';
import '../../domain/compound_interest_calculator.dart';

class PlanChart extends StatefulWidget {
  final List<CompoundInterestPeriodResult> data;
  final double currentBrokerAmount;
  final String currency;
  final void Function(int index)? onTapPoint;

  const PlanChart({
    super.key,
    required this.data,
    required this.currentBrokerAmount,
    required this.currency,
    this.onTapPoint,
  });

  @override
  State<PlanChart> createState() => _PlanChartState();
}

class _PlanChartState extends State<PlanChart> {
  int? _selectedIndex;

  void _updateSelectedIndex(Offset localPos, double width, double paddingX) {
    if (widget.data.length < 2) return;
    final double chartWidth = width - (paddingX * 2);
    final double relativeX = localPos.dx - paddingX;
    final double step = chartWidth / (widget.data.length - 1);
    final int index = (relativeX / step).round().clamp(0, widget.data.length - 1);
    if (_selectedIndex != index) {
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
          child: Text(
            'Sin datos de proyección',
            style: TextStyle(color: Colors.white60),
          ),
        ),
      );
    }

    final glassTheme = context.glass;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        const double height = 220.0;
        const double paddingX = 40.0;
        const double paddingY = 20.0;

        return MouseRegion(
          onHover: (event) => _updateSelectedIndex(event.localPosition, width, paddingX),
          onExit: (_) {
            if (_selectedIndex != null) {
              setState(() => _selectedIndex = null);
            }
          },
          child: GestureDetector(
            onTapDown: (details) {
              _updateSelectedIndex(details.localPosition, width, paddingX);
              if (_selectedIndex != null && widget.onTapPoint != null) {
                widget.onTapPoint!(_selectedIndex!);
              }
            },
            onPanUpdate: (details) => _updateSelectedIndex(details.localPosition, width, paddingX),
            onPanEnd: (_) {},
            child: CustomPaint(
              size: Size(width, height),
              painter: _PlanChartPainter(
                data: widget.data,
                currentBrokerAmount: widget.currentBrokerAmount,
                currency: widget.currency,
                paddingX: paddingX,
                paddingY: paddingY,
                glassTheme: glassTheme,
                selectedIndex: _selectedIndex,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PlanChartPainter extends CustomPainter {
  final List<CompoundInterestPeriodResult> data;
  final double currentBrokerAmount;
  final String currency;
  final double paddingX;
  final double paddingY;
  final GlassThemeExtension glassTheme;
  final int? selectedIndex;

  _PlanChartPainter({
    required this.data,
    required this.currentBrokerAmount,
    required this.currency,
    required this.paddingX,
    required this.paddingY,
    required this.glassTheme,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double chartWidth = width - (paddingX * 2);
    final double chartHeight = height - (paddingY * 2);

    // 1. Obtener valores mínimos y máximos para escalar el eje Y
    double minY = data.map((e) => e.startBalance).reduce(min);
    double maxY = data.map((e) => e.endBalance).reduce(max);

    // Incluimos el monto del broker en la escala para que no quede fuera de pantalla
    minY = min(minY, currentBrokerAmount) * 0.95;
    maxY = max(maxY, currentBrokerAmount) * 1.05;

    final double rangeY = maxY - minY == 0 ? 1.0 : maxY - minY;

    // 2. Generar coordenadas de puntos para la curva teórica (verde)
    final double stepX = chartWidth / (data.length - 1);
    final points = <Offset>[];

    for (int i = 0; i < data.length; i++) {
      final d = data[i];
      final double x = paddingX + (i * stepX);
      final double y = height - paddingY - ((d.endBalance - minY) / rangeY * chartHeight);
      points.add(Offset(x, y));
    }

    // 3. Dibujar la cuadrícula horizontal (líneas guía de balance)
    final gridPaint = Paint()
      ..color = glassTheme.textPrimary.withValues(alpha: 0.08)
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    const int gridLines = 3;
    for (int i = 0; i <= gridLines; i++) {
      final double fraction = i / gridLines;
      final double y = height - paddingY - (fraction * chartHeight);
      canvas.drawLine(Offset(paddingX, y), Offset(width - paddingX, y), gridPaint);

      // Etiquetas del eje Y
      final double val = minY + (fraction * (maxY - minY));
      textPainter.text = TextSpan(
        text: '\$${val.toStringAsFixed(0)}',
        style: TextStyle(
          color: glassTheme.textSecondary.withValues(alpha: 0.85),
          fontSize: 9,
          fontWeight: FontWeight.w500,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(8, y - 6));
    }

    // 4. Pintar área con gradiente debajo de la curva verde
    if (points.isNotEmpty) {
      final gradientPath = Path()
        ..moveTo(points.first.dx, height - paddingY);
      for (final p in points) {
        gradientPath.lineTo(p.dx, p.dy);
      }
      gradientPath.lineTo(points.last.dx, height - paddingY);
      gradientPath.close();

      final areaGradient = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          glassTheme.positive.withValues(alpha: 0.25),
          glassTheme.positive.withValues(alpha: 0.00),
        ],
      );

      final paintArea = Paint()
        ..shader = areaGradient.createShader(
          Rect.fromLTRB(paddingX, paddingY, width - paddingX, height - paddingY),
        )
        ..style = PaintingStyle.fill;

      canvas.drawPath(gradientPath, paintArea);
    }

    // 5. Pintar la línea de la proyección (curva verde)
    final linePaint = Paint()
      ..color = glassTheme.positive
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final linePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(linePath, linePaint);

    // 6. Encontrar la coordenada X para "Hoy" y dibujar el marcador de Balance del Broker (azul)
    final DateTime now = DateTime.now();
    int closestIndex = 0;
    int minDiffMs = double.maxFinite.toInt();

    for (int i = 0; i < data.length; i++) {
      final diff = (data[i].date.millisecondsSinceEpoch - now.millisecondsSinceEpoch).abs();
      if (diff < minDiffMs) {
        minDiffMs = diff;
        closestIndex = i;
      }
    }

    final double brokerX = points[closestIndex].dx;
    final double brokerY = height - paddingY - ((currentBrokerAmount - minY) / rangeY * chartHeight);
    final Offset brokerOffset = Offset(brokerX, brokerY);

    // Línea vertical discontinua hacia el marcador azul
    final dashPaint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    double startY = height - paddingY;
    const double dashHeight = 4.0;
    const double dashSpace = 4.0;
    while (startY > brokerY) {
      canvas.drawLine(
        Offset(brokerX, startY),
        Offset(brokerX, max(brokerY, startY - dashHeight)),
        dashPaint,
      );
      startY -= (dashHeight + dashSpace);
    }

    // Brillo del punto azul
    final blueGlowPaint = Paint()
      ..color = Colors.blueAccent.withValues(alpha: 0.35)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(brokerOffset, 12, blueGlowPaint);

    // Punto azul interno
    final bluePointPaint = Paint()
      ..color = Colors.blueAccent.shade200
      ..style = PaintingStyle.fill;
    canvas.drawCircle(brokerOffset, 5, bluePointPaint);

    // Etiqueta del balance del broker
    textPainter.text = TextSpan(
      text: 'Broker: \$${currentBrokerAmount.toStringAsFixed(2)}',
      style: TextStyle(
        color: glassTheme.textPrimary,
        fontSize: 10,
        fontWeight: FontWeight.bold,
      ),
    );
    textPainter.layout();

    // Dibujar fondo de etiqueta con Glass Fill y Border
    final double textWidth = textPainter.width;
    final double textHeight = textPainter.height;
    final double labelX = (brokerX + textWidth + 10 > width - 10) ? brokerX - textWidth - 10 : brokerX + 10;
    final double labelY = brokerY - (textHeight / 2);

    final labelRect = Rect.fromLTWH(labelX - 4, labelY - 2, textWidth + 8, textHeight + 4);
    final rRect = RRect.fromRectAndRadius(labelRect, const Radius.circular(4));
    
    final labelBgPaint = Paint()..color = glassTheme.glassFill;
    final labelBorderPaint = Paint()
      ..color = glassTheme.glassBorder
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
      
    canvas.drawRRect(rRect, labelBgPaint);
    canvas.drawRRect(rRect, labelBorderPaint);

    textPainter.paint(canvas, Offset(labelX, labelY));

    // 7. Dibujar etiquetas de tiempo en el eje X
    if (data.length >= 2) {
      final int stepLabel = (data.length / 4).round().clamp(1, data.length);
      for (int i = 0; i < data.length; i += stepLabel) {
        final d = data[i];
        textPainter.text = TextSpan(
          text: d.label,
          style: TextStyle(
            color: glassTheme.textSecondary.withValues(alpha: 0.85),
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        );
        textPainter.layout();
        final double labelXPos = points[i].dx - (textPainter.width / 2);
        textPainter.paint(canvas, Offset(labelXPos, height - paddingY + 6));
      }
    }

    // 8. Dibujar indicador y tooltip para el punto seleccionado (hover / touch)
    if (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < points.length) {
      final idx = selectedIndex!;
      final selectedPoint = points[idx];
      final item = data[idx];

      // Línea vertical tenue indicadora
      final guideLinePaint = Paint()
        ..color = glassTheme.textPrimary.withValues(alpha: 0.15)
        ..strokeWidth = 1.0;
      canvas.drawLine(
        Offset(selectedPoint.dx, paddingY),
        Offset(selectedPoint.dx, height - paddingY),
        guideLinePaint,
      );

      // Círculo concéntrico en el punto verde
      final outerDotPaint = Paint()
        ..color = glassTheme.positive.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 8, outerDotPaint);

      final innerDotPaint = Paint()
        ..color = glassTheme.positive
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 4, innerDotPaint);

      final whiteDotPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(selectedPoint, 2, whiteDotPaint);

      // Textos del Tooltip
      final dateSpan = TextSpan(
        text: item.label,
        style: TextStyle(
          color: glassTheme.textSecondary,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      );
      final totalSpan = TextSpan(
        text: 'Total: \$${item.endBalance.toStringAsFixed(2)}',
        style: TextStyle(
          color: glassTheme.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      );
      final yieldSign = item.yieldAmount >= 0 ? '+' : '';
      final yieldSpan = TextSpan(
        text: 'Plan: $yieldSign\$${item.yieldAmount.toStringAsFixed(2)}',
        style: TextStyle(
          color: glassTheme.positive,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      );

      final tpDate = TextPainter(text: dateSpan, textDirection: TextDirection.ltr)..layout();
      final tpTotal = TextPainter(text: totalSpan, textDirection: TextDirection.ltr)..layout();
      final tpYield = TextPainter(text: yieldSpan, textDirection: TextDirection.ltr)..layout();

      final double tooltipWidth = max(tpDate.width, max(tpTotal.width, tpYield.width)) + 16;
      final double tooltipHeight = tpDate.height + tpTotal.height + tpYield.height + 12;

      // Posicionamiento inteligente del tooltip (encima o debajo, sin salirse de bordes)
      double ttX = selectedPoint.dx - (tooltipWidth / 2);
      ttX = ttX.clamp(10.0, width - tooltipWidth - 10.0);

      double ttY = selectedPoint.dy - tooltipHeight - 10;
      if (ttY < 10) {
        ttY = selectedPoint.dy + 10;
      }

      final ttRect = Rect.fromLTWH(ttX, ttY, tooltipWidth, tooltipHeight);
      final ttRRect = RRect.fromRectAndRadius(ttRect, const Radius.circular(8));

      final bool isDarkTheme = glassTheme.textPrimary.computeLuminance() > 0.5;
      final Color ttBgColor = isDarkTheme ? const Color(0xEE1E293B) : const Color(0xF0F8FAFC);

      final ttBgPaint = Paint()
        ..color = ttBgColor
        ..style = PaintingStyle.fill;

      final ttBorderPaint = Paint()
        ..color = glassTheme.glassBorder
        ..strokeWidth = 1.0
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(ttRRect, ttBgPaint);
      canvas.drawRRect(ttRRect, ttBorderPaint);

      double currY = ttY + 6;
      tpDate.paint(canvas, Offset(ttX + 8, currY));
      currY += tpDate.height + 2;
      tpTotal.paint(canvas, Offset(ttX + 8, currY));
      currY += tpTotal.height + 2;
      tpYield.paint(canvas, Offset(ttX + 8, currY));
    }
  }

  @override
  bool shouldRepaint(covariant _PlanChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.currentBrokerAmount != currentBrokerAmount ||
        oldDelegate.currency != currency ||
        oldDelegate.selectedIndex != selectedIndex;
  }
}
