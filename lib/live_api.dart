// lib/live_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'app_config.dart';

class LiveRecording {
  final int id;
  final String file;
  final int size;
  final int createdAt; // unix seconds
  final String url; // "/clips/xxx.mp4"
  final String? thumbUrl; // "/clips/thumbs/xxx.jpg"

  LiveRecording({
    required this.id,
    required this.file,
    required this.size,
    required this.createdAt,
    required this.url,
    this.thumbUrl,
  });

  factory LiveRecording.fromJson(Map<String, dynamic> j) {
    return LiveRecording(
      id: (j['id'] as num?)?.toInt() ?? 0,
      file: (j['file'] ?? '').toString(),
      size: (j['size'] as num?)?.toInt() ?? 0,
      createdAt: (j['createdAt'] as num?)?.toInt() ?? 0,
      url: (j['url'] ?? '').toString(),
      thumbUrl: j['thumbUrl'] == null ? null : j['thumbUrl'].toString(),
    );
  }
}

class LiveApi {
  static String get baseUrl => AppConfig.baseUrl;

  static Map<String, String> _headers() => {
        'Content-Type': 'application/json',
        'X-User-Id': '${AppConfig.userId}',
      };

  static Uri _uri(String path, [Map<String, String>? query]) {
    var b = baseUrl.trim();
    if (b.endsWith('/')) b = b.substring(0, b.length - 1);

    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';

    final u = Uri.parse('$b$p');
    if (query == null || query.isEmpty) return u;
    return u.replace(queryParameters: query);
  }

  static Future<dynamic> _readData(http.Response r) async {
    dynamic jsonBody;
    try {
      jsonBody = json.decode(r.body);
    } catch (_) {
      throw Exception('bad response: ${r.statusCode}');
    }

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final msg = (jsonBody is Map && jsonBody['message'] != null)
          ? jsonBody['message'].toString()
          : 'http ${r.statusCode}';
      throw Exception(msg);
    }

    if (jsonBody is Map && jsonBody['success'] == true) {
      return jsonBody['data'];
    }

    if (jsonBody is Map && jsonBody['message'] != null) {
      throw Exception(jsonBody['message'].toString());
    }

    return jsonBody;
  }

  static String streamUrl() => _uri('/live/stream').toString();

  static String absUrl(String path) {
    final p = path.trim();
    if (p.isEmpty) return '';
    if (p.startsWith('http://') || p.startsWith('https://')) return p;

    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;

    final rel = p.startsWith('/') ? p : '/$p';
    return '$base$rel';
  }

  static Future<Map<String, dynamic>> status() async {
    final r = await http.get(_uri('/live/status'), headers: _headers());
    final data = await _readData(r);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<void> start() async {
    final r = await http.post(_uri('/live/start'), headers: _headers());
    await _readData(r);
  }

  static Future<void> stop() async {
    final r = await http.post(_uri('/live/stop'), headers: _headers());
    await _readData(r);
  }

  static Future<Map<String, dynamic>> takeSnapshot() async {
    final r = await http.post(_uri('/live/snapshot'), headers: _headers());
    final data = await _readData(r);
    return Map<String, dynamic>.from(data as Map);
  }

  static Future<List<LiveRecording>> recordings() async {
    final r = await http.get(_uri('/live/recordings'), headers: _headers());
    final data = await _readData(r);

    final list = (data as List)
        .map((e) => LiveRecording.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    return list;
  }
}
