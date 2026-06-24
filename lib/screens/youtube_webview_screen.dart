import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../widgets/network_error_view.dart';

class YouTubeWebViewScreen extends StatefulWidget {
  final String url;

  const YouTubeWebViewScreen({
    super.key,
    required this.url,
  });

  @override
  State<YouTubeWebViewScreen> createState() => _YouTubeWebViewScreenState();
}

class _YouTubeWebViewScreenState extends State<YouTubeWebViewScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  bool _wasBackgrounded = false;
  bool _isClosing = false;
  bool _pendingResumeClose = false;

  void _closeScreen() {
    if (!mounted || _isClosing) return;
    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    _isClosing = true;
    navigator.pop();
  }

  void _attemptResumeClose() {
    if (!mounted || _isClosing) return;

    _pendingResumeClose = false;
    final navigator = Navigator.of(context);

    navigator.maybePop();

    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || _isClosing) return;

      final route = ModalRoute.of(context);
      final isStillCurrent = route?.isCurrent ?? false;
      if (!isStillCurrent) return;

      _closeScreen();
    });
  }

  void _setLoading(bool value) {
    if (!mounted || _loading == value) return;
    setState(() => _loading = value);
  }

  void _loadUrl() {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    _controller.loadRequest(Uri.parse(widget.url));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _hasError = false;
            });
          },
          onProgress: (progress) {
            if (_hasError) return;
            if (progress >= 100) {
              _setLoading(false);
            } else {
              _setLoading(true);
            }
          },
          onNavigationRequest: (request) async {
            return NavigationDecision.navigate;
          },
          onPageFinished: (_) => _setLoading(false),
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
            });
          },
        ),
      );

    _loadUrl();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _wasBackgrounded = true;
        break;
      case AppLifecycleState.resumed:
        if (_wasBackgrounded) {
          _wasBackgrounded = false;
          setState(() {
            _pendingResumeClose = true;
          });
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingResumeClose && !_isClosing) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _attemptResumeClose();
      });
    }

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
      backgroundColor: _hasError
          ? Theme.of(context).scaffoldBackgroundColor
          : const Color(0xFF060606),
      body: Stack(
        children: [
          if (_hasError)
            Padding(
              padding: EdgeInsets.only(top: webViewTopPadding),
              child: NetworkErrorView(onRetry: _loadUrl),
            )
          else
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
                onTap: _closeScreen,
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
