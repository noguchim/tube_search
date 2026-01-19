import 'package:flutter/material.dart';
import 'package:tube_search/widgets/repeat/repeat_preview_dialog.dart';

import '../../screens/video_player_screen.dart';
import '../../services/repeat_list_service.dart';
import '../app_dialog.dart';
import 'repeat_header_switch.dart';
import 'repeat_history_tab.dart';
import 'repeat_new_tab.dart';
import 'repeat_range_dialog.dart';
import 'repeat_types.dart';

class RepeatSettingsContent extends StatefulWidget {
  final List<Map<String, dynamic>> videos;
  final VoidCallback onClose;

  const RepeatSettingsContent({
    super.key,
    required this.videos,
    required this.onClose,
  });

  @override
  State<RepeatSettingsContent> createState() => _RepeatSettingsContentState();
}

class _RepeatSettingsContentState extends State<RepeatSettingsContent> {
  // ===== state =====
  late List<Map<String, dynamic>> workingList;
  late TextEditingController listNameController;

  RepeatTab currentTab = RepeatTab.newSetting;
  SortMode sortMode = SortMode.asc;

  bool useFullRange = true;
  int? startIndex, endIndex, startNo, endNo;

  String? editingId;

  static const repeatListLimit = 50;
  bool isLimitReached = false;

  final panelColor = const Color(0xFFE67E22);

  // ✅ Toast（BottomSheet内ステータス通知）
  String? _toastMessage;

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

