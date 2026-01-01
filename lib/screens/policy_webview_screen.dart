import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PolicyWebViewScreen extends StatefulWidget {
  final String url;   // ← privacy / terms どちらでもOK

  const PolicyWebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<PolicyWebViewScreen> createState() => _PolicyWebViewScreenState();
}

class _PolicyWebViewScreenState extends State<PolicyWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    // 🌍 端末の言語コード
    final locale = WidgetsBinding.instance.platformDispatcher.locale;
    final isJapanese = locale.languageCode.toLowerCase().startsWith("ja");

    // 🌐 URL に lang パラメータ付与（共通化）
    final uri = Uri.parse(
      "${widget.url}?lang=${isJapanese ? "ja" : "en"}",
    );

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) => setState(() => _loading = false),
        ),
      )
      ..loadRequest(uri);
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
            child: WebViewWidget(controller: _controller),
          ),

          if (_loading)
            const Center(child: CircularProgressIndicator()),

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
