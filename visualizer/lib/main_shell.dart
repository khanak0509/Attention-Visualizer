import 'dart:async';

import 'package:flutter/material.dart';

import 'api_service.dart';
import 'app_colors.dart';
import 'models.dart';
import 'screens/ablation_screen.dart';
import 'screens/heatmap_screen.dart';
import 'screens/overview_screen.dart';
import 'screens/probing_screen.dart';
import 'screens/taxonomy_screen.dart';
import 'typography.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final _sentenceController = TextEditingController(
    text: 'The movie was absolutely wonderful and inspiring.',
  );
  final _api = ApiService();

  int _selectedTab = 0;
  bool _loading = false;
  String? _error;
  AnalysisData? _data;
  Timer? _ablationPollTimer;

  @override
  void dispose() {
    _ablationPollTimer?.cancel();
    _sentenceController.dispose();
    super.dispose();
  }

  void _startAblationPolling() {
    _ablationPollTimer?.cancel();
    _ablationPollTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_data == null) {
        _ablationPollTimer?.cancel();
        return;
      }
      if (_data!.ablation != null) {
        _ablationPollTimer?.cancel();
        return;
      }
      if (_data!.ablationError != null) {
        _ablationPollTimer?.cancel();
        return;
      }
      try {
        final result = await _api.fetchAblation();
        if (!mounted) return;
        if (result.ready && result.data != null) {
          setState(() {
            _data = _data!.copyWithAblation(
              ablation: result.data,
              ablationLoading: false,
              ablationProgress: 12,
            );
          });
          _ablationPollTimer?.cancel();
        } else if (result.error != null) {
          setState(() {
            _data = _data!.copyWithAblation(
              ablationLoading: false,
              ablationError: result.error,
            );
          });
          _ablationPollTimer?.cancel();
        } else {
          setState(() {
            _data = _data!.copyWithAblation(
              ablationLoading: true,
              ablationProgress: result.progress,
              ablationEvalSize: result.evalSize,
            );
          });
        }
      } catch (_) {
        // Keep polling — backend may still be loading models.
      }
    });
  }

  Future<void> _analyze() async {
    final sentence = _sentenceController.text.trim();
    if (sentence.isEmpty) {
      setState(() => _error = 'Please enter a sentence.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _api.analyze(sentence);
      if (!mounted) return;
      setState(() {
        _data = result;
        _loading = false;
      });
      if (result.ablation == null) {
        _startAblationPolling();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Failed to connect to backend at ${ApiService.baseUrl}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'LLM Attention Visualizer',
          style: monoText(16, weight: FontWeight.w600),
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          _buildAnalyzeBar(),
          if (_error != null) _buildErrorBanner(),
          Expanded(child: _buildBody()),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAnalyzeBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _sentenceController,
              style: interText(14),
              decoration: InputDecoration(
                hintText: 'Enter a sentence to analyze…',
                hintStyle: interText(14, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.surface2,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.accent),
                ),
              ),
              onSubmitted: (_) => _analyze(),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: _loading ? null : _analyze,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.textPrimary,
                foregroundColor: AppColors.background,
                disabledBackgroundColor: AppColors.textSecondary,
                disabledForegroundColor: AppColors.background.withValues(alpha: 0.6),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.background,
                      ),
                    )
                  : Text(
                      'Analyze',
                      style: interText(
                        14,
                        weight: FontWeight.w600,
                        color: AppColors.background,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: AppColors.danger.withValues(alpha: 0.15),
      child: Text(
        _error!,
        style: interText(13, color: AppColors.danger),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.accent),
            const SizedBox(height: 16),
            Text(
              'Running BERT attention analysis…',
              style: interText(14, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    if (_data == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.psychology_outlined,
                  size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'Enter a sentence and tap Analyze',
                style: interText(16, weight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                'Connects to backend at ${ApiService.baseUrl}',
                style: monoText(12, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    switch (_selectedTab) {
      case 0:
        return OverviewScreen(data: _data!);
      case 1:
        return HeatmapScreen(data: _data!);
      case 2:
        return TaxonomyScreen(data: _data!);
      case 3:
        return AblationScreen(data: _data!, api: _api, sentence: _data!.sentence);
      case 4:
        return ProbingScreen(data: _data!);
      default:
        return OverviewScreen(data: _data!);
    }
  }

  Widget _buildBottomNav() {
    const tabs = [
      (Icons.analytics_outlined, 'Overview'),
      (Icons.grid_on_outlined, 'Heatmap'),
      (Icons.category_outlined, 'Taxonomy'),
      (Icons.science_outlined, 'Ablation'),
      (Icons.psychology_outlined, 'Probing'),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(tabs.length, (i) {
              final selected = _selectedTab == i;
              return Tooltip(
                message: tabs[i].$2,
                child: InkWell(
                  onTap: () => setState(() => _selectedTab = i),
                  child: SizedBox(
                    width: 64,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          tabs[i].$1,
                          size: 24,
                          color: selected
                              ? AppColors.accent
                              : AppColors.textSecondary,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: selected
                                ? AppColors.accent
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
