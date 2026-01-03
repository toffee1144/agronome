import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class SurveyRecommendation {
  final int id;
  final String message;
  final int priorityLevel;
  final String? imageKey;
  final String? imageUrl;

  SurveyRecommendation({
    required this.id,
    required this.message,
    required this.priorityLevel,
    this.imageKey,
    this.imageUrl,
  });

  factory SurveyRecommendation.fromJson(Map<String, dynamic> j) {
    return SurveyRecommendation(
      id: (j['id'] ?? 0) as int,
      message: (j['message'] ?? '') as String,
      priorityLevel: (j['priority_level'] ?? 1) as int,
      imageKey: j['image_key']?.toString(),
      imageUrl: j['image_url']?.toString(),
    );
  }
}

class SurveyApi {
  static String get _baseUrl => AppConfig.baseUrl;

  static Future<List<SurveyRecommendation>> fetchRecommendations({
    int limit = 1,
    int offset = 0,
  }) async {
    final uri = Uri.parse("$_baseUrl/surveys/recommendations?limit=$limit&offset=$offset");
    final res = await http.get(uri);

    if (res.statusCode != 200) return [];

    final obj = jsonDecode(res.body) as Map<String, dynamic>;
    if (obj['success'] != true) return [];

    final data = obj['data'];
    if (data is! List) return [];

    return data
        .whereType<Map<String, dynamic>>()
        .map((e) => SurveyRecommendation.fromJson(e))
        .toList();
  }

  static Future<SurveyRecommendation?> fetchSecondLatestOrLatest() async {
    final list = await fetchRecommendations(limit: 2, offset: 0);
    if (list.isEmpty) return null;
    if (list.length >= 2) return list[1]; // 2nd latest
    return list[0]; // fallback ke latest
  }

  static String priorityText(int level) {
    if (level >= 3) return "HIGH PRIORITY";
    if (level == 2) return "MEDIUM PRIORITY";
    return "LOW PRIORITY";
  }
}
