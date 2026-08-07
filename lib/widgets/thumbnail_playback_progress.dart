import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/playback_progress_service.dart';

class ThumbnailPlaybackProgress extends StatelessWidget {
  final String videoId;
  final int? durationSeconds;

  const ThumbnailPlaybackProgress({
    super.key,
    required this.videoId,
    required this.durationSeconds,
  });

  @override
  Widget build(BuildContext context) {
    final progress = context
        .watch<PlaybackProgressService>()
        .progressFractionSync(videoId, durationSeconds: durationSeconds);
    if (progress <= 0) return const SizedBox.shrink();

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
        child: LinearProgressIndicator(
          value: progress,
          minHeight: 5,
          backgroundColor: const Color(0xFFA6A6A6),
          color: const Color(0xFFFF3B30),
        ),
      ),
    );
  }
}
