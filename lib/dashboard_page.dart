// lib/dashboard_page.dart
import 'dart:async';

import 'package:agronome/live_api.dart';
import 'package:agronome/survey_api.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mjpeg/flutter_mjpeg.dart';
import 'package:video_player/video_player.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  static const bg = Color(0xFFF6F7F8);
  static const card = Colors.white;
  static const green = Color(0xFF76B947);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  int tab = 0;

  bool running = false;
  bool hasFrame = false;
  double? secondsSinceFrame;

  bool recordEnabled = false;
  bool recordingActive = false;

  bool busy = false;
  int _streamNonce = 0;

  Timer? _poll;
  Timer? _recoPoll;
  bool _recoPollBusy = false;

  bool _hasSnapshotOnce = false;
  bool _recoLoading = false;
  String? _recoError;
  SurveyRecommendation? _latestReco;

  bool _isProcessingMessage(String msg) {
    final m = msg.toLowerCase();
    return m.contains('ai sedang proses') || m.contains('ai sedang memproses');
  }

  void _stopRecoPoll() {
    _recoPoll?.cancel();
    _recoPoll = null;
    _recoPollBusy = false;
  }

  Future<void> _fetchLatestRecoOnce() async {
    try {
      final list = await SurveyApi.fetchRecommendations(limit: 1, offset: 0);
      final reco = list.isNotEmpty ? list.first : null;

      if (!mounted) return;
      setState(() {
        _latestReco = reco;
        _recoError = null;
        _recoLoading = false;
      });

      final msg = (reco?.message ?? '').trim();
      if (msg.isNotEmpty && !_isProcessingMessage(msg)) {
        _stopRecoPoll();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _recoError = 'failed';
        _recoLoading = false;
      });
    }
  }

  void _startRecoPoll() {
    _stopRecoPoll();

    _recoPoll = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (!mounted) return;
      if (_recoPollBusy) return;

      _recoPollBusy = true;
      try {
        await _fetchLatestRecoOnce();
      } finally {
        _recoPollBusy = false;
      }
    });
  }

  Future<List<SurveyRecommendation>>? _recoFuture;
  Future<List<LiveRecording>>? _recordingsFuture;

  @override
  void initState() {
    super.initState();
    _fetchLiveStatusOnce();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _stopRecoPoll();
    super.dispose();
  }

  BoxDecoration cardDeco({double r = 24}) {
    return BoxDecoration(
      color: card,
      borderRadius: BorderRadius.circular(r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  String _withNonce(String url, int nonce) {
    try {
      final u = Uri.parse(url);
      final qp = Map<String, String>.from(u.queryParameters);
      qp['t'] = '$nonce';
      return u.replace(queryParameters: qp).toString();
    } catch (_) {
      return '$url?t=$nonce';
    }
  }

  void _startPoll() {
    _poll?.cancel();
    _poll = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!mounted) return;
      try {
        await _fetchLiveStatusOnce();
      } catch (_) {}
      if (!mounted) return;
      if (!running) {
        _poll?.cancel();
        _poll = null;
      }
    });
  }

  Future<void> _fetchLiveStatusOnce() async {
    final st = await LiveApi.status();

    final nextRunning = st['running'] == true;
    final nextHasFrame = st['hasFrame'] == true;

    final ssf = st['secondsSinceFrame'];
    final nextSsf = (ssf is num) ? ssf.toDouble() : null;

    bool nextRecEnabled = false;
    bool nextRecActive = false;
    final rec = st['recording'];
    if (rec is Map) {
      nextRecEnabled = rec['enabled'] == true;
      nextRecActive = rec['path'] != null;
    }

    if (!mounted) return;
    setState(() {
      running = nextRunning;
      hasFrame = nextHasFrame;
      secondsSinceFrame = nextSsf;
      recordEnabled = nextRecEnabled;
      recordingActive = nextRecActive;
    });
  }

  Future<void> _fetchLiveStatusAfterPlay() async {
    for (int i = 0; i < 10; i++) {
      try {
        await _fetchLiveStatusOnce();
      } catch (_) {
        if (!mounted) return;
        setState(() {
          hasFrame = false;
          secondsSinceFrame = null;
          recordEnabled = false;
          recordingActive = false;
        });
      }

      if (!mounted) return;
      if (!running) break;
      if (hasFrame) break;

      await Future.delayed(const Duration(milliseconds: 450));
    }
  }

  Future<void> _toggleLive() async {
    if (busy) return;

    setState(() => busy = true);

    if (running) {
      try {
        await LiveApi.stop();
      } catch (_) {}

      _poll?.cancel();
      _poll = null;

      if (!mounted) return;
      setState(() {
        running = false;
        hasFrame = false;
        secondsSinceFrame = null;
        recordEnabled = false;
        recordingActive = false;
        busy = false;
      });
      return;
    }

    try {
      await LiveApi.start();
      _streamNonce++;
    } catch (_) {
      if (!mounted) return;
      setState(() => busy = false);
      return;
    }

    await _fetchLiveStatusAfterPlay();
    _startPoll();

    if (!mounted) return;
    setState(() => busy = false);
  }

  Future<void> _doSnapshot() async {
    if (!running || !hasFrame || busy) return;

    if (!mounted) return;
    setState(() {
      _hasSnapshotOnce = true;
      _recoLoading = true;
      _recoError = null;
    });

    try {
      await LiveApi.takeSnapshot();

      if (!mounted) return;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('saved')),
      );

      await _fetchLatestRecoOnce();
      _startRecoPoll();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _recoLoading = false;
        _recoError = 'failed';
      });
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('snapshot failed')),
      );
    }
  }

  void _onTabChanged(int i) {
    setState(() {
      tab = i;
      if (i == 1) {
        _recordingsFuture = LiveApi.recordings();
      }
    });
  }

  Future<void> _refreshRecordings() async {
    setState(() {
      _recordingsFuture = LiveApi.recordings();
    });
    try {
      await _recordingsFuture;
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final rawStream = LiveApi.streamUrl();
    final streamUrl = _withNonce(rawStream, _streamNonce);

    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1)),
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Dashboard',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _Segmented(
                  left: 'Live View',
                  right: 'Recording',
                  selectedIndex: tab,
                  onChanged: _onTabChanged,
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: tab == 0
                        ? ListView(
                            key: const ValueKey('live'),
                            padding: EdgeInsets.zero,
                            children: [
                              _LivePreviewCard(
                                decoration: cardDeco(),
                                streamUrl: streamUrl,
                                running: running,
                                hasFrame: hasFrame,
                                secondsSinceFrame: secondsSinceFrame,
                                recordEnabled: recordEnabled,
                                recordingActive: recordingActive,
                                busy: busy,
                                onToggle: _toggleLive,
                                onSnapshot: _doSnapshot,
                              ),
                              const SizedBox(height: 18),
                              _RecommendationCard(
                                decoration: cardDeco(),
                                hasSnapshotOnce: _hasSnapshotOnce,
                                loading: _recoLoading,
                                error: _recoError,
                                reco: _latestReco,
                              ),
                              const SizedBox(height: 18),
                              _StatsCard(decoration: cardDeco()),
                            ],
                          )
                        : _RecordingList(
                            key: const ValueKey('recording'),
                            decoration: cardDeco(),
                            future: _recordingsFuture,
                            onRefresh: _refreshRecordings,
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String left;
  final String right;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _Segmented({
    required this.left,
    required this.right,
    required this.selectedIndex,
    required this.onChanged,
  });

  static const green = Color(0xFF76B947);
  static const border = Color(0xFFEDEEEF);

  @override
  Widget build(BuildContext context) {
    Widget pill(String label, bool active, VoidCallback onTap) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: active ? green : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: active ? green : border, width: 1),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        pill(left, selectedIndex == 0, () => onChanged(0)),
        const SizedBox(width: 12),
        pill(right, selectedIndex == 1, () => onChanged(1)),
      ],
    );
  }
}

