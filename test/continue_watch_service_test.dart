import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/data/continue_watch_queue.dart';
import 'package:tube_search/data/youtube_video.dart';
import 'package:tube_search/services/continue_watch_service.dart';

YouTubeVideo _video(
  String id, {
  int? durationSeconds = 120,
  bool isLive = false,
}) {
  return YouTubeVideo(
    id: id,
    title: 'Video $id',
    thumbnailUrl: 'https://example.com/$id.jpg',
    channelTitle: 'Channel',
    durationSeconds: durationSeconds,
    isLive: isLive,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('duration missing and live videos are excluded', () {
    expect(ContinueWatchService.isEligibleVideo(_video('normal')), isTrue);
    expect(
      ContinueWatchService.isEligibleVideo(
        _video('missing', durationSeconds: null),
      ),
      isFalse,
    );
    expect(
      ContinueWatchService.isEligibleVideo(_video('live', isLive: true)),
      isFalse,
    );
  });

  test('queue keeps a snapshot and removes duplicate video ids', () async {
    final service = ContinueWatchService();
    final queue = await service.createQueue(
      title: 'Popular',
      sourceType: 'popular',
      videos: [_video('a'), _video('a'), _video('b', durationSeconds: null)],
    );

    expect(queue.items, hasLength(2));
    expect(queue.items.first.selected, isTrue);
    expect(queue.items.last.selected, isFalse);
    expect(queue.items.last.status, ContinueWatchItemStatus.excluded);

    final restored = ContinueWatchService();
    await restored.load();
    expect(restored.queues.single.items, hasLength(2));
    expect(restored.activeQueue?.title, 'Popular');
  });

  test('select all only changes eligible items and persists', () async {
    final service = ContinueWatchService();
    final queue = await service.createQueue(
      title: 'Popular',
      sourceType: 'popular',
      videos: [
        _video('a'),
        _video('b'),
        _video('excluded', durationSeconds: null),
      ],
    );

    await service.setAllItemsSelected(queue.id, false);
    expect(queue.items.map((item) => item.selected), [false, false, false]);

    await service.setAllItemsSelected(queue.id, true);
    expect(queue.items.map((item) => item.selected), [true, true, false]);

    final restored = ContinueWatchService();
    await restored.load();
    expect(restored.queues.single.items.map((item) => item.selected), [
      true,
      true,
      false,
    ]);
  });

  test('free users can save up to ten playlists', () async {
    final service = ContinueWatchService();

    for (var i = 0; i < ContinueWatchService.freeQueueLimit; i++) {
      await service.createQueue(
        title: 'Queue $i',
        sourceType: 'popular',
        videos: [_video('video-$i')],
      );
    }

    expect(service.maxSavedQueues, ContinueWatchService.freeQueueLimit);
    expect(service.queues, hasLength(ContinueWatchService.freeQueueLimit));
    expect(
      () => service.createQueue(
        title: 'Queue over limit',
        sourceType: 'popular',
        videos: [_video('video-over-limit')],
      ),
      throwsA(isA<ContinueWatchQueueLimitException>()),
    );
  });

  test('pro users can save up to thirty playlists', () async {
    final service = ContinueWatchService(proEnabled: true);

    for (var i = 0; i < ContinueWatchService.proQueueLimit; i++) {
      await service.createQueue(
        title: 'Queue $i',
        sourceType: 'popular',
        videos: [_video('video-$i')],
      );
    }

    expect(service.maxSavedQueues, ContinueWatchService.proQueueLimit);
    expect(service.queues, hasLength(ContinueWatchService.proQueueLimit));
    expect(
      () => service.createQueue(
        title: 'Queue over limit',
        sourceType: 'popular',
        videos: [_video('video-over-limit')],
      ),
      throwsA(isA<ContinueWatchQueueLimitException>()),
    );
  });

  test('completed queue remains in history and can be restarted', () async {
    final service = ContinueWatchService();
    final queue = await service.createQueue(
      title: 'Search',
      sourceType: 'search',
      videos: [_video('a')],
    );

    final next = await service.markCompletedAndFindNext(queue.id, 0);
    expect(next, isNull);
    expect(service.queues, hasLength(1));
    expect(queue.status, ContinueWatchQueueStatus.completed);

    await service.restart(queue.id);
    expect(queue.status, ContinueWatchQueueStatus.ready);
    expect(queue.items.single.progressSeconds, 0);
    expect(queue.items.single.status, ContinueWatchItemStatus.pending);
  });

  test('completed queue selects its first checked item', () async {
    final service = ContinueWatchService();
    final queue = await service.createQueue(
      title: 'Search',
      sourceType: 'search',
      videos: [_video('a'), _video('b'), _video('c')],
    );
    await service.toggleItem(queue.id, 0);

    expect(await service.markCompletedAndFindNext(queue.id, 1), 2);
    expect(await service.markCompletedAndFindNext(queue.id, 2), isNull);

    expect(queue.status, ContinueWatchQueueStatus.completed);
    expect(queue.currentIndex, 1);
    expect(service.previousPlayable(queue.id, queue.currentIndex), isNull);
  });

  test('explicit playback restarts a completed item', () async {
    final service = ContinueWatchService();
    final queue = await service.createQueue(
      title: 'Popular',
      sourceType: 'popular',
      videos: [_video('a')],
    );

    await service.markCompletedAndFindNext(queue.id, 0);
    final restarted = await service.prepareExplicitPlayback(queue.id, 0);

    expect(restarted, isTrue);
    expect(queue.status, ContinueWatchQueueStatus.ready);
    expect(queue.currentIndex, 0);
    expect(queue.items.single.progressSeconds, 0);
    expect(queue.items.single.status, ContinueWatchItemStatus.pending);
  });

  test(
    'replaying a completed queue resets checked items from current',
    () async {
      final service = ContinueWatchService();
      final queue = await service.createQueue(
        title: 'Popular',
        sourceType: 'popular',
        videos: [_video('a'), _video('b'), _video('c')],
      );

      await service.markCompletedAndFindNext(queue.id, 0);
      await service.markCompletedAndFindNext(queue.id, 1);
      await service.markCompletedAndFindNext(queue.id, 2);
      final restarted = await service.prepareExplicitPlayback(queue.id, 0);

      expect(restarted, isTrue);
      expect(queue.status, ContinueWatchQueueStatus.ready);
      for (final item in queue.items) {
        expect(item.progressSeconds, 0);
        expect(item.status, ContinueWatchItemStatus.pending);
      }
    },
  );

  test(
    'explicit playback restarts an item within five seconds of the end',
    () async {
      final service = ContinueWatchService();
      final queue = await service.createQueue(
        title: 'Popular',
        sourceType: 'popular',
        videos: [_video('a')],
      );

      await service.markPaused(queue.id, 0, progressSeconds: 115);
      final restarted = await service.prepareExplicitPlayback(queue.id, 0);

      expect(restarted, isTrue);
      expect(queue.items.single.progressSeconds, 0);
      expect(queue.items.single.status, ContinueWatchItemStatus.pending);
    },
  );

  test('explicit playback preserves ordinary paused progress', () async {
    final service = ContinueWatchService();
    final queue = await service.createQueue(
      title: 'Popular',
      sourceType: 'popular',
      videos: [_video('a')],
    );

    await service.markPaused(queue.id, 0, progressSeconds: 60);
    final restarted = await service.prepareExplicitPlayback(queue.id, 0);

    expect(restarted, isFalse);
    expect(queue.status, ContinueWatchQueueStatus.paused);
    expect(queue.items.single.progressSeconds, 60);
    expect(queue.items.single.status, ContinueWatchItemStatus.paused);
  });
}
