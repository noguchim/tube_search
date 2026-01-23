import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/app_logger.dart';
import '../utils/open_in_custom_tabs.dart';
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

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen>
    with WidgetsBindingObserver {
  bool _hasError = false;
  bool _isOpening = false;

  /// ⭐ キュー管理（現在位置）
  int _currentIndex = 0;

  /// ⭐ 連続再生用 UI
  bool _showControls = true;
  bool _collapsed = false;
  Timer? _hideTimer;

  /// 自動で開くのは初回だけ（次へ/前へはユーザー操作）
  bool _openedOnce = false;

  Map<String, dynamic> get _currentVideo {
    if (widget.isRepeat && (widget.queue?.isNotEmpty ?? false)) {
      return widget.queue![_currentIndex];
    }
    return widget.video;
  }

  String get _currentVideoId => (_currentVideo['id'] ?? '').toString();

  String get _currentTitle => (_currentVideo['title'] ?? '').toString();

  bool get _hasQueue => widget.isRepeat && (widget.queue?.isNotEmpty ?? false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // 初回だけUIを一度表示
    if (_hasQueue) {
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

    // ✅ 再生画面に入ったら自動で開く（元の挙動を維持）
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openCurrentVideo(auto: true);
    });

    logger.i("📜 Received queue length=${widget.queue?.length ?? 0}");
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hideTimer?.cancel();
    super.dispose();
  }

  // 端末復帰時に再オープンはしない（勝手に開くのはUX悪化＆審査的にも微妙）
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // no-op
  }

  Future<void> _openCurrentVideo({required bool auto}) async {
    final id = _currentVideoId;
    if (id.isEmpty) {
      setState(() => _hasError = true);
      return;
    }

    // autoオープンは初回だけ
    if (auto && _openedOnce) return;
    _openedOnce = true;

    setState(() {
      _hasError = false;
      _isOpening = true;
    });

    try {
      logger.i("🌐 Open in CCT: $id title=$_currentTitle");
      await openYouTubePreferApp(context, videoId: id);

      // CustomTabsを閉じて戻ってきた後
      if (!mounted) return;

      // ✅ 連続再生じゃないときだけ一覧へ戻す
      if (!widget.isRepeat) {
        Navigator.pop(context);
        return;
      }

      setState(() => _isOpening = false);
    } catch (e) {
      logger.w("❌ CustomTabs open failed: $e");
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isOpening = false;
      });
    }
  }

  Future<void> _playPrev() async {
    if (!_hasQueue) return;
    if (_currentIndex <= 0) return;

    setState(() => _currentIndex--);
    // 次へ/前へは「押したら開く」でOK
    await _openCurrentVideo(auto: false);
  }

  Future<void> _playNext() async {
    if (!_hasQueue) return;
    if (_currentIndex >= widget.queue!.length - 1) return;

    setState(() => _currentIndex++);
    await _openCurrentVideo(auto: false);
  }

  void _retry() => _openCurrentVideo(auto: false);

  // =========================================================
  // Repeat UI
  // =========================================================

  Widget _buildRepeatControls() {
    if (!_hasQueue) return const SizedBox.shrink();

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
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.85)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 進捗
          Row(
            children: [
              Text(
                "${_currentIndex + 1}/${widget.queue!.length}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _currentTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 操作ボタン
          Row(
            children: [
              if (!isFirst)
                _buildNavButton(
                  label: "前へ",
                  icon: Icons.fast_rewind,
                  iconAfter: false,
                  onTap: _playPrev,
                )
              else
                const SizedBox(width: 90),
              const Spacer(),
              _buildNavButton(
                label: "開く",
                icon: Icons.open_in_browser,
                iconAfter: true,
                onTap: () => _openCurrentVideo(auto: false),
              ),
              const Spacer(),
              if (!isLast)
                _buildNavButton(
                  label: "次へ",
                  icon: Icons.fast_forward,
                  iconAfter: true,
                  onTap: _playNext,
                )
              else
                const SizedBox(width: 90),
            ],
          ),

          const SizedBox(height: 10),

          // サムネ（前後）
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
    required Future<void> Function() onTap,
  }) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _collapsed = false;
          _showControls = true;
        });
        await onTap();
      },
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

  Widget _buildRepeatOverlay() {
    if (!_hasQueue) return const SizedBox.shrink();

    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // つまみ（常に見える）
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
          // 手動再生ボタン（連続再生じゃなくても開けるように）
          IconButton(
            icon: Icon(
              Icons.open_in_browser,
              color: isDark ? Colors.white : Colors.black87,
            ),
            tooltip: "YouTubeで開く",
            onPressed: () => _openCurrentVideo(auto: false),
          ),
        ],
      ),
      body: Stack(
        children: [
          // ✅ ここは「再生は外部」なので、アプリ内は状態表示に徹する
          if (_hasError)
            NetworkErrorView(onRetry: _retry)
          else
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.ondemand_video,
                        size: 44, color: theme.hintColor),
                    const SizedBox(height: 10),
                    Text(
                      "YouTubeで再生します",
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "「開く」を押すと動画ページを表示します。",
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.hintColor),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: _isOpening
                          ? null
                          : () => _openCurrentVideo(auto: false),
                      icon: const Icon(Icons.open_in_browser),
                      label: Text(_isOpening ? "開いています..." : "開く"),
                    ),
                  ],
                ),
              ),
            ),

          if (_isOpening) const Center(child: CircularProgressIndicator()),

          // ⭐ 連続再生 UI オーバーレイ
          if (_hasQueue)
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