class _LivePreviewCard extends StatelessWidget {
  final BoxDecoration decoration;

  final String streamUrl;
  final bool running;
  final bool hasFrame;
  final double? secondsSinceFrame;

  final bool recordEnabled;
  final bool recordingActive;

  final bool busy;
  final VoidCallback onToggle;
  final VoidCallback onSnapshot;

  const _LivePreviewCard({
    required this.decoration,
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

  static const green = Color(0xFF76B947);

  @override
  Widget build(BuildContext context) {
    final showNoFrame = running && !hasFrame;
    final snapEnabled = running && hasFrame && !busy;

    final now = DateTime.now();
    final hh = now.hour.toString().padLeft(2, '0');
    final mm = now.minute.toString().padLeft(2, '0');
    final clock = '$hh:$mm';

    String badgeText;
    if (!running) {
      badgeText = 'OFF';
    } else if (!hasFrame) {
      final s = secondsSinceFrame;
      badgeText = s == null ? 'NO FRAME' : 'NO FRAME ${s.toStringAsFixed(1)}s';
    } else {
      badgeText = 'LIVE';
    }

    final showRec = recordEnabled && recordingActive;

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          height: 200,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (running)
                Mjpeg(
                  key: ValueKey(streamUrl),
                  isLive: true,
                  stream: streamUrl,
                  fit: BoxFit.cover,
                )
              else
                Container(color: const Color(0xFF111827)),
              if (!running)
                const Center(
                  child: Text(
                    'Camera is stopped',
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
                  ),
                ),
              if (showNoFrame)
                Container(
                  color: Colors.black.withOpacity(0.45),
                  child: const Center(
                    child: Text(
                      'Check camera',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
              Positioned(
                top: 12,
                left: 12,
                child: _Badge(
                  text: badgeText,
                  bg: Colors.black.withOpacity(0.55),
                  fg: Colors.white,
                ),
              ),
              if (showRec)
                Positioned(
                  top: 12,
                  right: 12,
                  child: _Badge(
                    text: 'REC',
                    bg: Colors.red.withOpacity(0.75),
                    fg: Colors.white,
                  ),
                ),
              Positioned(
                left: 12,
                bottom: 12,
                child: _Badge(
                  text: clock,
                  bg: Colors.black.withOpacity(0.55),
                  fg: Colors.white,
                ),
              ),
              Center(
                child: InkWell(
                  onTap: busy ? null : onToggle,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    width: 74,
                    height: 74,
                    decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                    child: Center(
                      child: busy
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            )
                          : Icon(
                              running ? Icons.pause_rounded : Icons.play_arrow_rounded,
                              size: 34,
                              color: green,
                            ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 12,
                bottom: 12,
                child: InkWell(
                  onTap: snapEnabled ? onSnapshot : null,
                  borderRadius: BorderRadius.circular(12),
                  child: Opacity(
                    opacity: snapEnabled ? 1 : 0.45,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.55),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded, size: 16, color: Colors.white),
                          SizedBox(width: 8),
                          Text(
                            'Snapshot',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordingList extends StatelessWidget {
  final BoxDecoration decoration;
  final Future<List<LiveRecording>>? future;
  final Future<void> Function() onRefresh;

  const _RecordingList({
    super.key,
    required this.decoration,
    required this.future,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (future == null) {
      return ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: decoration,
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tap Recording to load videos.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => onRefresh(),
                  child: const Text('Refresh'),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return FutureBuilder<List<LiveRecording>>(
      future: future,
      builder: (context, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final list = snap.data ?? const <LiveRecording>[];

        if (loading) {
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Container(
                decoration: decoration,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ],
          );
        }

        return RefreshIndicator(
          onRefresh: onRefresh,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Latest recordings',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ),
                  TextButton(onPressed: () => onRefresh(), child: const Text('Refresh')),
                ],
              ),
              const SizedBox(height: 12),
              if (list.isEmpty)
                Container(
                  decoration: decoration,
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                  child: const Text(
                    'No recordings yet.',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                )
              else
                for (final r in list) ...[
                  _RecordingCard(decoration: decoration, item: r),
                  const SizedBox(height: 16),
                ],
            ],
          ),
        );
      },
    );
  }
}

class _RecordingCard extends StatelessWidget {
  final BoxDecoration decoration;
  final LiveRecording item;

  const _RecordingCard({
    required this.decoration,
    required this.item,
  });

  static const green = Color(0xFF76B947);
  static const textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    final thumb = (item.thumbUrl ?? '').trim();
    final thumbUrl = thumb.isEmpty ? '' : LiveApi.absUrl(thumb);

    final when = DateTime.fromMillisecondsSinceEpoch(item.createdAt * 1000);
    final recordedText = _fmtRecorded(when, item.size);

    return Container(
      decoration: decoration,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            SizedBox(
              height: 210,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (thumbUrl.isNotEmpty)
                    Image.network(
                      thumbUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: const Color(0xFF111827)),
                    )
                  else
                    Container(color: const Color(0xFF111827)),
                  Positioned(
                    right: 14,
                    top: 14,
                    child: _Badge(
                      text: item.file,
                      bg: Colors.black.withOpacity(0.55),
                      fg: Colors.white,
                    ),
                  ),
                  Center(
                    child: InkWell(
                      onTap: () {
                        final full = LiveApi.absUrl(item.url);
                        debugPrint('OPEN VIDEO: $full');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RecordingPlayerPage(
                              title: item.file,
                              videoPath: full, // sudah full URL
                            ),
                          ),
                        );
                      },

                      borderRadius: BorderRadius.circular(999),
                      child: Container(
                        width: 74,
                        height: 74,
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Center(
                          child: Icon(Icons.play_arrow_rounded, size: 34, color: green),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              color: const Color(0xFFF1F1F1),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Text(
                recordedText,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtRecorded(DateTime dt, int sizeBytes) {
    String two(int n) => n.toString().padLeft(2, '0');
    final y = dt.year.toString().padLeft(4, '0');
    final m = two(dt.month);
    final d = two(dt.day);
    final hh = two(dt.hour);
    final mm = two(dt.minute);
    final mb = (sizeBytes / (1024 * 1024)).toStringAsFixed(1);
    return 'Recorded on $y-$m-$d • $hh:$mm • $mb MB';
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _Badge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final BoxDecoration decoration;

  final bool hasSnapshotOnce;
  final bool loading;
  final String? error;
  final SurveyRecommendation? reco;

  const _RecommendationCard({
    required this.decoration,
    required this.hasSnapshotOnce,
    required this.loading,
    required this.error,
    required this.reco,
  });

  static const green = Color(0xFF76B947);
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    Widget header() {
      return Row(
        children: const [
          Icon(Icons.spa_outlined, size: 22, color: textPrimary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Recommendation from latest surveys',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: textPrimary,
              ),
            ),
          ),
        ],
      );
    }

    if (!hasSnapshotOnce) {
      return Container(
        decoration: decoration,
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            header(),
            const SizedBox(height: 10),
            const Text(
              'Take a snapshot to load recommendation.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: textSecondary,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      );
    }

    final message = () {
      if (reco != null) return reco!.message;
      if (loading) return 'Loading recommendation...';
      if (error != null) return 'Failed to load recommendation.';
      return 'No recommendations yet.';
    }();

    final priorityText = reco == null ? '' : SurveyApi.priorityText(reco!.priorityLevel);

    final rawImg = (reco?.imageUrl ?? '').trim();
    final imgUrl = rawImg.isEmpty ? '' : LiveApi.absUrl(rawImg);
    final hasImg = imgUrl.isNotEmpty;

    void openDetails() {
      if (reco == null) return;

      final rawImg2 = (reco!.imageUrl ?? '').trim();
      final imgUrl2 = rawImg2.isEmpty ? '' : LiveApi.absUrl(rawImg2);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) {
          final maxSheetH = MediaQuery.of(context).size.height * 0.72;

          return SafeArea(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetH),
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            SurveyApi.priorityText(reco!.priorityLevel),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: green,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        reco!.message,
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.45,
                          color: textSecondary,
                        ),
                      ),
                      if (imgUrl2.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: Container(
                            height: 240,
                            width: double.infinity,
                            color: const Color(0xFFF6F7F8),
                            child: InteractiveViewer(
                              minScale: 1.0,
                              maxScale: 4.0,
                              child: Center(
                                child: Image.network(
                                  imgUrl2,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                  height: 240,
                                  loadingBuilder: (context, child, progress) {
                                    if (progress == null) return child;
                                    return const Center(child: CircularProgressIndicator());
                                  },
                                  errorBuilder: (context, _, __) {
                                    return const Center(child: Text('Failed to load image'));
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          header(),
          const SizedBox(height: 10),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          if (hasImg) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                imgUrl,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (reco != null)
                Text(
                  priorityText,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: green,
                    letterSpacing: 0.2,
                  ),
                )
              else
                const SizedBox.shrink(),
              InkWell(
                onTap: reco == null ? null : openDetails,
                child: const Text(
                  'View Details',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final BoxDecoration decoration;

  const _StatsCard({required this.decoration});

  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.insert_chart_outlined_rounded, size: 22, color: textPrimary),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Live Stream Statistics',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textPrimary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Real-time data from current flight mission',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textSecondary),
          ),
          const SizedBox(height: 14),
          Row(
            children: const [
              Expanded(child: _StatTile(label: 'FLIGHT TIME', value: '12:45')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'COVERAGE', value: '68%')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(child: _StatTile(label: 'BATTERY', value: '84%')),
              SizedBox(width: 12),
              Expanded(child: _StatTile(label: 'SIGNAL', value: 'Good')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;

  const _StatTile({required this.label, required this.value});

  static const border = Color(0xFFEDEEEF);
  static const textPrimary = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 82,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textPrimary),
          ),
        ],
      ),
    );
  }
}

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

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final uri = Uri.parse(widget.videoPath);
    final c = VideoPlayerController.networkUrl(uri); // tanpa headers
    _c = c;

    try {
      await c.initialize();
      c.setLooping(true);
      await c.play();
      if (!mounted) return;
      setState(() => _ready = true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _ready = false);
    }
  }

  @override
  void dispose() {
    _c?.dispose();
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
            ? const Text(
                'failed to load video',
                style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w700),
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
                              child: VideoProgressIndicator(
                                c,
                                allowScrubbing: true,
                              ),
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
