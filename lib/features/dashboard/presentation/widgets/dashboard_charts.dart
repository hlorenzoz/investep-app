import 'dart:math';
import 'package:flutter/material.dart';
import '../../../../app/theme/app_theme.dart';

/// Segmento de datos para el gráfico de dona.
class ChartSegment {
  final String label;
  final double value;
  final Color color;

  const ChartSegment({
    required this.label,
    required this.value,
    required this.color,
  });
}

/// Gráfico de dona (Doughnut Chart) interactivo y animado.
class DoughnutChart extends StatefulWidget {
  final List<ChartSegment> segments;
  final String centerTitle;
  final String centerSubtitle;
  final double height;

  const DoughnutChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    required this.centerSubtitle,
    this.height = 200,
  });

  @override
  State<DoughnutChart> createState() => _DoughnutChartState();
}

class _DoughnutChartState extends State<DoughnutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant DoughnutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si los segmentos cambian, reiniciamos la animación de forma elegante
    if (oldWidget.segments.length != widget.segments.length) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapOrHover(Offset localPosition, Size size) {
    if (widget.segments.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final relativeOffset = localPosition - center;
    final distance = relativeOffset.distance;

    final outerRadius = min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.65;

    // Verificar si el toque/hover cae dentro del anillo de la dona
    if (distance >= innerRadius && distance <= outerRadius) {
      // Calcular el ángulo en radianes (-pi a pi, luego mapeado a 0 a 2*pi)
      double angle = atan2(relativeOffset.dy, relativeOffset.dx);
      if (angle < 0) {
        angle += 2 * pi;
      }

      final total = widget.segments.fold<double>(
        0,
        (sum, item) => sum + item.value,
      );
      if (total == 0) return;

      double startAngle = -pi / 2; // Empezamos a dibujar en las 12 en punto
      int foundIndex = -1;

      if (widget.segments.length == 1) {
        foundIndex = 0;
      } else {
        for (int i = 0; i < widget.segments.length; i++) {
          final sweepAngle = (widget.segments[i].value / total) * 2 * pi;
          final endAngle = startAngle + sweepAngle;

          // Normalizar ángulos para la comparación en el rango [0, 2*pi)
          double normalizedStart = startAngle % (2 * pi);
          if (normalizedStart < 0) normalizedStart += 2 * pi;

          double normalizedEnd = endAngle % (2 * pi);
          if (normalizedEnd < 0) normalizedEnd += 2 * pi;

          bool isWithin = false;
          if (normalizedStart < normalizedEnd) {
            isWithin = angle >= normalizedStart && angle <= normalizedEnd;
          } else {
            // El segmento cruza la línea de 0 radianes (las 3 en punto)
            isWithin = angle >= normalizedStart || angle <= normalizedEnd;
          }

          if (isWithin) {
            foundIndex = i;
            break;
          }
          startAngle = endAngle;
        }
      }

      if (_hoveredIndex != foundIndex) {
        setState(() {
          _hoveredIndex = foundIndex;
        });
      }
    } else {
      if (_hoveredIndex != -1) {
        setState(() {
          _hoveredIndex = -1;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;

    if (widget.segments.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'Sin datos de distribución',
            style: TextStyle(color: glassTheme.textSecondary),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final Size chartSize = Size(width, widget.height);

        return MouseRegion(
          onHover: (event) => _handleTapOrHover(event.localPosition, chartSize),
          onExit: (_) => setState(() => _hoveredIndex = -1),
          child: GestureDetector(
            onTapDown: (details) =>
                _handleTapOrHover(details.localPosition, chartSize),
            child: AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                return CustomPaint(
                  size: chartSize,
                  painter: _DoughnutChartPainter(
                    segments: widget.segments,
                    animationValue: _animation.value,
                    hoveredIndex: _hoveredIndex,
                    centerTitle: widget.centerTitle,
                    centerSubtitle: widget.centerSubtitle,
                    glassTheme: glassTheme,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _DoughnutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double animationValue;
  final int hoveredIndex;
  final String centerTitle;
  final String centerSubtitle;
  final GlassThemeExtension glassTheme;

  _DoughnutChartPainter({
    required this.segments,
    required this.animationValue,
    required this.hoveredIndex,
    required this.centerTitle,
    required this.centerSubtitle,
    required this.glassTheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = min(size.width, size.height) / 2;
    final innerRadius = outerRadius * 0.65;
    final strokeWidth = outerRadius - innerRadius;

    final total = segments.fold<double>(0, (sum, item) => sum + item.value);
    if (total == 0) return;

    double startAngle = -pi / 2; // Empezamos a dibujar en las 12 en punto

    for (int i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final sweepAngle = (segment.value / total) * 2 * pi * animationValue;

      if (sweepAngle <= 0) continue;

      final isHovered = i == hoveredIndex;
      final paintRadius = isHovered ? outerRadius + 4 : outerRadius;
      final paintStrokeWidth = isHovered ? strokeWidth + 2 : strokeWidth;

      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = paintStrokeWidth
        ..strokeCap = StrokeCap
            .butt; // Sin redondeo en bordes interiores para que encajen perfectos

      final rect = Rect.fromCircle(
        center: center,
        radius: paintRadius - (paintStrokeWidth / 2),
      );

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      // Dibujar un borde separador sutil entre los arcos
      if (segments.length > 1) {
        final separatorPaint = Paint()
          ..color = glassTheme.glassBorder.withOpacity(0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawArc(rect, startAngle, 0.02, false, separatorPaint);
      }

      startAngle += (segment.value / total) * 2 * pi;
    }

    // Dibujar el fondo del círculo central para dar el efecto glassmorphism a la dona
    final innerPaint = Paint()
      ..color = glassTheme.glassFill
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, innerRadius, innerPaint);

    final borderPaint = Paint()
      ..color = glassTheme.glassBorder
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, innerRadius, borderPaint);

    // Dibujar textos en el centro
    final titlePainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Si hay un elemento hovered, mostramos su detalle, sino el total
    String mainText = centerTitle;
    String subText = centerSubtitle;

    if (hoveredIndex != -1 && hoveredIndex < segments.length) {
      final seg = segments[hoveredIndex];
      final percentage = (seg.value / total * 100).toStringAsFixed(1);
      mainText = percentage == '100.0' ? '100%' : '$percentage%';
      subText = seg.label;
    }

    titlePainter.text = TextSpan(
      text: mainText,
      style: TextStyle(
        color: glassTheme.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
    titlePainter.layout(maxWidth: innerRadius * 1.8);

    final subPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    subPainter.text = TextSpan(
      text: subText.toUpperCase(),
      style: TextStyle(
        color: glassTheme.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
    subPainter.layout(maxWidth: innerRadius * 1.8);

    // Centrado vertical dinámico del bloque (Título + Subtítulo) para evitar solapamientos
    const double spacing = 8.0;
    final double totalHeight =
        titlePainter.height + subPainter.height + spacing;
    final double yStart = center.dy - totalHeight / 2;

    titlePainter.paint(
      canvas,
      Offset(center.dx - titlePainter.width / 2, yStart),
    );

    subPainter.paint(
      canvas,
      Offset(
        center.dx - subPainter.width / 2,
        yStart + titlePainter.height + spacing,
      ),
    );
  }

  @override
  bool shouldRepaint(covariant _DoughnutChartPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
        oldDelegate.hoveredIndex != hoveredIndex ||
        oldDelegate.centerTitle != centerTitle ||
        oldDelegate.centerSubtitle != centerSubtitle ||
        oldDelegate.segments.length != segments.length;
  }
}

/// Barra de progreso de distribución horizontal segmentada (estilo premium).
class DistributionProgressBar extends StatelessWidget {
  final List<ChartSegment> segments;
  final double height;

  const DistributionProgressBar({
    super.key,
    required this.segments,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final glassTheme = context.glass;
    final total = segments.fold<double>(0, (sum, item) => sum + item.value);

    if (total == 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          color: glassTheme.textSecondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(height / 2),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(height / 2),
          child: Container(
            height: height,
            color: glassTheme.textSecondary.withValues(alpha: 0.08),
            child: Row(
              children: segments.map((segment) {
                final double widthFactor = segment.value / total;
                if (widthFactor == 0) return const SizedBox.shrink();
                return Expanded(
                  flex: max(1, (widthFactor * 1000).round()),
                  child: Container(height: height, color: segment.color),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 10),
        // Leyendas de la barra
        Wrap(
          spacing: 16,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: segments.map((segment) {
            final pct = (segment.value / total * 100).toStringAsFixed(1);
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: segment.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${segment.label} ($pct%)',
                  style: TextStyle(
                    color: glassTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
