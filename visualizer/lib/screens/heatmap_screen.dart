import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models.dart';
import '../painters.dart';
import '../typography.dart';
import '../widgets.dart';

class HeatmapScreen extends StatefulWidget {
  const HeatmapScreen({super.key, required this.data});

  final AnalysisData data;

  @override
  State<HeatmapScreen> createState() => _HeatmapScreenState();
}

class _HeatmapScreenState extends State<HeatmapScreen> {
  int _layer = 0;
  int _head = 0;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final entry = data.taxonomyAt(_layer, _head);
    final matrix = data.attention[_layer][_head];
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = gridCellSize(screenWidth, matrix.length);
    const labelSize = 52.0;
    final gridSize = labelSize + matrix.length * cellSize;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Attention Heatmap',
              subtitle: 'Layer × head attention weights (seq × seq)',
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(12, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('L${i + 1}', style: monoText(11)),
                      selected: _layer == i,
                      selectedColor: AppColors.accent.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surface2,
                      side: BorderSide(
                        color: _layer == i ? AppColors.accent : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: _layer == i
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      onSelected: (_) => setState(() => _layer = i),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: List.generate(12, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text('H${i + 1}', style: monoText(11)),
                      selected: _head == i,
                      selectedColor: AppColors.accent.withValues(alpha: 0.25),
                      backgroundColor: AppColors.surface2,
                      side: BorderSide(
                        color: _head == i ? AppColors.accent : AppColors.border,
                      ),
                      labelStyle: TextStyle(
                        color: _head == i
                            ? AppColors.accent
                            : AppColors.textSecondary,
                      ),
                      onSelected: (_) => setState(() => _head = i),
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('Selected: ', style: interText(13)),
                Text('L${_layer + 1} / H${_head + 1}',
                    style: monoText(13, weight: FontWeight.w600)),
                const SizedBox(width: 10),
                if (entry != null) HeadTypeChip(type: entry.type),
              ],
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: SizedBox(
                width: gridSize,
                height: gridSize,
                child: Stack(
                  children: [
                    CustomPaint(
                      size: Size(gridSize, gridSize),
                      painter: AttentionHeatmapPainter(
                        matrix: matrix,
                        cellSize: cellSize,
                        labelSize: labelSize,
                      ),
                    ),
                    Positioned.fill(
                      child: GestureDetector(
                        onTapUp: (details) {
                          final pos = details.localPosition;
                          if (pos.dx < labelSize || pos.dy < labelSize) return;
                          final col =
                              ((pos.dx - labelSize) / cellSize).floor();
                          final row =
                              ((pos.dy - labelSize) / cellSize).floor();
                          if (row >= 0 &&
                              row < matrix.length &&
                              col >= 0 &&
                              col < matrix.length) {
                            final weight = matrix[row][col];
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.surface2,
                                content: Text(
                                  'FROM ${data.tokens[row]} → TO ${data.tokens[col]}  weight=${weight.toStringAsFixed(4)}',
                                  style: monoText(12),
                                ),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        child: Container(color: Colors.transparent),
                      ),
                    ),
                    ..._buildTokenLabels(data.tokens, cellSize, labelSize),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Note: Each row sums to 1.0 (softmax output). Brighter cells indicate stronger attention from query token (row) to key token (column).',
                style: interText(12, color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTokenLabels(
    List<String> tokens,
    double cellSize,
    double labelSize,
  ) {
    final widgets = <Widget>[];

    for (var i = 0; i < tokens.length; i++) {
      final label = tokens[i].length > 8
          ? '${tokens[i].substring(0, 7)}…'
          : tokens[i];

      widgets.add(
        Positioned(
          left: labelSize + i * cellSize,
          top: 4,
          width: cellSize,
          child: Transform.rotate(
            angle: -0.6,
            child: Text(
              label,
              style: monoText(8, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      );

      widgets.add(
        Positioned(
          left: 2,
          top: labelSize + i * cellSize + cellSize / 2 - 6,
          width: labelSize - 4,
          child: Text(
            label,
            style: monoText(8, color: AppColors.textSecondary),
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return widgets;
  }
}
