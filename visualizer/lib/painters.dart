import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'models.dart';
import 'typography.dart';

double gridCellSize(double screenWidth, int cols, {double padding = 32}) {
  return (screenWidth - padding) / math.max(cols, 12);
}

class DonutChartPainter extends CustomPainter {
  DonutChartPainter({
    required this.counts,
    required this.colors,
  });

  final Map<String, int> counts;
  final Map<String, Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    const stroke = 28.0;
    var startAngle = -math.pi / 2;

    for (final entry in counts.entries) {
      final sweep = 2 * math.pi * entry.value / total;
      final paint = Paint()
        ..color = colors[entry.key] ?? AppColors.surface2
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }

    final holePaint = Paint()..color = AppColors.surface2;
    canvas.drawCircle(center, radius - stroke / 2 - 2, holePaint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: '$total',
      style: monoText(22, weight: FontWeight.w700),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(covariant DonutChartPainter oldDelegate) =>
      oldDelegate.counts != counts;
}

class AttentionHeatmapPainter extends CustomPainter {
  AttentionHeatmapPainter({
    required this.matrix,
    required this.cellSize,
    required this.labelSize,
    this.selectedRow,
    this.selectedCol,
  });

  final List<List<double>> matrix;
  final double cellSize;
  final double labelSize;
  final int? selectedRow;
  final int? selectedCol;

