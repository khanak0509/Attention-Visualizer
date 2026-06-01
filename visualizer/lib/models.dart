class TaxonomyEntry {
  TaxonomyEntry({
    required this.layer,
    required this.head,
    required this.type,
    required this.entropy,
    required this.verticalScore,
    required this.diagonalScore,
  });

  final int layer;
  final int head;
  final String type;
  final double entropy;
  final double verticalScore;
  final double diagonalScore;

  factory TaxonomyEntry.fromJson(Map<String, dynamic> json) {
    return TaxonomyEntry(
      layer: (json['layer'] as num).toInt(),
      head: (json['head'] as num).toInt(),
      type: json['type'] as String,
      entropy: (json['entropy'] as num).toDouble(),
      verticalScore: (json['vertical_score'] as num).toDouble(),
      diagonalScore: (json['diagonal_score'] as num).toDouble(),
    );
  }
}

class AblationCritical {
  AblationCritical({
    required this.layer,
    required this.head,
    required this.drop,
    this.sigma = 0,
  });

  final int layer;
  final int head;
  final double drop;
  final double sigma;

  factory AblationCritical.fromJson(Map<String, dynamic> json) {
    return AblationCritical(
      layer: (json['layer'] as num).toInt(),
      head: (json['head'] as num).toInt(),
      drop: (json['drop'] as num).toDouble(),
      sigma: (json['sigma'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AblationTopHead {
  AblationTopHead({
    required this.layer,
    required this.head,
    required this.drop,
    required this.sigma,
  });

  final int layer;
  final int head;
  final double drop;
  final double sigma;

  factory AblationTopHead.fromJson(Map<String, dynamic> json) {
    return AblationTopHead(
      layer: (json['layer'] as num).toInt(),
      head: (json['head'] as num).toInt(),
      drop: (json['drop'] as num).toDouble(),
      sigma: (json['sigma'] as num).toDouble(),
    );
  }
}

class AblationData {
  AblationData({
    required this.baseline,
    required this.importance,
    required this.layerDrops,
    required this.layerWiseDrops,
    required this.headMaxPerLayer,
    required this.mostCritical,
    required this.meanDrop,
    required this.stdDrop,
    required this.absoluteCritical,
    required this.relativeCritical,
    required this.notableHeads,
    required this.relativeThreshold1Sigma,
    required this.relativeThresholdNotable,
    required this.topHeads,
    required this.evalSize,
    required this.criticalHeads,
    required this.redundantHeads,
  });

  final double baseline;
  final List<List<double>> importance;
  final List<double> layerDrops;
  final List<double> layerWiseDrops;
  final List<double> headMaxPerLayer;
  final AblationCritical mostCritical;
  final double meanDrop;
  final double stdDrop;
  final int absoluteCritical;
  final int relativeCritical;
  final int notableHeads;
  final double relativeThreshold1Sigma;
  final double relativeThresholdNotable;
  final List<AblationTopHead> topHeads;
  final int evalSize;
  final int criticalHeads;
  final int redundantHeads;

  factory AblationData.fromJson(Map<String, dynamic> json) {
    return AblationData(
      baseline: (json['baseline'] as num).toDouble(),
      importance: _parseMatrix(json['importance']),
      layerDrops: (json['layer_drops'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      layerWiseDrops: (json['layer_wise_drops'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          (json['layer_drops'] as List)
              .map((e) => (e as num).toDouble())
              .toList(),
      headMaxPerLayer: (json['head_max_per_layer'] as List?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      mostCritical:
          AblationCritical.fromJson(json['most_critical'] as Map<String, dynamic>),
      meanDrop: (json['mean_drop'] as num?)?.toDouble() ?? 0,
      stdDrop: (json['std_drop'] as num?)?.toDouble() ?? 0,
      absoluteCritical:
          (json['absolute_critical'] as num?)?.toInt() ??
          (json['critical_heads'] as num).toInt(),
      relativeCritical: (json['relative_critical'] as num?)?.toInt() ?? 0,
      notableHeads: (json['notable_heads'] as num?)?.toInt() ?? 0,
      relativeThreshold1Sigma:
          (json['relative_threshold_1sigma'] as num?)?.toDouble() ?? 0,
      relativeThresholdNotable:
          (json['relative_threshold_notable'] as num?)?.toDouble() ?? 0,
      topHeads: (json['top_heads'] as List?)
              ?.map((e) => AblationTopHead.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      evalSize: (json['eval_size'] as num?)?.toInt() ?? 0,
      criticalHeads: (json['critical_heads'] as num).toInt(),
      redundantHeads: (json['redundant_heads'] as num).toInt(),
    );
  }
}

class ProbingBest {
  ProbingBest({
    required this.layer,
    required this.head,
    required this.accuracy,
  });

  final int layer;
  final int head;
  final double accuracy;

  factory ProbingBest.fromJson(Map<String, dynamic> json) {
    return ProbingBest(
      layer: (json['layer'] as num).toInt(),
      head: (json['head'] as num).toInt(),
      accuracy: (json['accuracy'] as num).toDouble(),
    );
  }
}

class SentimentPrediction {
  SentimentPrediction({
    required this.label,
    required this.labelName,
    required this.confidence,
    required this.probabilities,
  });

  final int label;
  final String labelName;
  final double confidence;
  final Map<String, double> probabilities;

  factory SentimentPrediction.fromJson(Map<String, dynamic> json) {
    final probs = (json['probabilities'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, (v as num).toDouble()),
    );
    return SentimentPrediction(
      label: (json['label'] as num).toInt(),
      labelName: json['label_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      probabilities: probs,
    );
  }
}

class AnalysisData {
  AnalysisData({
    required this.sentence,
    required this.tokens,
    required this.attention,
    required this.taxonomy,
    required this.taxonomyCounts,
    required this.mostFocused,
    required this.rollout,
    required this.rolloutCls,
    required this.topClsToken,
    required this.probingGrid,
    required this.probingBest,
    required this.probingLayerMax,
    required this.probingRandomBaseline,
    required this.probingTokenCount,
    required this.posTags,
    this.ablation,
    this.ablationLoading = false,
    this.ablationProgress = 0,
    this.ablationEvalSize = 200,
    this.ablationError,
  });

  final String sentence;
  final List<String> tokens;
  final List<List<List<List<double>>>> attention;
  final List<TaxonomyEntry> taxonomy;
  final Map<String, int> taxonomyCounts;
  final TaxonomyEntry mostFocused;
  final List<List<double>> rollout;
  final List<double> rolloutCls;
  final String topClsToken;
  final List<List<double>> probingGrid;
  final ProbingBest probingBest;
  final List<double> probingLayerMax;
  final double probingRandomBaseline;
  final int probingTokenCount;
  final List<String> posTags;
  final AblationData? ablation;
  final bool ablationLoading;
  final int ablationProgress;
  final int ablationEvalSize;
  final String? ablationError;

  factory AnalysisData.fromJson(Map<String, dynamic> json) {
    final taxonomyList = (json['taxonomy'] as List)
        .map((e) => TaxonomyEntry.fromJson(e as Map<String, dynamic>))
        .toList();

    final countsRaw = json['taxonomy_counts'] as Map<String, dynamic>;
    final counts = countsRaw.map((k, v) => MapEntry(k, (v as num).toInt()));

    AblationData? ablation;
    if (json['ablation'] != null) {
      ablation = AblationData.fromJson(json['ablation'] as Map<String, dynamic>);
    }

    return AnalysisData(
      sentence: json['sentence'] as String,
      tokens: (json['tokens'] as List).cast<String>(),
      attention: _parseAttention(json['attention']),
      taxonomy: taxonomyList,
      taxonomyCounts: counts,
      mostFocused:
          TaxonomyEntry.fromJson(json['most_focused'] as Map<String, dynamic>),
      rollout: _parseMatrix(json['rollout']),
      rolloutCls: (json['rollout_cls'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      topClsToken: json['top_cls_token'] as String? ?? '',
      probingGrid: _parseMatrix(json['probing_grid']),
      probingBest:
          ProbingBest.fromJson(json['probing_best'] as Map<String, dynamic>),
      probingLayerMax: (json['probing_layer_max'] as List)
          .map((e) => (e as num).toDouble())
          .toList(),
      probingRandomBaseline:
          (json['probing_random_baseline'] as num).toDouble(),
      probingTokenCount: (json['probing_token_count'] as num).toInt(),
      posTags: (json['pos_tags'] as List).cast<String>(),
      ablation: ablation,
      ablationLoading: json['ablation_loading'] as bool? ?? false,
      ablationProgress: (json['ablation_progress'] as num?)?.toInt() ?? 0,
      ablationEvalSize: (json['ablation_eval_size'] as num?)?.toInt() ?? 200,
      ablationError: json['ablation_error'] as String?,
    );
  }

  AnalysisData copyWithAblation({
    AblationData? ablation,
    bool? ablationLoading,
    int? ablationProgress,
    int? ablationEvalSize,
    String? ablationError,
  }) {
    return AnalysisData(
      sentence: sentence,
      tokens: tokens,
      attention: attention,
      taxonomy: taxonomy,
      taxonomyCounts: taxonomyCounts,
      mostFocused: mostFocused,
      rollout: rollout,
      rolloutCls: rolloutCls,
      topClsToken: topClsToken,
      probingGrid: probingGrid,
      probingBest: probingBest,
      probingLayerMax: probingLayerMax,
      probingRandomBaseline: probingRandomBaseline,
      probingTokenCount: probingTokenCount,
      posTags: posTags,
      ablation: ablation ?? this.ablation,
      ablationLoading: ablationLoading ?? this.ablationLoading,
      ablationProgress: ablationProgress ?? this.ablationProgress,
      ablationEvalSize: ablationEvalSize ?? this.ablationEvalSize,
      ablationError: ablationError ?? this.ablationError,
    );
  }

  TaxonomyEntry? taxonomyAt(int layer, int head) {
    for (final entry in taxonomy) {
      if (entry.layer == layer + 1 && entry.head == head + 1) {
        return entry;
      }
    }
    return null;
  }
}

List<List<double>> _parseMatrix(dynamic raw) {
  return (raw as List)
      .map(
        (row) => (row as List).map((v) => (v as num).toDouble()).toList(),
      )
      .toList();
}

List<List<List<List<double>>>> _parseAttention(dynamic raw) {
  return (raw as List)
      .map(
        (layer) => (layer as List)
            .map(
              (head) => (head as List)
                  .map(
                    (row) =>
                        (row as List).map((v) => (v as num).toDouble()).toList(),
                  )
                  .toList(),
            )
            .toList(),
      )
      .toList();
}
