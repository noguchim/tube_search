import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/app_back_button.dart';
import '../widgets/network_error_view.dart';

class PolicyWebViewScreen extends StatefulWidget {
  final String url; // ← privacy / terms どちらでもOK

  const PolicyWebViewScreen({super.key, required this.url});

  @override
  State<PolicyWebViewScreen> createState() => _PolicyWebViewScreenState();
}

class _PolicyWebViewScreenState extends State<PolicyWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  late final Uri _uri;

  void _loadUrl() {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _controller.loadRequest(_uri);
  }

  @override
  void initState() {
    super.initState();

    // 🌍 端末の言語コード
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final isJapanese = locale.languageCode.toLowerCase().startsWith("ja");

    // 🌐 URL に lang パラメータ付与
    _uri = Uri.parse("${widget.url}?lang=${isJapanese ? "ja" : "en"}");

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) {
              setState(() {
                _loading = true;
                _hasError = false;
              });
            }
          },
          onNavigationRequest: (request) async {
            final url = request.url;

            // 🔥 GooglePlayは外部ブラウザで開く
            if (url.contains('play.google.com')) {
              final uri = Uri.parse(url);

              await launchUrl(uri, mode: LaunchMode.externalApplication);

              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (_) {
            if (mounted) {
              setState(() => _loading = false);
            }
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (mounted) {
              setState(() {
                _loading = false;
                _hasError = true;
              });
            }
          },
        ),
      );

    _loadUrl();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding + 60),
            child: _hasError
                ? NetworkErrorView(onRetry: _loadUrl)
                : WebViewWidget(controller: _controller),
          ),
          if (_loading) const Center(child: CircularProgressIndicator()),
          Positioned(
            top: topPadding + 8,
            left: 8,
            child: AppBackButton(
              onPressed: () => Navigator.pop(context),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
