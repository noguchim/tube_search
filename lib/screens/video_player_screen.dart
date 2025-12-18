import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/network_error_view.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> video;

  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  /// 🧠 WebView 事前ウォームアップ
  static Future<void> preloadController() async {
    try {
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.loadRequest(Uri.parse('https://www.google.com'));
      debugPrint("✅ WebView preload complete");
    } catch (e) {
      debugPrint("⚠️ WebView preload failed: $e");
    }
  }

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late final WebViewController _controller;

  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();

    final videoId = widget.video['id'];

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() {
              _isLoading = true;
              _hasError = false;
            });
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (error) {
            debugPrint("❌ WebView Error: $error");
            setState(() {
              _hasError = true;
              _isLoading = false;
            });
          },
        ),
      )
      ..loadRequest(
        Uri.parse('https://www.youtube.com/watch?v=$videoId'),
      );
  }

  void _retry() {
    final videoId = widget.video['id'];

    setState(() {
      _hasError = false;
      _isLoading = true;
    });

    _controller.loadRequest(
      Uri.parse('https://www.youtube.com/watch?v=$videoId'),
    );
  }

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
      ),

      body: Stack(
        children: [
          // 🔥 ① エラー時はエラー画面
          if (_hasError)
            NetworkErrorView(onRetry: _retry),

          // 🔥 ② 正常時 WebView
          if (!_hasError)
            WebViewWidget(controller: _controller),

          // 🔥 ③ ローディング指標
          if (_isLoading && !_hasError)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}