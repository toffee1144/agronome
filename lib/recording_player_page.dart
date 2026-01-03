import 'package:agronome/app_config.dart';
import 'package:agronome/live_api.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecordingPlayerPage extends StatefulWidget {
  final String title;
  final String videoPath;

  const RecordingPlayerPage({
    super.key,
    required this.title,
    required this.videoPath,
  });

  @override
  State<RecordingPlayerPage> createState() => _RecordingPlayerPageState();
}

class _RecordingPlayerPageState extends State<RecordingPlayerPage> {
  VideoPlayerController? _c;
  bool _ready = false;
  String? _err;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('PLAY URL: ${widget.videoPath}');

      final uri = Uri.parse(widget.videoPath);

      final c = VideoPlayerController.networkUrl(
        uri,
        httpHeaders: {'X-User-Id': '${AppConfig.userId}'},
      );

      _c = c;

      c.addListener(() {
        final e = c.value.errorDescription;
        if (e != null && e.isNotEmpty && mounted) setState(() => _err = e);
      });

      await c.initialize();
      await c.setLooping(true);
      await c.play();

      if (!mounted) return;
      setState(() {
        _ready = true;
        _err = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _ready = false;
        _err = e.toString();
      });
    }
  }

  @override
  void dispose() {
    final c = _c;
    _c = null;
    c?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final c = _c;

    return Scaffold(
      backgroundColor: const Color(0xFF0B0F17),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0B0F17),
        foregroundColor: Colors.white,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: !_ready || c == null
            ? Text(
                _err == null ? 'failed to load video' : 'failed to load video\n\n$_err',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
              )
            : AspectRatio(
                aspectRatio: c.value.aspectRatio,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    VideoPlayer(c),
                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        color: Colors.black.withOpacity(0.35),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if (!c.value.isInitialized) return;
                                if (c.value.isPlaying) {
                                  c.pause();
                                } else {
                                  c.play();
                                }
                                setState(() {});
                              },
                              icon: Icon(
                                c.value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                                color: Colors.white,
                              ),
                            ),
                            Expanded(
                              child: VideoProgressIndicator(c, allowScrubbing: true),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              _fmt(c.value.position),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  String _fmt(Duration d) {
    String two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    final h = d.inHours;
    if (h > 0) return '${two(h)}:$m:$s';
    return '$m:$s';
  }
}
