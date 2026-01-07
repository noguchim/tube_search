import 'package:flutter/material.dart';

import '../screens/video_player_screen.dart';
import '../services/repeat_list_service.dart';
import 'app_dialog.dart';

Future<void> showRepeatSettingsPanel({
  required BuildContext context,
  required List<Map<String, dynamic>> videos,
}) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.90,
        minChildSize: 0.55,
        maxChildSize: 0.98,
        builder: (_, controller) {
          final theme = Theme.of(context);

          return Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: theme.dividerColor.withValues(alpha: .6),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _RepeatSettingsContent(
                      videos: videos,
                      onClose: () => Navigator.pop(sheetContext),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _RepeatSettingsContent extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final VoidCallback onClose;

  const _RepeatSettingsContent({
    required this.videos,
    required this.onClose,
  });

  @override
  State<_RepeatSettingsContent> createState() => _RepeatSettingsContentState();
}

enum SortMode { asc, desc, random }

class _RepeatSettingsContentState extends State<_RepeatSettingsContent> {
  late List<Map<String, dynamic>> workingList;

  int? startIndex;
  int? endIndex;
  int? startNo;
  int? endNo;

  late TextEditingController listNameController;

  SortMode sortMode = SortMode.asc;
  String? editingId;
  bool useFullRange = true;
  static const int repeatListLimit = 1;
  bool _isLimitReached = false;

  @override
  void initState() {
    super.initState();

    workingList = List.generate(
      widget.videos.length,
      (i) => {
        ...widget.videos[i],
        "_originalNo": i + 1,
      },
    );

    final now = DateTime.now();
    listNameController = TextEditingController(
      text:
          "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} "
          "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}",
    );

    _checkRepeatListLimit();
  }

  Future<void> _checkRepeatListLimit({bool showWarningDialog = true}) async {
    final lists = await RepeatListService.getLists();
    final reached = lists.length >= repeatListLimit;

    if (!mounted) return;

    // ★★★ UI を更新するのは必ず setState() の中で！
    setState(() {
      _isLimitReached = reached;
    });

    if (showWarningDialog && reached) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          builder: (_) => AppDialog(
            title: "保存上限に達しました",
            style: AppDialogStyle.info,
            message: "連続再生リストは最大 $repeatListLimit 件まで保存できます。\n\n"
                "新しく保存する場合は、不要なリストを削除してください。",
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
    }
  }

  // ------------------ 新規設定タブ ------------------

  Widget _buildNewTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 15),

        Row(
          children: [
            const Text("リスト名", style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: listNameController,
                decoration: const InputDecoration(
                  hintText: "連続再生リスト名を入力",
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // 再生範囲
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text("再生範囲",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Radio(
                  value: true,
                  groupValue: useFullRange,
                  fillColor: MaterialStateProperty.all(const Color(0xFF22C55E)),
                  // 緑
                  onChanged: (_) {
                    setState(() {
                      useFullRange = true;
                      startIndex = endIndex = startNo = endNo = null;
                    });
                  },
                ),
                Text("全て",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
                Radio(
                  value: false,
                  groupValue: useFullRange,
                  fillColor: MaterialStateProperty.all(const Color(0xFF22C55E)),
                  // 緑
                  onChanged: (_) => setState(() => useFullRange = false),
                ),
                Text("範囲指定",
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    )),
              ],
            ),
            if (!useFullRange) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("開始：",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  _labelBox(startNo == null ? "-" : "No.$startNo"),
                  const SizedBox(width: 12),
                  Text("〜",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  const SizedBox(width: 12),
                  Text("終了：",
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                      )),
                  _labelBox(endNo == null ? "-" : "No.$endNo"),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lightbulb, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    "一覧から開始と終了をタップしてください",
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            ],
          ],
        ),

        const SizedBox(height: 5),

        _buildSortButtons(),
        const SizedBox(height: 10),

        Expanded(
          child: useFullRange
              ? const SizedBox() // ← 空のスペースだけ確保
              : _buildVideoList(), // ← 範囲指定のときだけ表示
        ),

        _buildBottomButtons(),
      ],
    );
  }

  Widget _labelBox(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).dividerColor,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(text),
      );

  // ------------------ 並び替え ------------------

  Widget _buildSortButtons() => Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text("昇順"),
            selected: sortMode == SortMode.asc,
            selectedColor: const Color(0xFF22C55E),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: sortMode == SortMode.asc
                  ? Colors.black87
                  : Theme.of(context).colorScheme.onSurface,
            ),
            side: BorderSide(
              color: sortMode == SortMode.asc
                  ? Colors.transparent
                  : Theme.of(context).dividerColor,
            ),
            onSelected: (_) {
              setState(() {
                sortMode = SortMode.asc;
                workingList.sort(
                  (a, b) =>
                      (a["_originalNo"] as int).compareTo(b["_originalNo"]),
                );
                startIndex = endIndex = startNo = endNo = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("降順"),
            selected: sortMode == SortMode.desc,
            selectedColor: const Color(0xFF22C55E),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: sortMode == SortMode.desc
                  ? Colors.black87
                  : Theme.of(context).colorScheme.onSurface,
            ),
            side: BorderSide(
              color: sortMode == SortMode.desc
                  ? Colors.transparent
                  : Theme.of(context).dividerColor,
            ),
            onSelected: (_) {
              setState(() {
                sortMode = SortMode.desc;
                workingList.sort((a, b) =>
                    (b["_originalNo"] as int).compareTo(a["_originalNo"]));
                startIndex = endIndex = startNo = endNo = null;
              });
            },
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text("ランダム"),
            selected: sortMode == SortMode.random,
            selectedColor: const Color(0xFF22C55E),
            labelStyle: TextStyle(
              fontWeight: FontWeight.w600,
              color: sortMode == SortMode.random
                  ? Colors.black87
                  : Theme.of(context).colorScheme.onSurface,
            ),
            side: BorderSide(
              color: sortMode == SortMode.random
                  ? Colors.transparent
                  : Theme.of(context).dividerColor,
            ),
            onSelected: (_) {
              setState(() {
                sortMode = SortMode.random;
                workingList.shuffle();
                startIndex = endIndex = startNo = endNo = null;
              });
            },
          ),
        ],
      );

  // ------------------ 一覧 ------------------

  Widget _buildVideoList() => ListView.builder(
        itemCount: workingList.length,
        itemBuilder: (_, index) {
          final video = workingList[index];
          final selected = startIndex != null &&
              endIndex != null &&
              index >= startIndex! &&
              index <= endIndex!;

          return ListTile(
            dense: true,
            visualDensity: const VisualDensity(vertical: -2),
            tileColor: selected ? Colors.red.withValues(alpha: .08) : null,
            leading: Text(
              "${video["_originalNo"]}",
              style: const TextStyle(fontSize: 16),
            ),
            title: Text(
              video["title"] ?? "",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: useFullRange
                ? null
                : () {
                    setState(() {
                      final no = video["_originalNo"] as int;

                      if (startIndex == null) {
                        startIndex = index;
                        startNo = no;
                      } else if (endIndex == null) {
                        if (index < startIndex!) return;
                        endIndex = index;
                        endNo = no;
                      } else {
                        startIndex = index;
                        startNo = no;
                        endIndex = endNo = null;
                      }
                    });
                  },
          );
        },
      );

  // ------------------ 保存 ------------------

  Widget _buildBottomButtons() {
    final isEditing = editingId != null;
    print("limit? $_isLimitReached  editingId=$editingId");

    final canSave = listNameController.text.trim().isNotEmpty &&
        (useFullRange || (startIndex != null && endIndex != null)) &&
        (isEditing // ← 編集中なら OK
            ||
            !_isLimitReached // ← 新規保存時のみ上限チェック
        );

    return SafeArea(
      top: false,
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                setState(() => editingId = null);
                widget.onClose();
              },
              child: Text("キャンセル",
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                  )),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: !canSave
                  ? null
                  : () async {
                      if (useFullRange) {
                        startNo = 1;
                        endNo = workingList.length;
                      }

                      final queue = useFullRange
                          ? List<Map<String, dynamic>>.from(workingList)
                          : workingList.sublist(startIndex!, endIndex! + 1);

                      final name = listNameController.text.trim();

                      if (editingId == null) {
                        await RepeatListService.addDetailedList(
                          name: name,
                          startNo: startNo!,
                          endNo: endNo!,
                          sortMode: sortMode.name,
                          allVideos: workingList,
                          queue: queue,
                          useFullRange: useFullRange,
                        );
                      } else {
                        await RepeatListService.updateById(
                          editingId!,
                          {
                            "name": name,
                            "startNo": startNo!,
                            "endNo": endNo!,
                            "sortMode": sortMode.name,
                            "allVideos": workingList,
                            "queue": queue,
                            "useFullRange": useFullRange,
                          },
                        );
                      }

                      if (!mounted) return;

                      Navigator.pop(context);

                      Future.microtask(() {
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
                      });
                    },
              child: const Text("動画再生画面へ"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSavedTab(BuildContext tabContext) {
    return FutureBuilder(
      future: RepeatListService.getLists(),
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lists = snapshot.data!;

        // ⭐ 0件 → これまで通り
        if (lists.isEmpty) {
          return const Center(child: Text("保存された連続再生リストはありません"));
        }

        // ⭐ 1件以上 → 先頭にカウンターを追加
        return ListView.separated(
          itemCount: lists.length + 1, // ← 先頭1行ぶん追加
          separatorBuilder: (_, index) =>
              index == 0 ? const SizedBox() : const Divider(height: 1),

          itemBuilder: (_, index) {
            // ─── 0行目：カウンター ───
            if (index == 0) {
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.04)
                      : const Color(0xFFE4E8EC),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      "登録件数：${lists.length} / $repeatListLimit件",
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }

            // ─── それ以降：通常ListTile（index - 1 に注意） ───
            final item = lists[index - 1];

            final queue = (item["queue"] as List)
                .map<Map<String, dynamic>>(
                    (e) => Map<String, dynamic>.from(e as Map))
                .toList();

            final sortModeName = (() {
              switch (item["sortMode"]) {
                case "asc":
                  return "昇順";
                case "desc":
                  return "降順";
                case "random":
                  return "ランダム";
                default:
                  return "-";
              }
            })();

            final rangeLabel = (item["useFullRange"] == true)
                ? "全て"
                : "No.${item["startNo"]}〜No.${item["endNo"]}";

            return ListTile(
              title: Text(item["name"]),
              subtitle: Text(
                "${queue.length} 本の動画, $sortModeName, $rangeLabel",
              ),
              onTap: () {
                Navigator.pop(context);
                Future.microtask(() {
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
                });
              },
              trailing: editingId == item["id"]
                  ? Builder(
                      builder: (context) {
                        final theme = Theme.of(context);
                        final primary = theme.colorScheme.primary;
                        final isDark = theme.brightness == Brightness.dark;

                        final bgColor = isDark
                            ? primary.withValues(alpha: 0.18)
                            : primary; // ★
                        final textColor = isDark ? primary : Colors.white; // ★
                        final borderColor = isDark
                            ? primary.withValues(alpha: 0.6)
                            : Colors.transparent; // ★

                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: borderColor),
                          ),
                          child: Text(
                            "編集中",
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    )
                  : PopupMenuButton(
                      onSelected: (value) async {
                        if (value == "edit") {
                          _onEditSavedList(tabContext, item);
                        } else if (value == "delete") {
                          await RepeatListService.deleteById(item["id"]);

                          // ⭐ 削除後に上限チェックを更新
                          await _checkRepeatListLimit(showWarningDialog: false);

                          setState(() {});
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: "edit", child: Text("編集")),
                        PopupMenuItem(value: "delete", child: Text("削除")),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  void _onEditSavedList(
    BuildContext tabContext,
    Map<String, dynamic> item,
  ) {
    setState(() {
      editingId = item["id"];
      listNameController.text = item["name"];

      sortMode = SortMode.values.firstWhere(
        (m) => m.name == item["sortMode"],
      );

      workingList = (item["allVideos"] as List)
          .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e as Map))
          .toList();

      useFullRange = item["useFullRange"] ?? true;

      if (useFullRange) {
        startIndex = endIndex = startNo = endNo = null;
      } else {
        startNo = item["startNo"];
        endNo = item["endNo"];

        startIndex = workingList.indexWhere((v) => v["_originalNo"] == startNo);
        endIndex = workingList.indexWhere((v) => v["_originalNo"] == endNo);
      }
    });

    DefaultTabController.of(tabContext).animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Text("連続再生の設定", style: TextStyle(fontWeight: FontWeight.bold)),
          TabBar(
            indicatorColor: const Color(0xFF22C55E), // 緑
            labelColor: const Color(0xFF22C55E),
            unselectedLabelColor:
                Theme.of(context).colorScheme.onSurface.withOpacity(.5),
            tabs: const [
              Tab(text: "新規設定"),
              Tab(text: "設定履歴"),
            ],
          ),
          Expanded(
            child: Builder(
              builder: (tabContext) => TabBarView(
                children: [_buildNewTab(), _buildSavedTab(tabContext)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
