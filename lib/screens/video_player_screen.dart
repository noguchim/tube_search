import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> video; // 一覧から受け取る全データ

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

  @override
  void initState() {
    super.initState();
    // YouTube動画読み込み
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('https://www.youtube.com/watch?v=${widget.video['id']}'),
      );
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      // ✅ AppBar（テーマカラー適用・タイトル非表示）
      appBar: AppBar(
        title: const SizedBox.shrink(),
        backgroundColor: primaryColor,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      // ✅ WebViewのみ（全画面）
      body: WebViewWidget(controller: _controller),
    );
  }
}
