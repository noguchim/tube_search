import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../l10n/app_localizations.dart';
import '../data/youtube_playback_close_reason.dart';
import '../utils/app_logger.dart';
import '../widgets/app_back_button.dart';
import '../widgets/network_error_view.dart';

class YouTubeWebViewScreen extends StatefulWidget {
  final String url;
  final Duration? autoCloseAfter;

  const YouTubeWebViewScreen({
    super.key,
    required this.url,
    this.autoCloseAfter,
  });

  @override
  State<YouTubeWebViewScreen> createState() => _YouTubeWebViewScreenState();
}

class _YouTubeWebViewScreenState extends State<YouTubeWebViewScreen>
    with WidgetsBindingObserver {
  static const _interactionGrace = Duration(seconds: 1);

  late final WebViewController _controller;
  bool _loading = true;
  bool _hasError = false;
  bool _wasBackgrounded = false;
  bool _isClosing = false;
  Orientation? _lastPhysicalOrientation;
  DateTime? _lastOrientationChangeAt;
  Timer? _resumeCloseTimer;
  Timer? _autoCloseTimer;
  DateTime? _autoCloseDeadline;
  Widget? _fullscreenWidget;
  VoidCallback? _notifyCustomWidgetHidden;
  bool _isOpeningYouTubeApp = false;
  bool _closeAfterYouTubeAppReturn = false;

  Orientation? _physicalOrientation() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isEmpty) return null;

    final size = views.first.physicalSize;
    if (size.isEmpty) return null;

    return size.width > size.height
        ? Orientation.landscape
        : Orientation.portrait;
  }

  bool get _rotatedRecently {
    final changedAt = _lastOrientationChangeAt;
    if (changedAt == null) return false;

    return DateTime.now().difference(changedAt) < const Duration(seconds: 1);
  }

  void _scheduleAutoClose(Duration delay) {
    _autoCloseTimer?.cancel();
    _autoCloseDeadline = DateTime.now().add(delay);
    _autoCloseTimer = Timer(delay, () {
      _autoCloseDeadline = null;
      _closeScreen(reason: YouTubePlaybackCloseReason.automatic);
    });
  }

  void _extendAutoClose(Duration extension) {
    final deadline = _autoCloseDeadline;
    if (deadline == null || _isClosing) return;

    final remaining = deadline.difference(DateTime.now());
    if (remaining <= Duration.zero) return;
    _scheduleAutoClose(remaining + extension);
  }

  void _showFullscreenWidget(
    Widget widget,
    VoidCallback notifyCustomWidgetHidden,
  ) {
    if (!mounted) {
      notifyCustomWidgetHidden();
      return;
    }

    final enteringFullscreen = _fullscreenWidget == null;
    final previousCallback = _notifyCustomWidgetHidden;
    setState(() {
      _fullscreenWidget = widget;
      _notifyCustomWidgetHidden = notifyCustomWidgetHidden;
    });

    if (enteringFullscreen) {
      _extendAutoClose(_interactionGrace);
    }

    if (previousCallback != null &&
        previousCallback != notifyCustomWidgetHidden) {
      previousCallback();
    }
  }

  void _hideFullscreenWidget({bool notifyWebView = false}) {
    final callback = _notifyCustomWidgetHidden;
    _fullscreenWidget = null;
    _notifyCustomWidgetHidden = null;

    if (mounted) {
      setState(() {});
    }

    if (notifyWebView) {
      callback?.call();
    }
  }

  bool _isAppLaunchUrl(String? value) {
    if (value == null || value.isEmpty) return false;

    final uri = Uri.tryParse(value);
    if (uri == null) return false;

    return uri.scheme == 'intent' ||
        uri.scheme == 'vnd.youtube' ||
        uri.scheme == 'youtube';
  }

  Future<void> _openYouTubeApp() async {
    if (_isOpeningYouTubeApp) return;
    _isOpeningYouTubeApp = true;

    if (_fullscreenWidget != null) {
      _hideFullscreenWidget(notifyWebView: true);
    }

    _closeAfterYouTubeAppReturn = true;

    try {
      final opened = await url_launcher.launchUrl(
        Uri.parse(widget.url),
        mode: url_launcher.LaunchMode.externalNonBrowserApplication,
      );

      if (!opened) {
        _closeAfterYouTubeAppReturn = false;
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.browserOpenFailed),
            ),
          );
        }
      }
    } catch (error) {
      _closeAfterYouTubeAppReturn = false;
      logger.w('YouTube app launch failed: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.browserOpenFailed),
          ),
        );
      }
    } finally {
      _isOpeningYouTubeApp = false;
    }
  }

  void _closeScreen({
    YouTubePlaybackCloseReason reason = YouTubePlaybackCloseReason.manual,
  }) {
    if (!mounted || _isClosing) return;

    if (_fullscreenWidget != null &&
        reason == YouTubePlaybackCloseReason.manual) {
      _hideFullscreenWidget(notifyWebView: true);
      return;
    }

    if (_fullscreenWidget != null) {
      _hideFullscreenWidget(notifyWebView: true);
    }

    final navigator = Navigator.of(context);
    if (!navigator.canPop()) return;

    _isClosing = true;
    navigator.pop(reason);
  }

  void _attemptResumeClose({
    YouTubePlaybackCloseReason reason = YouTubePlaybackCloseReason.manual,
  }) {
    if (!mounted || _isClosing) return;

    final navigator = Navigator.of(context);

    navigator.maybePop(reason);

    Future<void>.delayed(const Duration(milliseconds: 220), () {
      if (!mounted || _isClosing) return;

      final route = ModalRoute.of(context);
      final isStillCurrent = route?.isCurrent ?? false;
      if (!isStillCurrent) return;

      _closeScreen(reason: reason);
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
    _lastPhysicalOrientation = _physicalOrientation();

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
          onNavigationRequest: (request) {
            if (_isAppLaunchUrl(request.url)) {
              unawaited(_openYouTubeApp());
              return NavigationDecision.prevent;
            }

            return NavigationDecision.navigate;
          },
          onPageFinished: (_) => _setLoading(false),
          onWebResourceError: (error) {
            if (error.isForMainFrame == false) return;
            if (_isAppLaunchUrl(error.url)) {
              unawaited(_openYouTubeApp());
              return;
            }
            if (_isOpeningYouTubeApp) return;
            if (!mounted) return;
            setState(() {
              _loading = false;
              _hasError = true;
            });
          },
        ),
      );

    final platformController = _controller.platform;
    if (platformController is AndroidWebViewController) {
      unawaited(
        platformController.setCustomWidgetCallbacks(
          onShowCustomWidget: _showFullscreenWidget,
          onHideCustomWidget: _hideFullscreenWidget,
        ),
      );
    }

    _loadUrl();

    final autoCloseAfter = widget.autoCloseAfter;
    if (autoCloseAfter != null) {
      _scheduleAutoClose(autoCloseAfter);
    }
  }

  @override
  void didChangeMetrics() {
    final orientation = _physicalOrientation();
    if (orientation == null) return;

    final previous = _lastPhysicalOrientation;
    _lastPhysicalOrientation = orientation;

    if (previous != null && previous != orientation) {
      _lastOrientationChangeAt = DateTime.now();
      if (_fullscreenWidget == null) {
        _extendAutoClose(_interactionGrace);
      }
    }
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
          final closeAfterYouTubeAppReturn = _closeAfterYouTubeAppReturn;
          _closeAfterYouTubeAppReturn = false;
          _resumeCloseTimer?.cancel();
          _resumeCloseTimer = Timer(const Duration(milliseconds: 400), () {
            if (!closeAfterYouTubeAppReturn && _rotatedRecently) return;
            _attemptResumeClose(
              reason: closeAfterYouTubeAppReturn
                  ? YouTubePlaybackCloseReason.externalApplication
                  : YouTubePlaybackCloseReason.manual,
            );
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
    _resumeCloseTimer?.cancel();
    _autoCloseTimer?.cancel();
    final callback = _notifyCustomWidgetHidden;
    _fullscreenWidget = null;
    _notifyCustomWidgetHidden = null;
    callback?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final topPadding = media.padding.top;
    final isLandscape = media.orientation == Orientation.landscape;
    final webViewTopPadding = isLandscape ? 8.0 : topPadding + 60;
    final backButtonTop = isLandscape ? 18.0 : media.viewPadding.top + 8;
    final backButtonLeft = isLandscape ? 4.0 : media.viewPadding.left + 8;
    final backIconColor = _hasError
        ? Theme.of(context).colorScheme.onSurface
        : Colors.white;
    final webView = WebViewWidget(controller: _controller);
    final fullscreenWidget = _fullscreenWidget;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        systemNavigationBarColor: Colors.black,
        systemNavigationBarDividerColor: Colors.black,
        systemNavigationBarContrastEnforced: false,
      ),
      child: PopScope(
        canPop: fullscreenWidget == null,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop && _fullscreenWidget != null) {
            _hideFullscreenWidget(notifyWebView: true);
          }
        },
        child: Scaffold(
          backgroundColor: _hasError
              ? Theme.of(context).scaffoldBackgroundColor
              : const Color(0xFF060606),
          body: Stack(
            children: [
              IgnorePointer(
                ignoring: fullscreenWidget != null,
                child: Stack(
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
                    if (isLandscape && media.viewPadding.left > 0)
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: 0,
                        width: media.viewPadding.left,
                        child: const ColoredBox(color: Colors.black),
                      ),
                    if (_loading)
                      const Center(child: CircularProgressIndicator()),
                    Positioned(
                      top: backButtonTop,
                      left: backButtonLeft,
                      child: AppBackButton(
                        onPressed: _closeScreen,
                        color: backIconColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (fullscreenWidget != null)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black,
                    child: fullscreenWidget,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
