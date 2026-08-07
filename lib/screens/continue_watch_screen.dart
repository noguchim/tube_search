import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart' as ct;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/continue_watch_queue.dart';
import '../data/youtube_playback_close_reason.dart';
import '../data/youtube_video.dart';
import '../l10n/app_localizations.dart';
import '../providers/iap_provider.dart';
import '../services/continue_watch_interstitial_service.dart';
import '../services/continue_watch_service.dart';
import '../services/iap_products.dart';
import '../services/playback_progress_service.dart';
import '../services/watch_history_service.dart';
import '../utils/admob_config.dart';
import '../utils/open_in_custom_tabs.dart';
import '../widgets/app_back_button.dart';
import '../widgets/app_dialog.dart';
import '../widgets/simple_tab_bar.dart';
import 'continue_watch_help_screen.dart';
import 'shop_screen.dart';

enum _ContinueWatchDisplayMode { compact, large }

class ContinueWatchScreen extends StatefulWidget {
  final List<YouTubeVideo> sourceVideos;
  final String sourceTitle;
  final String sourceType;
  final String? sourceQuery;

  const ContinueWatchScreen({
    super.key,
    this.sourceVideos = const [],
    required this.sourceTitle,
    required this.sourceType,
    this.sourceQuery,
  });

  @override
  State<ContinueWatchScreen> createState() => _ContinueWatchScreenState();
}

