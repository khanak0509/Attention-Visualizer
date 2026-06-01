import 'package:flutter/material.dart';

import '../api_service.dart';
import '../app_colors.dart';
import '../models.dart';
import '../painters.dart';
import '../typography.dart';
import '../widgets.dart';

class AblationScreen extends StatefulWidget {
  const AblationScreen({
    super.key,
    required this.data,
    required this.api,
    required this.sentence,
  });

  final AnalysisData data;
  final ApiService api;
  final String sentence;

  @override
  State<AblationScreen> createState() => _AblationScreenState();
}

class _AblationScreenState extends State<AblationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _ablateLayer = 0;
  int _ablateHead = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ablation = widget.data.ablation;
    final screenWidth = MediaQuery.of(context).size.width;
    final cellSize = gridCellSize(screenWidth, 12);

    return SafeArea(
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            indicatorColor: AppColors.accent,
            labelColor: AppColors.accent,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: interText(13, weight: FontWeight.w600),
            tabs: const [
              Tab(text: 'Single Head'),
              Tab(text: 'Layer-wise'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSingleHeadTab(ablation, cellSize),
                _buildLayerWiseTab(ablation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleHeadTab(AblationData? ablation, double cellSize) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Head Importance Heatmap',
            subtitle: 'Pre-computed · 144 heads × SST-2 validation · red = drop, blue = gain',
          ),
          if (ablation != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  _ColorLegendDot(color: AppColors.heatmapRed, label: 'drop'),
                  const SizedBox(width: 12),
                  _ColorLegendDot(color: AppColors.heatmapBlue, label: 'gain'),
                  const SizedBox(width: 12),
                  _ColorLegendDot(color: AppColors.heatmapNeutral, label: '~0'),
                ],
              ),
            ),
          if (ablation != null)
            SizedBox(
              width: 12 * cellSize,
              height: 12 * cellSize,
              child: CustomPaint(
                painter: DivergingHeatmapPainter(
                  matrix: ablation.importance,
                  cellSize: cellSize,
                  highlightLayer: _ablateLayer,
                  highlightHead: _ablateHead,
                ),
              ),
            )
          else
            _AblationLoadingPlaceholder(
              loading: widget.data.ablationLoading,
              progress: widget.data.ablationProgress,
              evalSize: widget.data.ablationEvalSize,
              error: widget.data.ablationError,
            ),
          const SizedBox(height: 20),
          const SectionHeader(
            title: 'SST-2 ablation result',
            subtitle: 'Cached from background study — reads instantly, no re-run',
          ),
          Row(
            children: [
              Expanded(
                child: _PickerDropdown(
                  label: 'Layer',
                  value: _ablateLayer,
                  items: List.generate(12, (i) => i),
                  formatter: (v) => 'L${v + 1}',
                  onChanged: (v) => setState(() => _ablateLayer = v),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _PickerDropdown(
                  label: 'Head',
                  value: _ablateHead,
                  items: List.generate(12, (i) => i),
                  formatter: (v) => 'H${v + 1}',
                  onChanged: (v) => setState(() => _ablateHead = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (ablation != null)
            _Sst2BatchResultCard(
              ablation: ablation,
              layer: _ablateLayer + 1,
              head: _ablateHead + 1,
              drop: ablation.importance[_ablateLayer][_ablateHead],
            )
          else
            _AblationLoadingPlaceholder(
              loading: widget.data.ablationLoading,
              progress: widget.data.ablationProgress,
              evalSize: widget.data.ablationEvalSize,
              error: widget.data.ablationError,
            ),
          const SizedBox(height: 16),
          if (ablation != null)
            FindingCard(
              title: 'Ablation Finding',
              body:
                  'Baseline SST-2 accuracy is ${(ablation.baseline * 100).toStringAsFixed(1)}%. '
                  'Ablating L${ablation.mostCritical.layer}/H${ablation.mostCritical.head} causes the largest drop '
                  '(${ablation.mostCritical.drop.toStringAsFixed(4)}). '
                  'Absolute >1%: ${ablation.absoluteCritical}/144 critical. '
                  'Relative >1σ: ${ablation.relativeCritical}/144. '
                  'Notable >0.5σ: ${ablation.notableHeads}/144.',
            ),
        ],
      ),
    );
  }

  Widget _buildLayerWiseTab(AblationData? ablation) {
    if (ablation == null) {
      return _AblationLoadingPlaceholder(
        loading: widget.data.ablationLoading,
        progress: widget.data.ablationProgress,
        evalSize: widget.data.ablationEvalSize,
        error: widget.data.ablationError,
      );
    }

    final drops = ablation.layerWiseDrops;
    final maxDrop = drops.reduce((a, b) => a > b ? a : b);
    final maxLayer = drops.indexWhere((v) => v == maxDrop) + 1;

    const barHeight = 22.0;
    const gap = 6.0;
    const labelWidth = 28.0;
    final chartHeight = drops.length * (barHeight + gap);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            title: 'Layer-wise Ablation',
            subtitle: 'All 12 heads in a layer removed at once · pre-computed on SST-2',
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: SizedBox(
              height: chartHeight,
              width: double.infinity,
              child: CustomPaint(
                painter: HorizontalBarChartPainter(
                  values: drops,
                  barHeight: barHeight,
                  gap: gap,
                  labelWidth: labelWidth,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _ColorLegendDot(color: AppColors.heatmapRed, label: '≥ 0.01'),
              const SizedBox(width: 12),
              _ColorLegendDot(color: AppColors.accent3, label: '≥ 0.005'),
              const SizedBox(width: 12),
              _ColorLegendDot(color: AppColors.accent2, label: '< 0.005'),
            ],
          ),
          const SizedBox(height: 16),
          Container(
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
                Text(
                  'Layer $maxLayer — largest full-layer drop',
                  style: interText(12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Text(
                  'Drop ${maxDrop.toStringAsFixed(4)} (${(maxDrop * 100).toStringAsFixed(2)}%) · '
                  'baseline ${(ablation.baseline * 100).toStringAsFixed(2)}%',
                  style: monoText(12, weight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  'Single-head max in L$maxLayer was only '
                  '${ablation.headMaxPerLayer.length > maxLayer - 1 ? ablation.headMaxPerLayer[maxLayer - 1].toStringAsFixed(4) : "—"} — '
                  'full layer removal is a stronger test.',
                  style: interText(11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          FindingCard(
            title: 'Layer-wise Finding',
            body:
                'Removing all heads in layer $maxLayer drops SST-2 accuracy by '
                '${(maxDrop * 100).toStringAsFixed(2)}% (vs ${(ablation.mostCritical.drop * 100).toStringAsFixed(2)}% for the worst single head L${ablation.mostCritical.layer}/H${ablation.mostCritical.head}). '
                'Background study: 144 single-head runs + 12 full-layer runs on ${ablation.evalSize} examples.',
          ),
        ],
      ),
    );
  }
}

class _Sst2BatchResultCard extends StatelessWidget {
  const _Sst2BatchResultCard({
    required this.ablation,
    required this.layer,
    required this.head,
    required this.drop,
  });

  final AblationData ablation;
  final int layer;
  final int head;
  final double drop;

  @override
  Widget build(BuildContext context) {
    final ablatedAcc = ablation.baseline - drop;
    final sigma =
        ablation.stdDrop > 0 ? (drop - ablation.meanDrop) / ablation.stdDrop : 0.0;
    final evalSize = ablation.evalSize > 0 ? ablation.evalSize : 0;
    final evalLabel = evalSize > 0 ? '$evalSize SST-2 validation examples' : 'SST-2 validation set';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SST-2 accuracy · L$layer/H$head ablated',
            style: interText(13, weight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(evalLabel, style: interText(11, color: AppColors.textSecondary)),
          const SizedBox(height: 12),
          _Sst2MetricRow(
            label: 'Baseline',
            value: '${(ablation.baseline * 100).toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 8),
          _Sst2MetricRow(
            label: 'Ablated',
            value: '${(ablatedAcc * 100).toStringAsFixed(2)}%',
          ),
          const SizedBox(height: 8),
          _Sst2MetricRow(
            label: 'Drop',
            value: '${drop.toStringAsFixed(4)} (${(drop * 100).toStringAsFixed(2)}%) · '
                '${sigma >= 0 ? '+' : ''}${sigma.toStringAsFixed(1)}σ',
            emphasize: true,
          ),
        ],
      ),
    );
  }
}

class _Sst2MetricRow extends StatelessWidget {
  const _Sst2MetricRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 72,
          child: Text(label, style: interText(12, color: AppColors.textSecondary)),
        ),
        Expanded(
          child: Text(
            value,
            style: monoText(12, weight: emphasize ? FontWeight.w700 : FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _AblationLoadingPlaceholder extends StatelessWidget {
  const _AblationLoadingPlaceholder({
    required this.loading,
    this.progress = 0,
    this.evalSize = 200,
    this.error,
  });

  final bool loading;
  final int progress;
  final int evalSize;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (error != null)
            Text(
              error!,
              style: interText(13, color: AppColors.danger),
            )
          else if (loading)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Running SST-2 ablation (144 heads)',
                  style: interText(13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Each head tested on $evalSize validation examples · then 12 layer-wise runs',
                  style: interText(11, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: progress > 0 ? progress / 12 : null,
                    minHeight: 3,
                    backgroundColor: AppColors.border,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            )
          else
            Text(
              'Ablation data not yet available',
              style: interText(13, color: AppColors.textSecondary),
            ),
        ],
      ),
    );
  }
}

class _PickerDropdown extends StatelessWidget {
  const _PickerDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.formatter,
    required this.onChanged,
  });

  final String label;
  final int value;
  final List<int> items;
  final String Function(int) formatter;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: interText(12, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.surface2,
              style: monoText(13),
              items: items
                  .map(
                    (i) => DropdownMenuItem(
                      value: i,
                      child: Text(formatter(i)),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _ColorLegendDot extends StatelessWidget {
  const _ColorLegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: monoText(10, color: AppColors.textSecondary)),
      ],
    );
  }
}
