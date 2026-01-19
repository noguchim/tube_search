import 'dart:async';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../utils/app_logger.dart';
import '../widgets/network_error_view.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> video;

  /// 連続再生キュー（任意）
  final List<Map<String, dynamic>>? queue;

  /// 連続再生 ON/OFF
  final bool isRepeat;

  const VideoPlayerScreen({
    super.key,
    required this.video,
    this.queue,
    required this.isRepeat,
  });

  static Future<void> preloadController() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.loadRequest(Uri.parse('https://www.google.com'));
      logger.i("✅ WebView preload complete");
    } catch (e) {
      logger.i("⚠️ WebView preload failed: $e");
    }
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  late WebViewController _controller;

  bool _hasError = false;
  bool _isLoading = true;

  /// ⭐ キュー管理（現在位置）
  int _currentIndex = 0;
  Timer? _nextTimer;

  // ✅ ページロードタイムアウト
  Timer? _loadTimeoutTimer;
  static const _loadTimeout = Duration(seconds: 20);

  /// ⭐ 実際に再生する動画（単体 or キュー中の動画）
  Map<String, dynamic> get _currentVideo {
    if (widget.isRepeat && (widget.queue?.isNotEmpty ?? false)) {
      return widget.queue![_currentIndex];
    }
    return widget.video;
  }

  /// ⭐ 連続再生用 UI
  bool _showControls = true; // 起動時は ON（→ 一度だけ見せる）
  bool _collapsed = false; // 折りたたみ状態
  Timer? _hideTimer;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _setupWebView();
    _loadCurrentVideo();

    // ⭐ 連続再生のときだけ UI を一度表示
    if (widget.isRepeat && (widget.queue?.isNotEmpty ?? false)) {
      _showControls = true;
      _collapsed = false;

      _hideTimer?.cancel();
      _hideTimer = Timer(const Duration(seconds: 4), () {
        if (!mounted) return;
        setState(() {
          _showControls = false;
          _collapsed = true;
        });
      });
    }

    logger.i("📜 Received queue length=${widget.queue?.length ?? 0}");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nextTimer?.cancel();
    _hideTimer?.cancel();
    _loadTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // ✅ 復帰時に軽く再読込（音が戻りやすい）
      _controller.reload();
    }
  }

  void _setupWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
            // ✅ ロード開始＝タイムアウト開始
            _startLoadTimeout();
          },
          onPageFinished: (_) {
            // ✅ ロード成功＝タイムアウト停止
            _stopLoadTimeout();

            if (!mounted) return;
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            logger.i("❌ WebView Error: $error");

            // ✅ ロード失敗＝タイムアウト停止
            _stopLoadTimeout();

            if (!mounted) return;
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      );
  }

  void _startLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = Timer(_loadTimeout, () {
      if (!mounted) return;

      logger.w("⏰ WebView load timeout ($_loadTimeout) → show error");

      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    });
  }

  void _stopLoadTimeout() {
    _loadTimeoutTimer?.cancel();
    _loadTimeoutTimer = null;
  }

  /// ⭐ 指定された動画をロード
  void _loadCurrentVideo() {
    final videoId = _currentVideo['id'];
    logger.i("▶️ Play video: $videoId (index=$_currentIndex)");

    _controller.loadRequest(
      Uri.parse('https://www.youtube.com/watch?v=$videoId'),
    );

    if (widget.isRepeat && widget.queue != null) {
      logger.i("🎯 Start timing for next video");
      _scheduleNext();
    }
  }

  void _scheduleNext() {
    if (!widget.isRepeat || widget.queue == null) return;

    final v = widget.queue![_currentIndex];
    final duration = v['durationSeconds'] ?? 0;

    logger
        .i("🕒 durationSeconds(raw)=${v['durationSeconds']} parsed=$duration");

    if (duration == 0) {
      logger.w("⛔ duration=0 → 自動再生スキップ");
      return;
    }

    logger.i("⏳ Schedule next in ${duration}s");

    _nextTimer?.cancel();
    _nextTimer = Timer(Duration(seconds: duration + 3), _playNext);
  }

  /// ⭐ 次の動画へ
  void _playNext() async {
    if (widget.queue == null) return;

    if (_currentIndex >= widget.queue!.length - 1) {
      logger.i("🎬 Queue finished");
      _nextTimer?.cancel();
      return;
    }

    _currentIndex++;

    final id = widget.queue![_currentIndex]['id'];
    logger.i("⏭ Next: index=$_currentIndex id=$id");

    await _loadBlank();

    await _controller.loadRequest(
      Uri.parse("https://www.youtube.com/watch?v=$id"),
    );

    _scheduleNext();
  }

  Future<void> _loadBlank() async {
    await _controller
        .loadHtmlString("<html><body style='background:black;'></body></html>");
    await Future.delayed(const Duration(milliseconds: 200));
  }

  void _retry() {
    _stopLoadTimeout();
    setState(() {
      _hasError = false;
      _isLoading = true;
    });
    _loadCurrentVideo();
  }

  // =========================================================
  // 連続再生 UI  (本体)
  // =========================================================

  Widget _buildRepeatControls() {
    if (!widget.isRepeat || widget.queue == null) {
      return const SizedBox.shrink();
    }

    final isFirst = _currentIndex == 0;
    final isLast = _currentIndex == widget.queue!.length - 1;

    final prev = !isFirst ? widget.queue![_currentIndex - 1] : null;
    final next = !isLast ? widget.queue![_currentIndex + 1] : null;

    String thumbFor(Map<String, dynamic>? v) {
      if (v == null) return "";
      return "https://img.youtube.com/vi/${v["id"]}/hqdefault.jpg";
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.85),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (!isFirst)
                _buildNavButton(
                  label: "前の動画へ",
                  icon: Icons.fast_rewind,
                  iconAfter: false,
                  onTap: () {
                    _nextTimer?.cancel();
                    setState(() => _currentIndex--);
                    _loadCurrentVideo();
                  },
                )
              else
                const SizedBox(width: 90),
              const Spacer(),
              if (!isLast)
                _buildNavButton(
                  label: "次の動画へ",
                  icon: Icons.fast_forward,
                  iconAfter: true,
                  onTap: () {
                    _nextTimer?.cancel();
                    _playNext();
                  },
                )
              else
                const SizedBox(width: 90),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 150,
                child: prev != null
                    ? _thumbTile(
                        title: prev["title"] ?? "",
                        url: thumbFor(prev),
                        alignRight: false,
                      )
                    : const SizedBox.shrink(),
              ),
              SizedBox(
                width: 150,
                child: next != null
                    ? _thumbTile(
                        title: next["title"] ?? "",
                        url: thumbFor(next),
                        alignRight: true,
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _thumbTile({
    required String title,
    required String url,
    required bool alignRight,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Stack(
        children: [
          Image.network(
            url,
            height: 90,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
          Container(
            height: 90,
            color: Colors.black45,
            alignment:
                alignRight ? Alignment.bottomRight : Alignment.bottomLeft,
            padding: const EdgeInsets.all(6),
            child: Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required IconData icon,
    required bool iconAfter,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (!iconAfter) ...[
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(label,
                style: const TextStyle(color: Colors.white, fontSize: 12)),
            if (iconAfter) ...[
              const SizedBox(width: 6),
              Icon(icon, color: Colors.white, size: 18),
            ],
          ],
        ),
      ),
    );
  }

  // =========================================================
  // オーバーレイ（ハンドル付き・開閉＋フェード）
  // =========================================================
  Widget _buildRepeatOverlay() {
    if (!widget.isRepeat || widget.queue == null) {
      return const SizedBox.shrink();
    }

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ⭐ つまみ（常に見える）
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            onVerticalDragUpdate: (d) {
              if (d.primaryDelta == null) return;
              if (d.primaryDelta! < -6) _expand();
              if (d.primaryDelta! > 6) _collapse();
            },
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Center(
                child: Container(
                  width: 44,
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
              ),
            ),
          ),

          // ⭐ UI 本体（ここだけスライドで隠す）
          AnimatedSlide(
            duration: const Duration(milliseconds: 250),
            offset: _collapsed ? const Offset(0, 1.0) : Offset.zero,
            child: IgnorePointer(
              ignoring: _collapsed,
              child: _buildRepeatControls(),
            ),
          ),
        ],
      ),
    );
  }

  void _toggleControls() {
    setState(() {
      _collapsed = !_collapsed;
      _showControls = true;
    });
  }

  void _expand() {
    setState(() {
      _collapsed = false;
      _showControls = true;
    });
  }

  void _collapse() {
    setState(() => _collapsed = true);
  }

  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        elevation: 0.4,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (widget.isRepeat && widget.queue != null)
            IconButton(
              icon: Icon(
                Icons.queue_play_next,
                color: isDark ? Colors.white : Colors.black87,
              ),
              tooltip: "連続再生の操作",
              onPressed: () {
                setState(() {
                  _collapsed = !_collapsed;
                  _showControls = !_collapsed;
                });

                // 👇 AppBar から開いた場合はタイマーを止める
                _hideTimer?.cancel();
              },
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_hasError) NetworkErrorView(onRetry: _retry),
          if (!_hasError) WebViewWidget(controller: _controller),
          if (_isLoading && !_hasError)
            const Center(child: CircularProgressIndicator()),

          // ⭐ 連続再生 UI オーバーレイ
          if (widget.isRepeat && widget.queue != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildRepeatOverlay(),
            ),
        ],
      ),
    );
  }
}