class _ContinueWatchScreenState extends State<ContinueWatchScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  static const _displayModePrefsKey = 'continue_watch_display_mode_v1';

  late final TabController _tabController;
  final ScrollController _currentGridController = ScrollController();
  late List<ContinueWatchItem> _draftItems;
  Timer? _safariCloseTimer;
  Timer? _orientationAdReloadTimer;
  DateTime? _browserOpenedAt;
  bool _safariOpen = false;
  bool _safariWasBackgrounded = false;
  bool _automaticSafariClose = false;
  bool _opening = false;
  ContinueWatchService? _continueWatchService;
  PlaybackProgressService? _playbackProgressService;
  final _interstitialService = ContinueWatchInterstitialService();
  bool _adsEnabled = false;
  String? _completionHandledQueueId;
  int _autoAdvanceToken = 0;
  YouTubeVideo? _pendingNextVideo;
  String? _pendingNextQueueId;
  int? _pendingNextIndex;
  int _pendingNextCountdown = 0;
  int? _pendingHistoryScrollIndex;
  String? _selectedQueueId;
  int _draftCurrentIndex = 0;
  int _currentGridColumns = 2;
  double _currentGridItemHeight = 0;
  _ContinueWatchDisplayMode _displayMode = _ContinueWatchDisplayMode.compact;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChanged);
    unawaited(_loadDisplayMode());
    final seen = <String>{};
    _draftItems = widget.sourceVideos.where((video) => seen.add(video.id)).map((
      video,
    ) {
      final eligible = ContinueWatchService.isEligibleVideo(video);
      return ContinueWatchItem(
        video: video,
        selected: eligible,
        status: eligible
            ? ContinueWatchItemStatus.pending
            : ContinueWatchItemStatus.excluded,
      );
    }).toList();
    final firstPlayable = _draftItems.indexWhere(
      (item) => item.selected && item.eligible,
    );
    if (firstPlayable >= 0) _draftCurrentIndex = firstPlayable;
  }

  Future<void> _loadDisplayMode() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_displayModePrefsKey);
    if (!mounted || saved == null) return;
    final mode = saved == _ContinueWatchDisplayMode.large.name
        ? _ContinueWatchDisplayMode.large
        : _ContinueWatchDisplayMode.compact;
    if (mode == _displayMode) return;
    setState(() => _displayMode = mode);
  }

  Future<void> _saveDisplayMode(_ContinueWatchDisplayMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_displayModePrefsKey, mode.name);
  }

  bool _isLandscapeNow() {
    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      final size = views.first.physicalSize;
      if (!size.isEmpty) return size.width > size.height;
    }
    return MediaQuery.maybeOrientationOf(context) == Orientation.landscape;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _continueWatchService ??= context.read<ContinueWatchService>();
    _playbackProgressService ??= context.read<PlaybackProgressService>();
    final iap = context.watch<IapProvider>();
    final adsRemoved = iap.isPurchased(IapProducts.removeAds.id);
    _adsEnabled =
        (iap.isReady || AdMobConfig.forceAds) &&
        AdMobConfig.shouldShowAds(adsRemoved: adsRemoved);
    _interstitialService.load(
      enabled: _adsEnabled,
      isLandscape: _isLandscapeNow(),
      enforceOrientation: true,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _tabController.removeListener(_handleTabChanged);
    _cancelAutoAdvance(updateUi: false);
    _tabController.dispose();
    _currentGridController.dispose();
    _safariCloseTimer?.cancel();
    _orientationAdReloadTimer?.cancel();
    _interstitialService.dispose();
    if (_safariOpen) {
      final service = _continueWatchService;
      if (service != null) {
        final queue = service.activeQueue;
        if (queue != null && queue.currentIndex < queue.items.length) {
          final item = queue.items[queue.currentIndex];
          unawaited(
            service.markPaused(
              queue.id,
              queue.currentIndex,
              progressSeconds: item.progressSeconds + _elapsedSinceOpen(),
            ),
          );
          unawaited(
            _playbackProgressService?.saveProgress(
              item.video.id,
              progressSeconds: item.progressSeconds + _elapsedSinceOpen(),
              durationSeconds: item.video.durationSeconds,
            ),
          );
        }
      }
      unawaited(ct.closeCustomTabs());
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_safariOpen) return;

    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
        _safariWasBackgrounded = true;
        break;
      case AppLifecycleState.resumed:
        if (_safariWasBackgrounded && !_automaticSafariClose) {
          _safariWasBackgrounded = false;
          unawaited(_pauseSafariPlayback());
        }
        break;
      case AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    _orientationAdReloadTimer?.cancel();
    _orientationAdReloadTimer = Timer(const Duration(milliseconds: 350), () {
      if (!mounted || !_adsEnabled) return;
      _interstitialService.load(
        enabled: true,
        isLandscape: _isLandscapeNow(),
        enforceOrientation: true,
      );
    });
  }

  int _elapsedSinceOpen() {
    final openedAt = _browserOpenedAt;
    if (openedAt == null) return 0;
    return DateTime.now()
        .difference(openedAt)
        .inSeconds
        .clamp(0, 86400)
        .toInt();
  }

  Future<void> _pauseSafariPlayback() async {
    if (!_safariOpen) return;
    _safariCloseTimer?.cancel();
    _safariOpen = false;

    final service = context.read<ContinueWatchService>();
    final queue = service.activeQueue;
    if (queue == null) return;
    final index = queue.currentIndex;
    final progress = queue.items[index].progressSeconds + _elapsedSinceOpen();
    await service.markPaused(queue.id, index, progressSeconds: progress);
    await _playbackProgressService!.saveProgress(
      queue.items[index].video.id,
      progressSeconds: progress,
      durationSeconds: queue.items[index].video.durationSeconds,
    );
  }

  Future<ContinueWatchQueue?> _ensureQueue() async {
    final service = context.read<ContinueWatchService>();
    final selectedQueueId = _selectedQueueId;
    if (selectedQueueId != null) {
      final selectedQueue = service.queueById(selectedQueueId);
      if (selectedQueue != null) return selectedQueue;
    }

    if (_draftItems.isEmpty) {
      final active = service.activeQueue;
      if (active != null) return active;
    }

    final snapshotVideos = _draftItems.map((item) => item.video).toList();
    if (!snapshotVideos.any(ContinueWatchService.isEligibleVideo)) return null;
    if (!service.canCreateQueue) {
      await _showQueueLimitDialog(service);
      return null;
    }

    final queue = await service.createQueue(
      title: _defaultQueueTitle(),
      sourceType: widget.sourceType,
      sourceQuery: widget.sourceQuery,
      videos: snapshotVideos,
      selectedVideoIds: _draftItems
          .where((item) => item.selected && item.eligible)
          .map((item) => item.video.id)
          .toSet(),
    );
    if (_draftCurrentIndex >= 0 &&
        _draftCurrentIndex < queue.items.length &&
        queue.items[_draftCurrentIndex].selected &&
        queue.items[_draftCurrentIndex].eligible) {
      await service.setCurrentIndex(queue.id, _draftCurrentIndex);
    }
    if (mounted) {
      setState(() => _selectedQueueId = queue.id);
    }
    return queue;
  }

  Future<void> _showQueueLimitDialog(ContinueWatchService service) async {
    final l = AppLocalizations.of(context)!;
    final proEnabled = context.read<IapProvider>().isPurchased(
      IapProducts.continueWatchPro.id,
    );
    final action = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) => AppDialog(
        title: l.continueWatchLimitTitle,
        message: proEnabled
            ? l.continueWatchProLimitMessage(service.maxSavedQueues)
            : l.continueWatchFreeLimitMessage(
                ContinueWatchService.freeQueueLimit,
                ContinueWatchService.proQueueLimit,
              ),
        actionsAlignment: AppDialogActionsAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, proEnabled ? 'history' : 'shop'),
            child: Text(
              proEnabled ? l.continueWatchOpenHistory : l.continueWatchOpenShop,
            ),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (action == 'history') {
      _tabController.animateTo(1);
    } else if (action == 'shop') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const ShopScreen()));
    }
  }

  String _defaultQueueTitle() {
    final suffix = DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now());
    return '${widget.sourceTitle} $suffix'.trim();
  }

  Future<void> _playCurrent() async {
    _cancelAutoAdvance();
    final service = context.read<ContinueWatchService>();
    final queue = await _ensureQueue();
    if (queue == null || !mounted) return;
    var index = queue.currentIndex;
    if (index < 0 ||
        index >= queue.items.length ||
        !queue.items[index].selected ||
        !queue.items[index].eligible) {
      index = service.nextPlayable(queue.id, -1) ?? -1;
    }
    if (index < 0) return;

    final restartingCompletedQueue =
        queue.status == ContinueWatchQueueStatus.completed;
    final restarted = await service.prepareExplicitPlayback(queue.id, index);
    if (restarted) {
      _completionHandledQueueId = null;
      final resetIds = restartingCompletedQueue
          ? queue.items
                .skip(index)
                .where((item) => item.selected && item.eligible)
                .map((item) => item.video.id)
          : [queue.items[index].video.id];
      await _playbackProgressService!.resetAll(resetIds);
    }
    if (mounted) await _playIndex(queue.id, index);
  }

  Future<void> _playIndex(String queueId, int index) async {
    if (_opening || !mounted) return;
    final service = context.read<ContinueWatchService>();
    final queue = service.queueById(queueId);
    if (queue == null || index < 0 || index >= queue.items.length) return;
    final item = queue.items[index];
    if (!item.selected || !item.eligible) return;

    _opening = true;
    final progressService = _playbackProgressService!;
    final historyService = context.read<WatchHistoryService>();
    final sharedProgress = await progressService.resumeSeconds(
      item.video.id,
      durationSeconds: item.video.durationSeconds,
    );
    if (sharedProgress > item.progressSeconds) {
      await service.updateProgress(queueId, index, sharedProgress);
    }
    await service.markPlaying(queueId, index);
    if (!mounted) return;
    _scheduleScrollToCurrent(index);
    _interstitialService.load(
      enabled: _adsEnabled,
      isLandscape: _isLandscapeNow(),
      enforceOrientation: true,
    );
    unawaited(historyService.add(item.video));

    final duration = item.video.durationSeconds ?? 0;
    final remainingSeconds = (duration - item.progressSeconds + 1.5).clamp(
      1.0,
      duration + 1.5,
    );
    final autoCloseAfter = Duration(
      milliseconds: (remainingSeconds * 1000).round(),
    );
    _browserOpenedAt = DateTime.now();

    if (Platform.isIOS) {
      _safariOpen = true;
      _safariWasBackgrounded = false;
      _automaticSafariClose = false;
      _safariCloseTimer?.cancel();
      _safariCloseTimer = Timer(autoCloseAfter, () {
        unawaited(_completeSafariPlayback(queueId, index));
      });

      await openYouTubeInInAppBrowser(
        context,
        videoId: item.video.id,
        startSeconds: item.progressSeconds,
        durationSeconds: item.video.durationSeconds,
        useSavedProgress: false,
        trackProgress: false,
      );
      _opening = false;
      return;
    }

    final reason = await openYouTubeInInAppBrowser(
      context,
      videoId: item.video.id,
      startSeconds: item.progressSeconds,
      durationSeconds: item.video.durationSeconds,
      autoCloseAfter: autoCloseAfter,
      useSavedProgress: false,
      trackProgress: false,
    );
    _opening = false;
    if (!mounted) return;

    if (reason == YouTubePlaybackCloseReason.automatic) {
      await progressService.markCompleted(
        item.video.id,
        durationSeconds: duration,
      );
      final next = await service.markCompletedAndFindNext(queueId, index);
      if (next != null && mounted) {
        await _waitAndPlayNext(queueId, next);
      } else if (mounted) {
        final completedQueue = service.queueById(queueId);
        if (completedQueue != null) {
          _handlePlaylistCompleted(completedQueue);
        }
      }
    } else if (reason != YouTubePlaybackCloseReason.externalApplication) {
      final progress = item.progressSeconds + _elapsedSinceOpen();
      await service.markPaused(queueId, index, progressSeconds: progress);
      await progressService.saveProgress(
        item.video.id,
        progressSeconds: progress,
        durationSeconds: item.video.durationSeconds,
      );
    } else {
      await service.markPaused(
        queueId,
        index,
        progressSeconds: item.progressSeconds,
      );
    }
  }

  Future<void> _completeSafariPlayback(String queueId, int index) async {
    if (!_safariOpen) return;
    _automaticSafariClose = true;
    await ct.closeCustomTabs();
    _safariOpen = false;
    _opening = false;
    if (!mounted) return;

    final service = context.read<ContinueWatchService>();
    final progressService = _playbackProgressService!;
    final item = service.queueById(queueId)?.items[index];
    if (item != null) {
      await progressService.markCompleted(
        item.video.id,
        durationSeconds: item.video.durationSeconds ?? 0,
      );
    }
    final next = await service.markCompletedAndFindNext(queueId, index);
    _automaticSafariClose = false;
    if (next != null && mounted) {
      await _waitAndPlayNext(queueId, next);
    } else if (mounted) {
      final completedQueue = service.queueById(queueId);
      if (completedQueue != null) {
        _handlePlaylistCompleted(completedQueue);
      }
    }
  }

  void _handlePlaylistCompleted(ContinueWatchQueue queue) {
    _cancelAutoAdvance();
    if (_completionHandledQueueId == queue.id) return;
    _completionHandledQueueId = queue.id;
    unawaited(_showPlaylistCompletion());
  }

  Future<void> _showPlaylistCompletion() async {
    await WidgetsBinding.instance.endOfFrame;
    await Future<void>.delayed(const Duration(milliseconds: 350));
    if (!mounted) return;

    Future<void> showCompletionMessage() async {
      if (!mounted) return;
      final l = AppLocalizations.of(context)!;
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.3),
        builder: (dialogContext) => AppDialog(
          title: l.continueWatchCompletedTitle,
          message: l.continueWatchCompleted,
          actionsAlignment: AppDialogActionsAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(l.commonOk),
            ),
          ],
        ),
      );
    }

    var isLandscape = _isLandscapeNow();
    if (_adsEnabled && Platform.isIOS && !isLandscape) {
      _interstitialService.load(
        enabled: true,
        isLandscape: false,
        enforceOrientation: true,
      );
      await _interstitialService.waitUntilAvailable(
        isLandscape: false,
        enforceOrientation: true,
      );
      if (!mounted) return;
      isLandscape = _isLandscapeNow();
    }

    if (_adsEnabled &&
        _interstitialService.showIfAvailable(
          isLandscape: isLandscape,
          enforceOrientation: true,
          onFinished: () => unawaited(showCompletionMessage()),
        )) {
      return;
    }
    _interstitialService.load(
      enabled: _adsEnabled,
      isLandscape: isLandscape,
      enforceOrientation: true,
    );
    await showCompletionMessage();
  }

  Future<void> _waitAndPlayNext(String queueId, int nextIndex) async {
    _cancelAutoAdvance();
    final queue = context.read<ContinueWatchService>().queueById(queueId);
    if (queue == null || nextIndex < 0 || nextIndex >= queue.items.length) {
      return;
    }

    final token = ++_autoAdvanceToken;
    setState(() {
      _pendingNextVideo = queue.items[nextIndex].video;
      _pendingNextQueueId = queueId;
      _pendingNextIndex = nextIndex;
      _pendingNextCountdown = 5;
    });

    for (var seconds = 5; seconds > 0; seconds--) {
      if (!mounted || token != _autoAdvanceToken) return;
      setState(() => _pendingNextCountdown = seconds);
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    if (!mounted || token != _autoAdvanceToken) return;
    _clearAutoAdvanceOverlay();
    await _playIndex(queueId, nextIndex);
  }

  void _cancelAutoAdvance({bool updateUi = true}) {
    _autoAdvanceToken++;
    _clearAutoAdvanceOverlay(updateUi: updateUi);
  }

  void _clearAutoAdvanceOverlay({bool updateUi = true}) {
    void clear() {
      _pendingNextVideo = null;
      _pendingNextQueueId = null;
      _pendingNextIndex = null;
      _pendingNextCountdown = 0;
    }

    if (updateUi && mounted) {
      setState(clear);
    } else {
      clear();
    }
  }

  void _playPendingNextNow() {
    final queueId = _pendingNextQueueId;
    final index = _pendingNextIndex;
    _cancelAutoAdvance();
    if (queueId != null && index != null) {
      unawaited(_playIndex(queueId, index));
    }
  }

  void _handleTabChanged() {
    if (_tabController.index != 0) {
      _cancelAutoAdvance();
      return;
    }
    if (_tabController.indexIsChanging) return;

    final pendingIndex = _pendingHistoryScrollIndex;
    if (pendingIndex != null) {
      _pendingHistoryScrollIndex = null;
      _scheduleScrollToCurrent(pendingIndex);
    }
  }

  Future<void> _movePrevious() async {
    _cancelAutoAdvance();
    final service = context.read<ContinueWatchService>();
    final queue = _selectedQueueId != null
        ? service.queueById(_selectedQueueId!)
        : (_draftItems.isEmpty ? service.activeQueue : null);
    if (queue == null) {
      final previous = _findDraftPlayable(
        _draftCurrentIndex - 1,
        forward: false,
      );
      if (previous != null) {
        setState(() => _draftCurrentIndex = previous);
        _scheduleScrollToCurrent(previous);
      }
      return;
    }
    final previous = service.previousPlayable(queue.id, queue.currentIndex);
    if (previous == null) return;
    await service.setCurrentIndex(queue.id, previous);
    _scheduleScrollToCurrent(previous);
  }

  Future<void> _moveNext() async {
    _cancelAutoAdvance();
    final service = context.read<ContinueWatchService>();
    final queue = _selectedQueueId != null
        ? service.queueById(_selectedQueueId!)
        : (_draftItems.isEmpty ? service.activeQueue : null);
    if (queue == null) {
      final next = _findDraftPlayable(_draftCurrentIndex + 1, forward: true);
      if (next != null) {
        setState(() => _draftCurrentIndex = next);
        _scheduleScrollToCurrent(next);
      }
      return;
    }
    final next = service.nextPlayable(queue.id, queue.currentIndex);
    if (next == null) return;
    await service.setCurrentIndex(queue.id, next);
    _scheduleScrollToCurrent(next);
  }

  int? _findDraftPlayable(int start, {required bool forward}) {
    var index = start;
    while (index >= 0 && index < _draftItems.length) {
      final item = _draftItems[index];
      if (item.selected && item.eligible) return index;
      index += forward ? 1 : -1;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final screenBackground = theme.scaffoldBackgroundColor;
    final hasSecondTitleLine = l.continueWatchHeaderLine2.isNotEmpty;
    final proEnabled = context.watch<IapProvider>().isPurchased(
      IapProducts.continueWatchPro.id,
    );
    return Scaffold(
      backgroundColor: screenBackground,
      appBar: AppBar(
        leading: const AppBackButton(),
        toolbarHeight: hasSecondTitleLine ? 64 : kToolbarHeight,
        title: _ContinueWatchHeaderTitle(
          firstLine: l.continueWatchHeaderLine1,
          secondLine: l.continueWatchHeaderLine2,
          showProBadge: proEnabled,
        ),
        backgroundColor: screenBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _openHowTo,
            icon: const Icon(Icons.help_outline_rounded, size: 19),
            label: Text(l.continueWatchHowTo),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.onSurfaceVariant,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              textStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        bottom: SimpleTabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l.continueWatchCurrentTab),
            Tab(text: l.continueWatchHistoryTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCurrentTab(context), _buildHistoryTab(context)],
      ),
    );
  }

  Widget _buildCurrentTab(BuildContext context) {
    final service = context.watch<ContinueWatchService>();
    final queue = _selectedQueueId != null
        ? service.queueById(_selectedQueueId!)
        : (_draftItems.isEmpty ? service.activeQueue : null);
    final items = queue?.items ?? _draftItems;
    final l = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final eligibleItems = items.where((item) => item.eligible).toList();

    if (items.isEmpty && !service.hasSavedQueues) {
      return Center(child: Text(l.continueWatchEmpty));
    }

    final playbackBottomPadding = 72.0 + MediaQuery.paddingOf(context).bottom;

    return Stack(
      children: [
        Column(
          children: [
            if (items.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 6),
                child: Row(
                  children: [
                    PopupMenuButton<bool>(
                      enabled: eligibleItems.isNotEmpty,
                      tooltip: l.continueWatchSelectionMenu,
                      onSelected: (selected) => _setAllItemsSelected(
                        service: service,
                        queue: queue,
                        eligibleItems: eligibleItems,
                        selected: selected,
                      ),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: true,
                          child: Center(child: Text(l.continueWatchSelectAll)),
                        ),
                        PopupMenuItem(
                          value: false,
                          child: Center(child: Text(l.continueWatchClearAll)),
                        ),
                      ],
                      child: SizedBox(
                        height: 36,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_box_outline_blank_rounded,
                              color: eligibleItems.isEmpty
                                  ? theme.disabledColor
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                            Icon(
                              Icons.arrow_drop_down_rounded,
                              color: eligibleItems.isEmpty
                                  ? theme.disabledColor
                                  : theme.colorScheme.onSurfaceVariant,
                              size: 28,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SegmentedButton<_ContinueWatchDisplayMode>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: _ContinueWatchDisplayMode.compact,
                          icon: Tooltip(
                            message: l.continueWatchCompactView,
                            child: const Icon(
                              Icons.grid_view_rounded,
                              size: 18,
                            ),
                          ),
                        ),
                        ButtonSegment(
                          value: _ContinueWatchDisplayMode.large,
                          icon: Tooltip(
                            message: l.continueWatchLargeView,
                            child: const Icon(
                              Icons.view_agenda_outlined,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                      selected: {_displayMode},
                      onSelectionChanged: (selection) {
                        final mode = selection.first;
                        if (mode == _displayMode) return;
                        setState(() => _displayMode = mode);
                        unawaited(_saveDisplayMode(mode));
                        _scheduleScrollToCurrent(
                          queue?.currentIndex ?? _draftCurrentIndex,
                        );
                      },
                      style: ButtonStyle(
                        visualDensity: VisualDensity.compact,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        foregroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          final isDark = theme.brightness == Brightness.dark;
                          if (states.contains(WidgetState.selected)) {
                            return isDark ? Colors.black : Colors.white;
                          }
                          return isDark ? Colors.white70 : Colors.black;
                        }),
                        backgroundColor: WidgetStateProperty.resolveWith((
                          states,
                        ) {
                          if (!states.contains(WidgetState.selected)) {
                            return Colors.transparent;
                          }
                          return theme.brightness == Brightness.dark
                              ? Colors.white
                              : Colors.black;
                        }),
                        minimumSize: const WidgetStatePropertyAll(Size(34, 34)),
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(horizontal: 7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        queue?.title ?? widget.sourceTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Text(
                      queue == null
                          ? '${items.where((item) => item.selected && item.eligible).length}'
                          : '${queue.completedCount}/${queue.selectedCount}',
                      textAlign: TextAlign.right,
                    ),
                  ],
                ),
              ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isLandscape =
                      MediaQuery.orientationOf(context) ==
                      Orientation.landscape;
                  final columns =
                      _displayMode == _ContinueWatchDisplayMode.large
                      ? (constraints.maxWidth >= 700 ? 2 : 1)
                      : isLandscape
                      ? (constraints.maxWidth >= 900 ? 4 : 3)
                      : 2;
                  final isLarge =
                      _displayMode == _ContinueWatchDisplayMode.large;
                  final horizontalPadding = isLarge ? 20.0 : 24.0;
                  const crossAxisSpacing = 8.0;
                  final itemWidth =
                      (constraints.maxWidth -
                          horizontalPadding -
                          (columns - 1) * crossAxisSpacing) /
                      columns;
                  final horizontalLargeHeight = itemWidth * 0.6 * 9 / 16 + 16;
                  final itemHeight = isLarge
                      ? (horizontalLargeHeight < 136
                            ? 136.0
                            : horizontalLargeHeight)
                      : itemWidth * 9 / 16;
                  _currentGridColumns = columns;
                  _currentGridItemHeight = itemHeight;
                  return GridView.builder(
                    controller: _currentGridController,
                    padding: EdgeInsets.fromLTRB(
                      isLarge ? 10 : 12,
                      6,
                      isLarge ? 10 : 12,
                      playbackBottomPadding,
                    ),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: columns,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: itemWidth / itemHeight,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) => _buildQueueItem(
                      context,
                      item: items[index],
                      large: _displayMode == _ContinueWatchDisplayMode.large,
                      selected:
                          queue?.currentIndex == index ||
                          (queue == null && _draftCurrentIndex == index),
                      onToggle: () {
                        _cancelAutoAdvance();
                        if (queue == null) {
                          setState(() {
                            items[index].selected = !items[index].selected;
                          });
                        } else {
                          service.toggleItem(queue.id, index);
                        }
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _buildPlaybackBar(context, queue),
        ),
        if (_pendingNextVideo case final video?) ...[
          const Positioned.fill(
            child: ModalBarrier(dismissible: false, color: Colors.transparent),
          ),
          Positioned.fill(
            child: SafeArea(
              child: Center(child: _buildAutoAdvanceOverlay(context, video)),
            ),
          ),
        ],
      ],
    );
  }

  void _setAllItemsSelected({
    required ContinueWatchService service,
    required ContinueWatchQueue? queue,
    required List<ContinueWatchItem> eligibleItems,
    required bool selected,
  }) {
    _cancelAutoAdvance();
    if (queue == null) {
      setState(() {
        for (final item in eligibleItems) {
          item.selected = selected;
        }
      });
      return;
    }
    unawaited(service.setAllItemsSelected(queue.id, selected));
  }

  Widget _buildAutoAdvanceOverlay(BuildContext context, YouTubeVideo video) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final borderSide = BorderSide(
      color: isDark
          ? Colors.white.withValues(alpha: 0.06)
          : Colors.black.withValues(alpha: 0.05),
      width: 1,
    );
    final isCompactLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape &&
        MediaQuery.sizeOf(context).height < 500;

    final thumbnail = ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: CachedNetworkImage(
          imageUrl: video.thumbnailUrl,
          fit: BoxFit.cover,
          errorWidget: (_, __, ___) => const ColoredBox(
            color: Colors.black26,
            child: Icon(Icons.broken_image_outlined, color: Colors.white70),
          ),
        ),
      ),
    );

    final details = Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.continueWatchUpNext,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            video.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 17,
              height: 1.3,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (video.channelTitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              video.channelTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 13,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Text(
            l.continueWatchNextCountdown(_pendingNextCountdown),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: _cancelAutoAdvance,
                icon: const Icon(Icons.stop_rounded),
                label: Text(l.continueWatchStop),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.onSurface,
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _playPendingNextNow,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.continueWatchPlayNow),
              ),
            ],
          ),
        ],
      ),
    );

    return FractionallySizedBox(
      widthFactor: isCompactLandscape ? 0.88 : 0.86,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isCompactLandscape ? 680 : 420),
        child: Container(
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.fromBorderSide(borderSide),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 16,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: isCompactLandscape
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(child: thumbnail),
                      Expanded(child: details),
                    ],
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [thumbnail, details],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildQueueItem(
    BuildContext context, {
    required ContinueWatchItem item,
    required bool large,
    required bool selected,
    required VoidCallback onToggle,
  }) {
    final l = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final sharedProgress = context
        .watch<PlaybackProgressService>()
        .progressFractionSync(
          item.video.id,
          durationSeconds: item.video.durationSeconds,
        );
    final displayedProgress = item.progress > sharedProgress
        ? item.progress
        : sharedProgress;
    final thumbnail = CachedNetworkImage(
      imageUrl: item.video.thumbnailUrl,
      fit: BoxFit.cover,
      errorWidget: (_, __, ___) => const ColoredBox(
        color: Colors.black12,
        child: Icon(Icons.broken_image_outlined),
      ),
    );
    final thumbnailContent = Stack(
      fit: StackFit.expand,
      children: [
        thumbnail,
        if (!large)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 22, 8, 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.88),
                  ],
                ),
              ),
              child: Text(
                item.video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
          ),
        if (item.eligible)
          Positioned(
            top: -7,
            left: -7,
            child: Transform.scale(
              scale: large ? 1.4 : 1.25,
              child: Checkbox(
                value: item.selected,
                onChanged: (_) {
                  Feedback.forTap(context);
                  onToggle();
                },
                activeColor: const Color(0xFF22C55E),
                checkColor: Colors.white,
                side: WidgetStateBorderSide.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const BorderSide(
                      color: Colors.transparent,
                      width: 0,
                    );
                  }
                  return const BorderSide(color: Colors.white, width: 2);
                }),
              ),
            ),
          ),
        if (!item.eligible)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.82),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                l.continueWatchExcluded,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: large ? 16 : 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        if (displayedProgress > 0)
          Align(
            alignment: Alignment.bottomCenter,
            child: LinearProgressIndicator(
              value: displayedProgress,
              minHeight: large ? 6 : 5,
              backgroundColor: const Color(0xFFA6A6A6),
              color: const Color(0xFFFF3B30),
            ),
          ),
      ],
    );

    return AnimatedScale(
      scale: large ? 1 : (selected ? 1.05 : 0.96),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.60),
                    blurRadius: 22,
                    spreadRadius: 1.5,
                    offset: const Offset(0, 10),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: item.eligible ? onToggle : null,
            splashColor: large ? Colors.transparent : null,
            highlightColor: large ? Colors.transparent : null,
            child: large
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            width: constraints.maxWidth * 0.6,
                            child: thumbnailContent,
                          ),
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                              color: selected
                                  ? const Color(0xFFF8E7E7)
                                  : Colors.transparent,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.video.title,
                                    maxLines: 5,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          height: 1.25,
                                        ).copyWith(
                                          color: selected
                                              ? Colors.black87
                                              : null,
                                        ),
                                  ),
                                  if (item.video.channelTitle.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      item.video.channelTitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: selected
                                            ? Colors.black54
                                            : colorScheme.onSurfaceVariant,
                                        fontSize: 13,
                                        height: 1.2,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  )
                : thumbnailContent,
          ),
        ),
      ),
    );
  }

  Widget _buildPlaybackBar(BuildContext context, ContinueWatchQueue? queue) {
    final l = AppLocalizations.of(context)!;
    final canPlay =
        queue?.selectedCount != 0 ||
        _draftItems.any((item) => item.selected && item.eligible);
    final isPaused = queue?.status == ContinueWatchQueueStatus.paused;
    final currentIndex = queue?.currentIndex ?? _draftCurrentIndex;
    final service = context.read<ContinueWatchService>();
    final previousIndex = queue == null
        ? _findDraftPlayable(currentIndex - 1, forward: false)
        : service.previousPlayable(queue.id, currentIndex);
    final nextIndex = queue == null
        ? _findDraftPlayable(currentIndex + 1, forward: true)
        : service.nextPlayable(queue.id, currentIndex);
    final safeBottom = MediaQuery.paddingOf(context).bottom;
    final playbackBarBottomPadding = Platform.isIOS
        ? safeBottom.clamp(0.0, 16.0).toDouble()
        : safeBottom;
    return Material(
      elevation: 8,
      color: Colors.black.withValues(alpha: 0.75),
      child: Padding(
        padding: EdgeInsets.only(bottom: playbackBarBottomPadding),
        child: SizedBox(
          height: 55,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                tooltip: l.continueWatchPrevious,
                onPressed: previousIndex == null ? null : _movePrevious,
                icon: const Icon(Icons.skip_previous_rounded),
                color: Colors.white,
                disabledColor: Colors.white38,
                iconSize: 36,
              ),
              const SizedBox(width: 28),
              IconButton(
                tooltip: isPaused ? l.continueWatchPaused : l.continueWatchPlay,
                onPressed: canPlay ? _playCurrent : null,
                icon: Icon(
                  isPaused ? Icons.pause_rounded : Icons.play_arrow_rounded,
                ),
                color: Colors.white,
                disabledColor: Colors.white38,
                iconSize: 48,
              ),
              const SizedBox(width: 28),
              IconButton(
                tooltip: l.continueWatchNext,
                onPressed: nextIndex == null ? null : _moveNext,
                icon: const Icon(Icons.skip_next_rounded),
                color: Colors.white,
                disabledColor: Colors.white38,
                iconSize: 36,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openHowTo() async {
    _cancelAutoAdvance();
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ContinueWatchHelpScreen()));
  }

  Widget _buildHistoryTab(BuildContext context) {
    final service = context.watch<ContinueWatchService>();
    final queues = service.queues;
    final l = AppLocalizations.of(context)!;
    if (queues.isEmpty) return Center(child: Text(l.continueWatchHistoryEmpty));

    return ListView.separated(
      padding: const EdgeInsets.all(12),
      itemCount: queues.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final queue = queues[index];
        final first = queue.items.isEmpty ? null : queue.items.first.video;
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 4,
            vertical: 6,
          ),
          leading: SizedBox(
            width: 92,
            child: first == null
                ? const ColoredBox(color: Colors.black12)
                : CachedNetworkImage(
                    imageUrl: first.thumbnailUrl,
                    fit: BoxFit.cover,
                  ),
          ),
          title: Text(
            queue.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${queue.completedCount}/${queue.selectedCount}  '
            '${DateFormat('yyyy/MM/dd HH:mm').format(queue.lastPlayedAt)}',
          ),
          onTap: () async {
            await service.activate(queue.id);
            if (mounted) {
              setState(() => _selectedQueueId = queue.id);
              _pendingHistoryScrollIndex = queue.currentIndex;
              _tabController.animateTo(0);
            }
          },
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'rename' && mounted) {
                await _renameQueue(queue);
              }
              if (value == 'delete' && mounted) {
                await _confirmDelete(queue);
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'rename',
                child: Text(l.continueWatchRename),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(l.continueWatchDelete),
              ),
            ],
          ),
        );
      },
    );
  }

  void _scheduleScrollToCurrent(int index, {int attempt = 0}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final itemHeight = _currentGridItemHeight;
        if (!_currentGridController.hasClients || itemHeight <= 0) {
          if (attempt < 5) {
            Future<void>.delayed(const Duration(milliseconds: 80), () {
              if (mounted) {
                _scheduleScrollToCurrent(index, attempt: attempt + 1);
              }
            });
          }
          return;
        }
        if (index < 0) return;

        const topPadding = 6.0;
        const mainAxisSpacing = 8.0;
        final row = index ~/ _currentGridColumns;
        final viewportHeight =
            _currentGridController.position.viewportDimension;
        final target =
            topPadding +
            row * (itemHeight + mainAxisSpacing) -
            (viewportHeight - itemHeight) / 2;
        final clamped = target.clamp(
          0.0,
          _currentGridController.position.maxScrollExtent,
        );
        _currentGridController.animateTo(
          clamped,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      });
    });
  }

  Future<void> _confirmDelete(ContinueWatchQueue queue) async {
    final l = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) => AppDialog(
        title: l.continueWatchDeleteTitle,
        message: queue.title,
        actionsAlignment: AppDialogActionsAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l.continueWatchDelete),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<ContinueWatchService>().delete(queue.id);
      if (mounted && _selectedQueueId == queue.id) {
        setState(() => _selectedQueueId = null);
      }
    }
  }

  Future<void> _renameQueue(ContinueWatchQueue queue) async {
    final l = AppLocalizations.of(context)!;
    final title = await showDialog<String>(
      context: context,
      builder: (_) => _RenameQueueDialog(
        initialTitle: queue.title,
        dialogTitle: l.continueWatchRename,
        fieldLabel: l.continueWatchQueueName,
        cancelLabel: l.commonCancel,
        saveLabel: l.continueWatchSave,
      ),
    );
    if (title != null && mounted) {
      await context.read<ContinueWatchService>().rename(queue.id, title);
    }
  }
}

