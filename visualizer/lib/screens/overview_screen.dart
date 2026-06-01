import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../models.dart';
import '../typography.dart';
import '../widgets.dart';

class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key, required this.data});

  final AnalysisData data;

  static const _papers = [
    ('Voita et al. 2019', 'Analyzing multi-head self-attention'),
    ('Clark et al. 2019', 'What does BERT look at?'),
    ('Kovaleva et al. 2019', 'Revealing dark secrets of BERT'),
    ('Michel et al. 2019', 'Are sixteen heads really better?'),
  ];

  @override
  Widget build(BuildContext context) {
    final ablation = data.ablation;
    final bestPosHead = data.probingBest;
    final ablationPending = ablation == null && data.ablationError == null;
    final evalSize = ablation?.evalSize ?? data.ablationEvalSize;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const ResearchChip(label: 'BERT-base-uncased'),
            const SizedBox(height: 12),
            SizedBox(
              height: 98,
              child: Row(
                children: [
                  Expanded(
                    child: StatCard(
                      label: 'SST-2 Baseline',
                      value: ablation != null
                          ? '${(ablation.baseline * 100).toStringAsFixed(1)}%'
                          : (data.ablationError != null ? 'Error' : '—'),
                      subtitle: ablation != null ? 'all heads intact' : null,
                      detail: ablation != null && evalSize > 0
                          ? '$evalSize validation examples'
                          : null,
                      accentColor: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'Max Drop Head',
                      value: ablation != null
                          ? 'L${ablation.mostCritical.layer} H${ablation.mostCritical.head}'
                          : '—',
                      subtitle: ablation != null
                          ? 'Δ ${ablation.mostCritical.drop.toStringAsFixed(4)} '
                              '(${(ablation.mostCritical.drop * 100).toStringAsFixed(2)}%)'
                          : null,
                      detail: ablation != null
                          ? '${ablation.mostCritical.sigma >= 0 ? '+' : ''}'
                              '${ablation.mostCritical.sigma.toStringAsFixed(1)}σ · '
                              'abs ${ablation.absoluteCritical}/144'
                          : null,
                      accentColor: AppColors.danger,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'Critical Heads',
                      value: ablation != null
                          ? '${ablation.relativeCritical}/144'
                          : '—',
                      subtitle: ablation != null
                          ? '>1σ · cutoff ${ablation.relativeThreshold1Sigma.toStringAsFixed(4)}'
                          : null,
                      detail: ablation != null
                          ? 'μ ${ablation.meanDrop.toStringAsFixed(4)} · '
                              'σ ${ablation.stdDrop.toStringAsFixed(4)}'
                          : null,
                      accentColor: AppColors.accent3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatCard(
                      label: 'Best POS Head',
                      value: 'L${bestPosHead.layer} H${bestPosHead.head}',
                      subtitle:
                          '${(bestPosHead.accuracy * 100).toStringAsFixed(1)}% probe acc',
                      detail: 'linear probe · your sentence',
                      accentColor: AppColors.accent2,
                    ),
                  ),
                ],
              ),
            ),
            if (ablation != null && ablation.topHeads.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Top heads by SST-2 drop',
                      style: interText(10, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    ...ablation.topHeads.take(3).map((h) {
                      final barLen = (h.drop * 2000).round().clamp(0, 14);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'L${h.layer} H${h.head}  '
                          '${h.drop.toStringAsFixed(4)}  '
                          '${h.sigma >= 0 ? '+' : ''}${h.sigma.toStringAsFixed(1)}σ  '
                          '${'█' * barLen}',
                          style: monoText(9, color: AppColors.textSecondary),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
            if (ablationPending) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Running in background',
                      style: interText(12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(2),
                      child: LinearProgressIndicator(
                        value: data.ablationProgress > 0
                            ? data.ablationProgress / 12
                            : null,
                        minHeight: 3,
                        backgroundColor: AppColors.border,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            const SectionHeader(title: 'Analyzed Sentence'),
            SentenceCard(tokens: data.tokens),
            const SizedBox(height: 20),
            const SectionHeader(
              title: 'Head Taxonomy Distribution',
              subtitle: '144 attention heads classified by pattern',
            ),
            TaxonomyDonut(counts: data.taxonomyCounts),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Papers Reproduced'),
            ..._papers.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface2,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.$1, style: monoText(12, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(p.$2,
                          style: interText(12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const SectionHeader(title: 'Mini Stats'),
            if (ablation != null)
              MiniStatRow(
                label: 'Max full-layer drop',
                value: ablation.layerWiseDrops
                    .reduce((a, b) => a > b ? a : b)
                    .toStringAsFixed(4),
              )
            else if (ablationPending)
              MiniStatRow(
                label: 'Ablation',
                value: 'Running in background',
              )
            else
              Text('Ablation data unavailable',
                  style: interText(13, color: AppColors.textSecondary)),
            MiniStatRow(
              label: 'Probing tokens',
              value: '${data.probingTokenCount}',
            ),
            MiniStatRow(
              label: 'Top [CLS] influence',
              value: data.topClsToken,
            ),
            MiniStatRow(
              label: 'Most focused head',
              value:
                  'L${data.mostFocused.layer}/H${data.mostFocused.head} (H=${data.mostFocused.entropy.toStringAsFixed(3)})',
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
