import 'dart:convert';
import 'package:agronome/app_config.dart';
import 'package:http/http.dart' as http;

class ChatApi {
  const ChatApi();

  String get _baseUrl => AppConfig.baseUrl;

  Future<String> start() async {
    final res = await http.post(Uri.parse('$_baseUrl/chat/start'));
    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400 || j['success'] != true) {
      throw Exception((j['message'] ?? 'start failed').toString());
    }

    final data = j['data'] as Map<String, dynamic>?;
    if (data == null || data['sessionId'] == null) {
      throw Exception('start failed: missing sessionId');
    }

    return data['sessionId'].toString();
  }

  Future<ChatReply> send({
    required String sessionId,
    required String message,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/chat/message'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'sessionId': sessionId,
        'message': message,
      }),
    );

    final j = jsonDecode(res.body) as Map<String, dynamic>;

    if (res.statusCode >= 400 || j['success'] != true) {
      throw Exception((j['message'] ?? 'send failed').toString());
    }

    final data = j['data'] as Map<String, dynamic>?;
    if (data == null || data['reply'] == null || data['sessionId'] == null) {
      throw Exception('send failed: missing reply/sessionId');
    }

    return ChatReply(
      sessionId: data['sessionId'].toString(),
      reply: data['reply'].toString(),
    );
  }
}

class ChatReply {
  final String sessionId;
  final String reply;

  ChatReply({
    required this.sessionId,
    required this.reply,
  });
}
