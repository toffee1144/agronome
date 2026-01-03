import 'dart:convert';
import 'package:agronome/app_config.dart';
import 'package:http/http.dart' as http;

class PlannerApi {
  PlannerApi({String? baseUrl}) : _baseUrl = baseUrl ?? AppConfig.baseUrl;

  final String _baseUrl;

  Uri _u(String path, [Map<String, String>? q]) {
    return Uri.parse('$_baseUrl$path').replace(queryParameters: q);
  }

  Map<String, String> _headers({bool json = false}) {
    return {
      if (json) 'Content-Type': 'application/json',
      'X-User-Id': AppConfig.userId.toString(),
    };
  }

  Future<List<String>> getFieldLocations() async {
    final r = await http.get(_u('/planner/field-locations'), headers: _headers());
    final json = _ensureOk(r);
    final data = json['data'];
    if (data is List) return data.map((e) => e.toString()).toList();
    return <String>[];
  }

  Future<List<String>> getMissionTypes() async {
    final r = await http.get(_u('/planner/mission-types'), headers: _headers());
    final json = _ensureOk(r);
    final data = json['data'];
    if (data is List) return data.map((e) => e.toString()).toList();
    return <String>[];
  }

  Future<void> addFieldLocation(String name) async {
    final r = await http.post(
      _u('/planner/field-locations'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name}),
    );
    _ensureOk(r);
  }

  Future<void> addMissionType(String name) async {
    final r = await http.post(
      _u('/planner/mission-types'),
      headers: _headers(json: true),
      body: jsonEncode({'name': name}),
    );
    _ensureOk(r);
  }

  Future<List<Map<String, dynamic>>> getMissions() async {
    final r = await http.get(_u('/planner/missions'), headers: _headers());
    final json = _ensureOk(r);
    final data = json['data'];
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return <Map<String, dynamic>>[];
  }

  Future<int> createMission(Map<String, dynamic> payload) async {
    final r = await http.post(
      _u('/planner/missions'),
      headers: _headers(json: true),
      body: jsonEncode(payload),
    );
    final json = _ensureOk(r);
    final data = json['data'];

    if (data is Map && data['id'] is num) {
      return (data['id'] as num).toInt();
    }
    throw Exception('createMission: missing id');
  }

  Future<void> updateMission(int id, Map<String, dynamic> payload) async {
    final r = await http.put(
      _u('/planner/missions/$id'),
      headers: _headers(json: true),
      body: jsonEncode(payload),
    );
    _ensureOk(r);
  }

  Future<void> deleteMission(int id) async {
    final r = await http.delete(
      _u('/planner/missions/$id'),
      headers: _headers(),
    );
    _ensureOk(r);
  }

  Map<String, dynamic> _ensureOk(http.Response r) {
    final ct = (r.headers['content-type'] ?? '').toLowerCase();
    final bodyText = r.body;

    if (r.statusCode < 200 || r.statusCode >= 300) {
      final snippet = bodyText.length > 250 ? bodyText.substring(0, 250) : bodyText;
      throw Exception('http ${r.statusCode}. $snippet');
    }

    final looksLikeHtml = bodyText.trimLeft().startsWith('<!doctype html') ||
        bodyText.trimLeft().startsWith('<html');

    if (!ct.contains('application/json') || looksLikeHtml) {
      final snippet = bodyText.length > 250 ? bodyText.substring(0, 250) : bodyText;
      throw Exception('non-json response. $snippet');
    }

    final body = jsonDecode(bodyText);
    if (body is! Map<String, dynamic>) throw Exception('bad json shape');
    if (body['success'] == false) {
      throw Exception((body['message'] ?? 'error').toString());
    }
    return body;
  }
}