class _ContinueWatchHeaderTitle extends StatelessWidget {
  static const _badgeGap = 4.0;

  final String firstLine;
  final String secondLine;
  final bool showProBadge;

  const _ContinueWatchHeaderTitle({
    required this.firstLine,
    required this.secondLine,
    required this.showProBadge,
  });

  @override
  Widget build(BuildContext context) {
    final hasSecondLine = secondLine.isNotEmpty;
    final firstLineText = Text(
      firstLine,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
    final secondLineText = Text(
      secondLine,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!showProBadge) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [firstLineText, if (hasSecondLine) secondLineText],
      );
    }

    final titleLineWithBadge = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        hasSecondLine ? secondLineText : firstLineText,
        const SizedBox(width: _badgeGap),
        Transform.translate(
          offset: const Offset(0, 1),
          child: Container(
            width: 34,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFE5484D),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'PRO',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ],
    );

    if (!hasSecondLine) return titleLineWithBadge;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [firstLineText, titleLineWithBadge],
    );
  }
}

class _RenameQueueDialog extends StatefulWidget {
  final String initialTitle;
  final String dialogTitle;
  final String fieldLabel;
  final String cancelLabel;
  final String saveLabel;

  const _RenameQueueDialog({
    required this.initialTitle,
    required this.dialogTitle,
    required this.fieldLabel,
    required this.cancelLabel,
    required this.saveLabel,
  });

  @override
  State<_RenameQueueDialog> createState() => _RenameQueueDialogState();
}

class _RenameQueueDialogState extends State<_RenameQueueDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialTitle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: widget.dialogTitle,
      message: '',
      actionsAlignment: AppDialogActionsAlignment.center,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(widget.cancelLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: Text(widget.saveLabel),
        ),
      ],
      child: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 60,
        cursorColor: Colors.white,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: widget.fieldLabel,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
          counterStyle: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.72)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }
}
