import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
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
  final int _currentIndex = 0;

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

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
      await openYouTubeInInAppBrowser(context, videoId: id);

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

  void _retry() => _openCurrentVideo(auto: false);

  // =========================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;

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
            tooltip: l.videoPlayerOpenYoutubeTooltip,
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
                      l.videoPlayerTitle,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l.videoPlayerDescription,
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
                      label: Text(
                        _isOpening ? l.videoPlayerOpening : l.videoPlayerOpen,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (_isOpening) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
