import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class YouTubeWebViewScreen extends StatefulWidget {
  final String url;

  const YouTubeWebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<YouTubeWebViewScreen> createState() => _YouTubeWebViewScreenState();
}

class _YouTubeWebViewScreenState extends State<YouTubeWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    final uri = Uri.parse(widget.url);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) async {
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(uri);
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final isLandscape = media.orientation == Orientation.landscape;
    final webViewTopPadding = isLandscape ? 8.0 : topPadding + 60;
    final backButtonTop = isLandscape ? 18.0 : topPadding + 8;
    final backButtonLeft = isLandscape ? 4.0 : 8.0;
    final backButtonColor =
        isLandscape ? Colors.black.withValues(alpha: 0.72) : Colors.white;
    final backIconColor = isLandscape ? Colors.white : Colors.black;
    final webView = WebViewWidget(controller: _controller);

    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: webViewTopPadding),
            child: isLandscape
                ? MediaQuery.removePadding(
                    context: context,
                    removeLeft: true,
                    removeRight: true,
                    removeTop: true,
                    removeBottom: true,
                    child: webView,
                  )
                : webView,
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: backButtonTop,
            left: backButtonLeft,
            child: Material(
              color: backButtonColor,
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: backIconColor,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
