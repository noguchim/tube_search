import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class AnimeWebViewScreen extends StatefulWidget {
  final String url;
  final String title;

  const AnimeWebViewScreen({
    super.key,
    required this.url,
    required this.title,
  });

  @override
  State<AnimeWebViewScreen> createState() => _AnimeWebViewScreenState();
}

class _AnimeWebViewScreenState extends State<AnimeWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (_) => NavigationDecision.navigate,
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF060606) : const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding + 60),
            child: WebViewWidget(controller: _controller),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: topPadding,
            left: 0,
            right: 0,
            child: Container(
              height: 60,
              color: isDark ? const Color(0xFF060606) : const Color(0xFFFAFAFA),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 64),
              child: Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),
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
