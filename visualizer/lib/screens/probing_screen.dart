import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models.dart';
import '../painters.dart';
import '../typography.dart';
import '../widgets.dart';

class ProbingScreen extends StatelessWidget {
  const ProbingScreen({super.key, required this.data});

  final AnalysisData data;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = gridCellSize(screenWidth, 12);
    final best = data.probingBest;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Methodology', style: interText(14, weight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(
                    'Linear probes trained on attention patterns to predict POS tags '
                    '(${data.probingTokenCount} token labels from user sentence + 10 reference sentences). '
                    'Random baseline: ${(data.probingRandomBaseline * 100).toStringAsFixed(1)}%.',
                    style: interText(13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'POS Probing Accuracy Grid',
              subtitle: 'Per-head linear probe accuracy',
            ),
            SizedBox(
              width: 12 * cellSize,
              height: 12 * cellSize,
              child: CustomPaint(
                painter: ProbingGridPainter(
                  grid: data.probingGrid,
                  cellSize: cellSize,
                  bestLayer: best.layer,
                  bestHead: best.head,
                ),
              ),
            ),
            const SizedBox(height: 20),
            _BestHeadCard(
              best: best,
              randomBaseline: data.probingRandomBaseline,
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'POS Tag Classes'),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: data.posTags
                  .map(
                    (t) => ColoredChip(
                      label: t,
                      color: AppColors.surface,
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Layer Max Accuracy',
              subtitle: 'Best head accuracy per layer',
            ),
            SizedBox(
              height: 180,
              width: double.infinity,
              child: CustomPaint(
                painter: LineChartPainter(
                  values: data.probingLayerMax,
                  lineColor: AppColors.textPrimary,
                  baseline: data.probingRandomBaseline,
                ),
              ),
            ),
            const SizedBox(height: 20),
            FindingCard(
              title: 'Probing Finding',
              body:
                  'Layer ${best.layer}, Head ${best.head} achieves the highest POS probing accuracy '
                  '(${(best.accuracy * 100).toStringAsFixed(1)}%), '
                  '${((best.accuracy - data.probingRandomBaseline) * 100).toStringAsFixed(1)} pp above random baseline. '
                  'This suggests syntactic information is encoded in specific mid-to-late layer heads.',
            ),
          ],
        ),
      ),
    );
  }
}

class _BestHeadCard extends StatelessWidget {
  const _BestHeadCard({
    required this.best,
    required this.randomBaseline,
  });

  final ProbingBest best;
  final double randomBaseline;

  @override
  Widget build(BuildContext context) {
    final improvement = best.accuracy - randomBaseline;
    final progress = (best.accuracy / 1.0).clamp(0.0, 1.0);
    final baselineProgress = (randomBaseline / 1.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events_outlined, color: AppColors.textSecondary, size: 22),
              const SizedBox(width: 8),
              Text('Best Head: L${best.layer}/H${best.head}',
                  style: monoText(15, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(best.accuracy * 100).toStringAsFixed(1)}% accuracy',
            style: monoText(24, weight: FontWeight.w700, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '+${(improvement * 100).toStringAsFixed(1)} pp vs random baseline '
            '(${(randomBaseline * 100).toStringAsFixed(1)}%)',
            style: interText(12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: AppColors.surface,
                  color: AppColors.textPrimary,
                ),
              ),
              Positioned(
                left: baselineProgress * (MediaQuery.of(context).size.width - 64),
                top: -2,
                child: Container(
                  width: 2,
                  height: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('▲ random baseline', style: monoText(9, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
