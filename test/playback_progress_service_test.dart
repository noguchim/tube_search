import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tube_search/services/playback_progress_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('progress is restored by video id', () async {
    final service = PlaybackProgressService();
    await service.saveProgress(
      'video-a',
      progressSeconds: 42,
      durationSeconds: 120,
    );

    final restored = PlaybackProgressService();
    expect(await restored.resumeSeconds('video-a', durationSeconds: 120), 42);
    expect(
      restored.progressFractionSync('video-a', durationSeconds: 120),
      closeTo(0.35, 0.001),
    );
  });

  test('sessions shorter than ten seconds are not saved', () async {
    final service = PlaybackProgressService();
    await service.saveProgress(
      'video-a',
      progressSeconds: 9,
      durationSeconds: 120,
    );

    expect(await service.resumeSeconds('video-a', durationSeconds: 120), 0);
  });

  test(
    'progress within five seconds of completion restarts from zero',
    () async {
      final service = PlaybackProgressService();
      await service.saveProgress(
        'video-a',
        progressSeconds: 115,
        durationSeconds: 120,
      );

      expect(await service.resumeSeconds('video-a', durationSeconds: 120), 0);
    },
  );

  test('completed playback displays a full progress bar', () async {
    final service = PlaybackProgressService();
    await service.markCompleted('video-a', durationSeconds: 120);

    expect(service.progressFractionSync('video-a', durationSeconds: 120), 1);
  });

  test('entries older than thirty days are removed', () async {
    final expired = [
      {
        'videoId': 'video-a',
        'progressSeconds': 42,
        'durationSeconds': 120,
        'updatedAt': DateTime.now()
            .subtract(const Duration(days: 31))
            .toIso8601String(),
      },
    ];
    SharedPreferences.setMockInitialValues({
      PlaybackProgressService.storageKey: jsonEncode(expired),
    });

    final service = PlaybackProgressService();
    expect(await service.resumeSeconds('video-a', durationSeconds: 120), 0);
  });

  test('reset all clears replay progress', () async {
    final service = PlaybackProgressService();
    await service.saveProgress(
      'video-a',
      progressSeconds: 42,
      durationSeconds: 120,
    );
    await service.saveProgress(
      'video-b',
      progressSeconds: 64,
      durationSeconds: 120,
    );

    await service.resetAll(['video-a', 'video-b']);

    expect(await service.resumeSeconds('video-a'), 0);
    expect(await service.resumeSeconds('video-b'), 0);
  });
}
