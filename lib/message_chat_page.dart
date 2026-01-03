import 'package:flutter/material.dart';
import 'chat_api.dart';

class MessageChatPage extends StatefulWidget {
  const MessageChatPage({super.key});

  @override
  State<MessageChatPage> createState() => _MessageChatPageState();
}

class _MessageChatPageState extends State<MessageChatPage> {
  static const bg = Color(0xFFF6F7F8);
  static const green = Color(0xFF76B947);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const bubbleGrey = Color(0xFFF3F4F6);

  final _c = TextEditingController();
  final _sc = ScrollController();

  final ChatApi _api = const ChatApi();

  String? _sessionId;
  bool _sending = false;

  final List<_ChatMsg> _msgs = [];

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    try {
      final sid = await _api.start();
      if (!mounted) return;
      setState(() => _sessionId = sid);
    } catch (_) {
      // ignore
    }
  }

  @override
  void dispose() {
    _c.dispose();
    _sc.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_sc.hasClients) return;
      _sc.animateTo(
        _sc.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final t = _c.text.trim();
    if (t.isEmpty) return;
    if (_sending) return;

    final sid = _sessionId;
    if (sid == null) return;

    setState(() {
      _sending = true;
      _msgs.add(_ChatMsg(text: t, time: _fmtNow(), me: true));
    });

    _c.clear();
    FocusScope.of(context).unfocus();
    _scrollToBottom();

    try {
      final res = await _api.send(sessionId: sid, message: t);
      if (!mounted) return;

      setState(() {
        _sessionId = res.sessionId;
        _msgs.add(_ChatMsg(text: res.reply, time: _fmtNow(), me: false));
        _sending = false;
      });
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _msgs.add(_ChatMsg(text: 'Error: $e', time: _fmtNow(), me: false));
        _sending = false;
      });
      _scrollToBottom();
    }
  }

  String _fmtNow() {
    final now = TimeOfDay.now();
    final h = now.hourOfPeriod == 0 ? 12 : now.hourOfPeriod;
    final m = now.minute.toString().padLeft(2, '0');
    final ampm = now.period == DayPeriod.am ? "AM" : "PM";
    return "$h:$m $ampm";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(
              name: "Agronome Assistant",
              status: _sending ? "typing..." : "online",
              onBack: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: ListView.builder(
                controller: _sc,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
                itemCount: _msgs.length,
                itemBuilder: (context, i) {
                  final m = _msgs[i];
                  return _Bubble(
                    text: m.text,
                    time: m.time,
                    me: m.me,
                    green: green,
                    textPrimary: textPrimary,
                    textSecondary: textSecondary,
                    bubbleGrey: bubbleGrey,
                  );
                },
              ),
            ),
            _Composer(
              controller: _c,
              green: green,
              onSend: _send,
              enabled: _sessionId != null && !_sending,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String name;
  final String status;
  final VoidCallback onBack;

  const _TopBar({
    required this.name,
    required this.status,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withOpacity(0.06), width: 1),
        ),
      ),
      child: Row(
        children: [
          
          const SizedBox(width: 10),
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              color: Color(0xFFE5E7EB),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Color(0xFF6B7280), size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final String time;
  final bool me;

  final Color green;
  final Color textPrimary;
  final Color textSecondary;
  final Color bubbleGrey;

  const _Bubble({
    required this.text,
    required this.time,
    required this.me,
    required this.green,
    required this.textPrimary,
    required this.textSecondary,
    required this.bubbleGrey,
  });

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.of(context).size.width * 0.72;

    final bubble = Container(
      constraints: BoxConstraints(maxWidth: maxW),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: me ? green : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: me
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13.5,
          height: 1.25,
          fontWeight: FontWeight.w600,
          color: me ? Colors.white : textPrimary,
        ),
      ),
    );

    final timeText = Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        time,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textSecondary,
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: me ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: me ? Alignment.centerRight : Alignment.centerLeft,
            child: bubble,
          ),
          Align(
            alignment: me ? Alignment.centerRight : Alignment.centerLeft,
            child: timeText,
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final Color green;
  final VoidCallback onSend;
  final bool enabled;

  const _Composer({
    required this.controller,
    required this.green,
    required this.onSend,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: Opacity(
              opacity: enabled ? 1 : 0.5,
              child: Container(
                height: 46,
                padding: const EdgeInsets.only(left: 16, right: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: green, width: 2),
                  borderRadius: BorderRadius.circular(26),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: enabled,
                        onSubmitted: (_) => enabled ? onSend() : null,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          isDense: true,
                        ),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: enabled ? onSend : null,
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: green,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMsg {
  final String text;
  final String time;
  final bool me;

  _ChatMsg({required this.text, required this.time, required this.me});
}