  @override
  void paint(Canvas canvas, Size size) {
    final n = matrix.length;
    final offset = labelSize;

    double maxVal = 0;
    for (final row in matrix) {
      for (final v in row) {
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal == 0) maxVal = 1;

    for (var r = 0; r < n; r++) {
      for (var c = 0; c < n; c++) {
        final t = matrix[r][c] / maxVal;
        final color = Color.lerp(AppColors.surface2, AppColors.textPrimary, t)!;
        final rect = Rect.fromLTWH(
          offset + c * cellSize,
          offset + r * cellSize,
          cellSize - 1,
          cellSize - 1,
        );
        canvas.drawRect(rect, Paint()..color = color);

        if (selectedRow == r && selectedCol == c) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = AppColors.accent
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant AttentionHeatmapPainter oldDelegate) => true;
}

class TaxonomyGridPainter extends CustomPainter {
  TaxonomyGridPainter({
    required this.taxonomy,
    required this.cellSize,
    this.highlightLayer,
    this.highlightHead,
  });

  final List<TaxonomyEntry> taxonomy;
  final double cellSize;
  final int? highlightLayer;
  final int? highlightHead;

  @override
  void paint(Canvas canvas, Size size) {
    for (final entry in taxonomy) {
      final l = entry.layer - 1;
      final h = entry.head - 1;
      final rect = Rect.fromLTWH(
        h * cellSize,
        l * cellSize,
        cellSize - 1,
        cellSize - 1,
      );
      canvas.drawRect(
        rect,
        Paint()..color = AppColors.headTypeColor(entry.type),
      );

      if (highlightLayer == l && highlightHead == h) {
        canvas.drawRect(
          rect,
          Paint()
            ..color = AppColors.accent
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant TaxonomyGridPainter oldDelegate) => true;
}

class DivergingHeatmapPainter extends CustomPainter {
  DivergingHeatmapPainter({
    required this.matrix,
    required this.cellSize,
    this.highlightLayer,
    this.highlightHead,
    this.showValues = true,
  });

  final List<List<double>> matrix;
  final double cellSize;
  final int? highlightLayer;
  final int? highlightHead;
  final bool showValues;

  static Color _cellColor(double v, double maxAbs) {
    if (maxAbs == 0) return AppColors.heatmapNeutral;
    final t = (v / maxAbs).clamp(-1.0, 1.0);
    if (t.abs() < 0.08) return AppColors.heatmapNeutral;
    if (t > 0) {
      return Color.lerp(AppColors.heatmapNeutral, AppColors.heatmapRed, t)!;
    }
    return Color.lerp(AppColors.heatmapNeutral, AppColors.heatmapBlue, -t)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    double maxAbs = 0;
    for (final row in matrix) {
      for (final v in row) {
        final a = v.abs();
        if (a > maxAbs) maxAbs = a;
      }
    }
    if (maxAbs == 0) maxAbs = 1;

    final tp = TextPainter(textDirection: TextDirection.ltr);
    final fontSize = math.max(6.0, cellSize * 0.22);
    final showText = showValues && cellSize >= 22;

    for (var l = 0; l < matrix.length; l++) {
      for (var h = 0; h < matrix[l].length; h++) {
        final v = matrix[l][h];
        final color = _cellColor(v, maxAbs);
        final rect = Rect.fromLTWH(
          h * cellSize,
          l * cellSize,
          cellSize - 1,
          cellSize - 1,
        );
        canvas.drawRect(rect, Paint()..color = color);

        if (showText) {
          final textColor =
              color.computeLuminance() > 0.35
                  ? AppColors.background
                  : AppColors.textPrimary;
          tp.text = TextSpan(
            text: v.toStringAsFixed(3),
            style: monoText(fontSize, color: textColor, weight: FontWeight.w500),
          );
          tp.layout(maxWidth: cellSize);
          if (tp.width <= cellSize - 2) {
            tp.paint(
              canvas,
              Offset(
                h * cellSize + (cellSize - tp.width) / 2,
                l * cellSize + (cellSize - tp.height) / 2,
              ),
            );
          }
        }

        if (highlightLayer == l && highlightHead == h) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = AppColors.textPrimary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant DivergingHeatmapPainter oldDelegate) => true;
}

class ProbingGridPainter extends CustomPainter {
  ProbingGridPainter({
    required this.grid,
    required this.cellSize,
    required this.bestLayer,
    required this.bestHead,
  });

  final List<List<double>> grid;
  final double cellSize;
  final int bestLayer;
  final int bestHead;

  @override
  void paint(Canvas canvas, Size size) {
    double maxVal = 0;
    for (final row in grid) {
      for (final v in row) {
        if (v > maxVal) maxVal = v;
      }
    }
    if (maxVal == 0) maxVal = 1;

    for (var l = 0; l < grid.length; l++) {
      for (var h = 0; h < grid[l].length; h++) {
        final v = grid[l][h];
        final t = v / maxVal;
        final color = Color.lerp(AppColors.surface2, AppColors.textPrimary, t)!;
        final rect = Rect.fromLTWH(
          h * cellSize,
          l * cellSize,
          cellSize - 1,
          cellSize - 1,
        );
        canvas.drawRect(rect, Paint()..color = color);

        if (v > 0) {
          final textColor =
              color.computeLuminance() > 0.45
                  ? AppColors.background
                  : AppColors.textPrimary;
          final tp = TextPainter(textDirection: TextDirection.ltr);
          tp.text = TextSpan(
            text: v.toStringAsFixed(2),
            style: monoText(
              math.max(7, cellSize * 0.28),
              color: textColor,
              weight: FontWeight.w600,
            ),
          );
          tp.layout(maxWidth: cellSize);
          tp.paint(
            canvas,
            Offset(
              h * cellSize + (cellSize - tp.width) / 2,
              l * cellSize + (cellSize - tp.height) / 2,
            ),
          );
        }

        if (l == bestLayer - 1 && h == bestHead - 1) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = color.computeLuminance() > 0.45
                  ? AppColors.background
                  : AppColors.textPrimary
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant ProbingGridPainter oldDelegate) => true;
}

class HorizontalBarChartPainter extends CustomPainter {
  HorizontalBarChartPainter({
    required this.values,
    required this.barHeight,
    required this.gap,
    required this.labelWidth,
  });

  final List<double> values;
  final double barHeight;
  final double gap;
  final double labelWidth;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final maxVal = values.reduce(math.max);
    if (maxVal == 0) return;

    final chartWidth = size.width - labelWidth - 8;
    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final y = i * (barHeight + gap);
      final barW = (v / maxVal) * chartWidth;

      Color barColor;
      if (v >= 0.01) {
        barColor = AppColors.heatmapRed;
      } else if (v >= 0.005) {
        barColor = AppColors.accent3;
      } else {
        barColor = AppColors.accent2;
      }

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(labelWidth, y, barW, barHeight),
          const Radius.circular(3),
        ),
        Paint()..color = barColor,
      );

      tp.text = TextSpan(
        text: 'L${i + 1}',
        style: monoText(10, color: AppColors.textSecondary),
      );
      tp.layout();
      tp.paint(canvas, Offset(labelWidth - tp.width - 4, y + (barHeight - tp.height) / 2));

      tp.text = TextSpan(
        text: v.toStringAsFixed(4),
        style: monoText(9, color: AppColors.textPrimary),
      );
      tp.layout();
      tp.paint(canvas, Offset(labelWidth + barW + 4, y + (barHeight - tp.height) / 2));
    }
  }

  @override
  bool shouldRepaint(covariant HorizontalBarChartPainter oldDelegate) => true;
}

class LineChartPainter extends CustomPainter {
  LineChartPainter({
    required this.values,
    required this.lineColor,
    required this.baseline,
  });

  final List<double> values;
  final Color lineColor;
  final double baseline;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    const padLeft = 28.0;
    const padRight = 8.0;
    const padTop = 12.0;
    const padBottom = 24.0;

    final chartW = size.width - padLeft - padRight;
    final chartH = size.height - padTop - padBottom;

    final maxVal = math.max(values.reduce(math.max), baseline * 1.1);
    final minVal = 0.0;
    final range = maxVal - minVal;
    if (range == 0) return;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;

    for (var i = 0; i <= 4; i++) {
      final y = padTop + chartH * i / 4;
      canvas.drawLine(Offset(padLeft, y), Offset(size.width - padRight, y), gridPaint);
    }

    final baselineY = padTop + chartH * (1 - (baseline - minVal) / range);
    canvas.drawLine(
      Offset(padLeft, baselineY),
      Offset(size.width - padRight, baselineY),
      Paint()
        ..color = AppColors.textSecondary.withValues(alpha: 0.5)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke,
    );

    final path = Path();
    for (var i = 0; i < values.length; i++) {
      final x = padLeft + chartW * i / (values.length - 1);
      final y = padTop + chartH * (1 - (values[i] - minVal) / range);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < values.length; i++) {
      final x = padLeft + chartW * i / (values.length - 1);
      final y = padTop + chartH * (1 - (values[i] - minVal) / range);
      canvas.drawCircle(Offset(x, y), 3, Paint()..color = lineColor);

      final tp = TextPainter(textDirection: TextDirection.ltr);
      tp.text = TextSpan(
        text: '${i + 1}',
        style: monoText(9, color: AppColors.textSecondary),
      );
      tp.layout();
      tp.paint(canvas, Offset(x - tp.width / 2, size.height - padBottom + 4));
    }

    final tp = TextPainter(textDirection: TextDirection.ltr);
    tp.text = TextSpan(
      text: baseline.toStringAsFixed(2),
      style: monoText(9, color: AppColors.textSecondary),
    );
    tp.layout();
    tp.paint(canvas, Offset(2, baselineY - tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant LineChartPainter oldDelegate) => true;
}
