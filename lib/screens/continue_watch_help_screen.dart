import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../l10n/app_localizations.dart';
import '../widgets/app_back_button.dart';
import '../widgets/network_error_view.dart';

class ContinueWatchHelpScreen extends StatefulWidget {
  const ContinueWatchHelpScreen({super.key});

  @override
  State<ContinueWatchHelpScreen> createState() =>
      _ContinueWatchHelpScreenState();
}

class _ContinueWatchHelpScreenState extends State<ContinueWatchHelpScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  bool _assetLoaded = false;
  String? _assetPath;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (!mounted) return;
            setState(() {
              _loading = true;
              _hasError = false;
            });
          },
          onPageFinished: (_) async {
            if (!mounted) return;
            await _applyTheme();
            if (mounted) setState(() => _loading = false);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == false || !mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
            });
          },
        ),
      );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final languageCode = Localizations.localeOf(context).languageCode;
    final nextAsset = languageCode == 'ja'
        ? 'assets/html/continue_watch_ja.html'
        : 'assets/html/continue_watch_en.html';
    if (!_assetLoaded || _assetPath != nextAsset) {
      _assetLoaded = true;
      _assetPath = nextAsset;
      _loadAsset();
    } else if (!_loading && !_hasError) {
      _applyTheme();
    }
  }

  Future<void> _loadAsset() async {
    final assetPath = _assetPath;
    if (assetPath == null) return;
    if (mounted) {
      setState(() {
        _loading = true;
        _hasError = false;
      });
    }
    await _controller.loadFlutterAsset(assetPath);
  }

  Future<void> _applyTheme() async {
    if (!mounted) return;
    await _controller.setBackgroundColor(Colors.white);
    await _controller.runJavaScript(
      'document.documentElement.dataset.theme = "light";',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: const AppBackButton(),
        title: Text(l.continueWatchHowToTitle),
        backgroundColor: theme.scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: ColoredBox(
        color: Colors.white,
        child: Stack(
          children: [
            if (_hasError)
              NetworkErrorView(onRetry: _loadAsset)
            else
              WebViewWidget(controller: _controller),
            if (_loading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }
}
