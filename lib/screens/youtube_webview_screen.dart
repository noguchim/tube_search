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
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFF060606),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding + 60),
            child: WebViewWidget(controller: _controller),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: topPadding + 8,
            left: 8,
            child: Material(
              color: Colors.white,
              shape: const CircleBorder(),
              elevation: 6,
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.pop(context),
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    size: 20,
                    color: Colors.black,
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
