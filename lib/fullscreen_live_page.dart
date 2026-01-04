import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';

class FullscreenLivePage extends StatefulWidget {
  final String streamUrl;
  final bool running;
  final bool hasFrame;
  final double? secondsSinceFrame;
  final bool recordEnabled;
  final bool recordingActive;
  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onSnapshot;

  const FullscreenLivePage({
    super.key,
    required this.streamUrl,
    required this.running,
    required this.hasFrame,
    required this.secondsSinceFrame,
    required this.recordEnabled,
    required this.recordingActive,
    required this.busy,
    required this.onToggle,
    required this.onSnapshot,
  });

  @override
  State<FullscreenLivePage> createState() => _FullscreenLivePageState();
}

class _FullscreenLivePageState extends State<FullscreenLivePage> {
  bool _showControls = true;
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
  }

  void _autoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _showThenHide() {
    setState(() => _showControls = true);
    _autoHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();

    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);

    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
    );

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final running = widget.running;
    final hasFrame = widget.hasFrame;

    String badgeText;
    if (!running) {
      badgeText = 'OFF';
    } else if (!hasFrame) {
      final s = widget.secondsSinceFrame;
      badgeText = s == null ? 'NO FRAME' : 'NO FRAME ${s.toStringAsFixed(1)}s';
    } else {
      badgeText = 'LIVE';
    }

    final now = DateTime.now();
    final clock =
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _showThenHide,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (running)
              Mjpeg(
                key: ValueKey(widget.streamUrl),
                isLive: true,
                stream: widget.streamUrl,
                fit: BoxFit.cover,
              )
            else
              Container(color: Colors.black),

            Positioned(
              top: 16,
              left: 16,
              child: _badge(badgeText),
            ),

            if (widget.recordEnabled && widget.recordingActive)
              Positioned(
                top: 16,
                right: 16,
                child: _badge('REC', bg: Colors.red),
              ),

            Positioned(
              left: 16,
              bottom: 16,
              child: _badge(clock),
            ),

            AnimatedOpacity(
              opacity: _showControls ? 1 : 0,
              duration: const Duration(milliseconds: 200),
              child: Center(
                child: InkWell(
                  onTap: widget.busy
                      ? null
                      : () {
                          widget.onToggle();
                          _showThenHide();
                        },
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      running
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 40,
                      color: Colors.green,
                    ),
                  ),
                ),
              ),
            ),

            Positioned(
              right: 16,
              bottom: 16,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: InkWell(
                  onTap: widget.onSnapshot,
                  child: _badge('SNAP'),
                ),
              ),
            ),


            Positioned(
              top: 16,
              right: widget.recordEnabled && widget.recordingActive ? 72 : 16,
              child: AnimatedOpacity(
                opacity: _showControls ? 1 : 0,
                duration: const Duration(milliseconds: 200),
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: _badge('EXIT'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, {Color bg = const Color(0xAA000000)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}