    _checkLimit();
  }

  @override
  void dispose() {
    listNameController.dispose();
    super.dispose();
  }

  // ===========================
  // ✅ Toast表示（2秒で自動消滅）
  // ===========================
  void _showToast(String msg) {
    setState(() => _toastMessage = msg);

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      setState(() => _toastMessage = null);
    });
  }

  Widget _buildToastOverlay(BuildContext context) {
    if (_toastMessage == null) return const SizedBox.shrink();

    final theme = Theme.of(context);

    return Positioned(
      left: 16,
      right: 16,

      // ✅ ヘッダ直下っぽい位置（好みで調整）
      top: 450, // ← ここを調整してベスト位置に
      child: IgnorePointer(
        ignoring: true, // ✅ トーストはタップ邪魔しない
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: _toastMessage != null ? 1 : 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.dark
                    ? Colors.black.withValues(alpha: 0.55)
                    : Colors.white.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: theme.brightness == Brightness.dark
                      ? Colors.white.withValues(alpha: 0.14)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 1,
                ),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 14,
                    offset: Offset(0, 6),
                    color: Color(0x33000000),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.brightness == Brightness.dark
                        ? Colors.white.withValues(alpha: 0.85)
                        : Colors.black.withValues(alpha: 0.72),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _toastMessage!,
                      style: TextStyle(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white.withValues(alpha: 0.92)
                            : Colors.black.withValues(alpha: 0.88),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _checkLimit({bool showWarningDialog = true}) async {
    final lists = await RepeatListService.getLists();
    if (!mounted) return;

    final reached = lists.length >= repeatListLimit;

    setState(() => isLimitReached = reached);

    if (showWarningDialog && reached && editingId == null) {
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

  // ===== actions =====
  Future<void> _onChangeRangeMode(bool full) async {
    // ✅ 全て
    if (full) {
      setState(() {
        useFullRange = true;
        startIndex = endIndex = startNo = endNo = null;
      });
      return;
    }

    // ✅ すでに確定しているか？
    final hasConfirmedRange = startIndex != null &&
        endIndex != null &&
        startNo != null &&
        endNo != null;

    // ✅ 現状バックアップ（キャンセル時に復元できるように）
    final prevStartIndex = startIndex;
    final prevEndIndex = endIndex;
    final prevStartNo = startNo;
    final prevEndNo = endNo;

    final prevSortMode = sortMode;
    final prevWorkingList =
        workingList.map((e) => Map<String, dynamic>.from(e)).toList();

    final result = await showRepeatRangeDialog(
      context: context,
      initialList: workingList,
      initialSortMode: sortMode,
      startIndex: startIndex,
      endIndex: endIndex,
      startNo: startNo,
      endNo: endNo,
      accentColor: panelColor,
    );

    // ✅ キャンセル
    if (result == null) {
      setState(() {
        // ✅ 範囲指定チェックはONのままにしたい
        useFullRange = false;

        if (hasConfirmedRange) {
          // ✅ 確定済みあり：前回確定状態へ復元
          startIndex = prevStartIndex;
          endIndex = prevEndIndex;
          startNo = prevStartNo;
          endNo = prevEndNo;

          sortMode = prevSortMode;
          workingList = prevWorkingList;
        } else {
          // ✅ 初回キャンセル：未確定（範囲指定チェックON）
          startIndex = endIndex = startNo = endNo = null;
        }
      });
      return;
    }

    // ✅ 確定
    setState(() {
      useFullRange = false;

      workingList = result.workingList;
      sortMode = result.sortMode;

      startIndex = result.startIndex;
      endIndex = result.endIndex;
      startNo = result.startNo;
      endNo = result.endNo;
    });
  }

  bool _canSave() {
    return listNameController.text.trim().isNotEmpty &&
        (useFullRange || (startIndex != null && endIndex != null)) &&
        (editingId != null || !isLimitReached);
  }

  // -----------------------------
  // ✅ プレビュー統合
  // -----------------------------
  Future<void> _onPressPreview() async {
    if (!_canSave()) return;

    // ── 範囲補正 ──
    int fixedStartNo;
    int fixedEndNo;
    List<Map<String, dynamic>> queue;

    if (useFullRange) {
      fixedStartNo = 1;
      fixedEndNo = workingList.length;
      queue = List<Map<String, dynamic>>.from(workingList);
    } else {
      if (startIndex == null || endIndex == null) return;

      fixedStartNo = (workingList[startIndex!]["_originalNo"] as int);
      fixedEndNo = (workingList[endIndex!]["_originalNo"] as int);

      queue = workingList.sublist(startIndex!, endIndex! + 1);
    }

    final name = listNameController.text.trim();

    final sortLabel = {
      SortMode.asc: "昇順",
      SortMode.desc: "降順",
      SortMode.random: "ランダム",
    }[sortMode]!;

    final rangeLabel =
        useFullRange ? "全て" : "No.$fixedStartNo 〜 No.$fixedEndNo";

    // ✅ プレビューUI表示（外部化＋AppDialog）
    final action = await showRepeatPreviewDialog(
      context: context,
      accentColor: panelColor,
      info: RepeatPreviewInfo(
        name: name,
        sortLabel: sortLabel,
        rangeLabel: rangeLabel,
        firstVideoId: queue.isNotEmpty ? queue.first["id"] : null,
        firstVideoTitle: queue.isNotEmpty ? (queue.first["title"] ?? "") : "",
      ),
    );

    if (!mounted) return;
    if (action == null || action == PreviewAction.cancel) return;

    // ─────────────────────────────
    // 💾 保存（共通）
    // ─────────────────────────────
    if (editingId == null) {
      await RepeatListService.addDetailedList(
        name: name,
        startNo: fixedStartNo,
        endNo: fixedEndNo,
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
          "startNo": fixedStartNo,
          "endNo": fixedEndNo,
          "sortMode": sortMode.name,
          "allVideos": workingList,
          "queue": queue,
          "useFullRange": useFullRange,
        },
      );
    }

    if (!mounted) return;

    await _checkLimit(showWarningDialog: false);

    // ✅ 保存のみ
    if (action == PreviewAction.saveOnly) {
      _showToast("保存しました");
      return;
    }

    // ✅ 保存＆再生
    widget.onClose();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VideoPlayerScreen(
          video: queue.first,
          queue: queue,
          isRepeat: true,
        ),
      ),
    );
  }

  Future<void> _onEditItem(Map<String, dynamic> item) async {
    setState(() {
      editingId = item["id"];
      listNameController.text = item["name"];

      sortMode = SortMode.values.firstWhere(
        (m) => m.name == item["sortMode"],
        orElse: () => SortMode.asc,
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

        startIndex = workingList.indexWhere(
          (v) => v["_originalNo"] == startNo,
        );
        endIndex = workingList.indexWhere(
          (v) => v["_originalNo"] == endNo,
        );
      }

      currentTab = RepeatTab.newSetting;
    });
  }

  void _clearEditingKeepTab() {
    editingId = null;

    workingList = List.generate(
      widget.videos.length,
      (i) => {
        ...widget.videos[i],
        "_originalNo": i + 1,
      },
    );

    final now = DateTime.now();
    listNameController.text =
        "${now.year}/${now.month.toString().padLeft(2, '0')}/${now.day.toString().padLeft(2, '0')} "
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";

    sortMode = SortMode.asc;

    useFullRange = true;
    startIndex = endIndex = startNo = endNo = null;

    // ❗currentTabは変えない（履歴画面に留まる）
  }

  // ===== build =====
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ✅ いつものUI（ズレない）
        Column(
          children: [
            // header
            SizedBox(
              // height: 130,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end, // ✅ center → end
                  children: [
                    const Text(
                      "連続再生の設定",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 7),
                    RepeatHeaderSwitch(
                      currentTab: currentTab,
                      color: panelColor,
                      isEditing: editingId != null,
                      onChanged: (t) => setState(() => currentTab = t),
                    ),
                    // const SizedBox(height: 8), // ✅ 下余白は最小限に（0〜8で好み）
                  ],
                ),
              ),
            ),

            // content
            Expanded(
              child: currentTab == RepeatTab.newSetting
                  ? RepeatNewTab(
                      listNameController: listNameController,
                      onListNameChanged: (_) => setState(() {}),
                      useFullRange: useFullRange,
                      sortMode: sortMode,
                      startNo: startNo,
                      endNo: endNo,
                      isLimitReached: isLimitReached,
                      editingId: editingId,
                      panelColor: panelColor,
                      onTapAll: () => _onChangeRangeMode(true),
                      onTapRange: () async => _onChangeRangeMode(false),
                      canSave: _canSave,
                      onClosePanel: widget.onClose,
                      onPressPreview: _onPressPreview,
                    )
                  : RepeatHistoryTab(
                      panelColor: panelColor,
                      editingId: editingId,
                      onPlay: (queue) {
                        widget.onClose();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VideoPlayerScreen(
                              video: queue.first,
                              queue: queue,
                              isRepeat: true,
                            ),
                          ),
                        );
                      },
                      onEdit: _onEditItem,
                      onCancelEdit: () {
                        setState(() => _clearEditingKeepTab());
                        _showToast("編集中を解除しました");
                      },
                    ),
            ),
          ],
        ),

        // ✅ オーバーレイトースト（UIズレなし）
        _buildToastOverlay(context),
      ],
    );
  }
}
