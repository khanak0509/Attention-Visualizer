import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models.dart';
import '../painters.dart';
import '../typography.dart';
import '../widgets.dart';

class TaxonomyScreen extends StatefulWidget {
  const TaxonomyScreen({super.key, required this.data});

  final AnalysisData data;

  @override
  State<TaxonomyScreen> createState() => _TaxonomyScreenState();
}

class _TaxonomyScreenState extends State<TaxonomyScreen> {
  TaxonomyEntry? _selected;

  void _showHeadSheet(TaxonomyEntry entry) {
    setState(() => _selected = entry);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'L${entry.layer} / H${entry.head}',
                    style: monoText(18, weight: FontWeight.w700),
                  ),
                  const SizedBox(width: 10),
                  HeadTypeChip(type: entry.type),
                ],
              ),
              const SizedBox(height: 16),
              _SheetMetric(label: 'Entropy', value: entry.entropy.toStringAsFixed(3)),
              _SheetMetric(
                  label: 'Vertical score', value: entry.verticalScore.toStringAsFixed(3)),
              _SheetMetric(
                  label: 'Diagonal score',
                  value: entry.diagonalScore.toStringAsFixed(3)),
              const SizedBox(height: 12),
              Text(
                'Lower entropy → more focused attention distribution.',
                style: interText(12, color: AppColors.textSecondary),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = gridCellSize(screenWidth, 12);
    final gridSize = 12 * cellSize;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SectionHeader(
              title: 'Head Taxonomy Grid',
              subtitle: 'Tap a cell for detailed scores',
            ),
            _LegendRow(),
            const SizedBox(height: 12),
            GestureDetector(
              onTapUp: (details) {
                final col = (details.localPosition.dx / cellSize).floor();
                final row = (details.localPosition.dy / cellSize).floor();
                if (row >= 0 && row < 12 && col >= 0 && col < 12) {
                  final entry = data.taxonomyAt(row, col);
                  if (entry != null) _showHeadSheet(entry);
                }
              },
              child: SizedBox(
                width: gridSize,
                height: gridSize,
                child: CustomPaint(
                  painter: TaxonomyGridPainter(
                    taxonomy: data.taxonomy,
                    cellSize: cellSize,
                    highlightLayer: _selected != null ? _selected!.layer - 1 : null,
                    highlightHead: _selected != null ? _selected!.head - 1 : null,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Distribution'),
            TaxonomyDonut(counts: data.taxonomyCounts),
            const SizedBox(height: 20),
            FindingCard(
              title: 'Taxonomy Finding',
              body:
                  'Layer ${data.mostFocused.layer}, Head ${data.mostFocused.head} is the most focused head '
                  '(entropy=${data.mostFocused.entropy.toStringAsFixed(3)}, type=${data.mostFocused.type}). '
                  '${data.taxonomyCounts['vertical'] ?? 0} vertical heads attend strongly to [CLS]/[SEP]. '
                  '${data.taxonomyCounts['broad'] ?? 0} broad heads distribute attention uniformly.',
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const types = ['vertical', 'focused', 'broad', 'positional'];
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: types.map((t) => HeadTypeChip(type: t)).toList(),
    );
  }
}

class _SheetMetric extends StatelessWidget {
  const _SheetMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: interText(14, color: AppColors.textSecondary)),
          ),
          Text(value, style: monoText(14, weight: FontWeight.w600)),
        ],
      ),
    );
  }
}
