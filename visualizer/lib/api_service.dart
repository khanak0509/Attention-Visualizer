import 'dart:convert';

import 'package:http/http.dart' as http;

import 'models.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  Future<AnalysisData> analyze(String sentence) async {
    final response = await http.post(
      Uri.parse('$baseUrl/analyze'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sentence': sentence}),
    );
    if (response.statusCode != 200) {
      throw Exception('Analyze failed (${response.statusCode})');
    }
    return AnalysisData.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<Map<String, dynamic>> ablationPredict({
    required String sentence,
    required int layer,
    required int head,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/ablation/predict'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'sentence': sentence, 'layer': layer, 'head': head}),
    );
    if (response.statusCode != 200) {
      throw Exception('Ablation predict failed (${response.statusCode})');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Poll until background ablation study finishes.
  Future<AblationPollResult> fetchAblation() async {
    final response = await http.get(Uri.parse('$baseUrl/ablation'));
    if (response.statusCode != 200) {
      throw Exception('Ablation fetch failed (${response.statusCode})');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    if (json['ready'] == true) {
      return AblationPollResult(
        ready: true,
        data: AblationData.fromJson(json),
        progress: 12,
        evalSize: 200,
      );
    }
    return AblationPollResult(
      ready: false,
      loading: json['loading'] as bool? ?? false,
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      evalSize: (json['eval_size'] as num?)?.toInt() ?? 200,
      error: json['error'] as String?,
    );
  }
}

class AblationPollResult {
  AblationPollResult({
    required this.ready,
    this.data,
    this.loading = false,
    this.progress = 0,
    this.evalSize = 200,
    this.error,
  });

  final bool ready;
  final AblationData? data;
  final bool loading;
  final int progress;
  final int evalSize;
  final String? error;
}
