import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tube_search/screens/video_player_screen.dart';

import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../utils/app_logger.dart';
import '../widgets/custom_glass_app_bar.dart';

enum RepeatUIType {
  off,
  ascending,
  descending,
  random,
}

class RepeatSettingsScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? allVideos;

  const RepeatSettingsScreen({
    super.key,
    this.allVideos,
  });

  @override
  State<RepeatSettingsScreen> createState() => _RepeatSettingsScreenState();
}

class _RepeatSettingsScreenState extends State<RepeatSettingsScreen> {
  bool enabled = false;
  RepeatUIType mode = RepeatUIType.ascending;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;
    final isDark = theme.brightness == Brightness.dark;
    final themeProvider = context.watch<ThemeProvider>();
    final t = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            expandedHeight: 70,
            flexibleSpace: CustomGlassAppBar(
              title: t.repeatSettingsTitle,
            ),
          ),

          // 内容
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🔹 連続再生 ON/OFF
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "連続再生",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: onSurface,
                        ),
                      ),
                      Switch(
                        value: enabled,
                        onChanged: (v) {
                          setState(() => enabled = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // 🔹 再生方法プルダウン
                  Text(
                    "再生方法",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: onSurface,
                    ),
                  ),

                  const SizedBox(height: 6),

                  DropdownButtonFormField<RepeatUIType>(
                    value: mode,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: RepeatUIType.ascending,
                        child: Text("昇順で再生"),
                      ),
                      DropdownMenuItem(
                        value: RepeatUIType.descending,
                        child: Text("降順で再生"),
                      ),
                      DropdownMenuItem(
                        value: RepeatUIType.random,
                        child: Text("ランダム再生"),
                      ),
                    ],
                    onChanged:
                        enabled ? (v) => setState(() => mode = v!) : null,
                  ),

                  const SizedBox(height: 24),

                  // 🔘 連続再生開始ボタン
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: enabled
                          ? () {
                              final all = widget.allVideos ?? [];

                              if (all.length <= 9) {
                                logger.w("⚠️ allVideos が 10 件未満のため、キュー生成せず");
                                return;
                              }

                              // ⭐ 10件目(= index 9) から最後まで
                              final queue = all.sublist(17);

                              logger.i(
                                  "🎬 Queue created (10th → end): len=${queue.length}");

                              for (var v in queue) {
                                logger.i("title:${v["title"]}");
                                logger.i(
                                    "durationSeconds:${v["durationSeconds"]}");
                              }

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VideoPlayerScreen(
                                    video: queue[0],
                                    queue: queue,
                                    isRepeat: true,
                                  ),
                                ),
                              );
                            }
                          : null,
                      child: const Text("連続再生開始"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
