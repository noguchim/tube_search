import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> video;

  const VideoPlayerScreen({
    super.key,
    required this.video,
  });

  /// 🧠 WebView 事前ウォームアップ（Drop されていたため復活）
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

    // 🎬 YouTube動画読み込み
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(
        Uri.parse('https://www.youtube.com/watch?v=${widget.video['id']}'),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      // ---------------------------------------------------------
      // 🎯 シンプルな通常 AppBar（透明にしない・重ねない）
      // ---------------------------------------------------------
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF111111) : Colors.white,
        elevation: 0.4,
        automaticallyImplyLeading: false, // ← デフォルト戻るは使わない

        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new, // iOS風「<」
            size: 20,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      // ---------------------------------------------------------
      // 🎬 WebView：全画面
      // ---------------------------------------------------------
      body: WebViewWidget(controller: _controller),
    );
  }
}
