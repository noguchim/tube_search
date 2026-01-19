// import 'package:flutter/material.dart';
//
// import '../../services/repeat_list_service.dart';
//
// class RepeatHistoryTab extends StatefulWidget {
//   final Color panelColor;
//
//   final void Function(List<Map<String, dynamic>> queue) onPlay;
//   final Future<void> Function(Map<String, dynamic> item) onEdit;
//
//   // ✅ 親から渡される「編集中ID」
//   final String? editingId;
//
//   // ✅ 編集解除
//   final VoidCallback onCancelEdit;
//
//   const RepeatHistoryTab({
//     super.key,
//     required this.panelColor,
//     required this.onPlay,
//     required this.onEdit,
//     required this.editingId,
//     required this.onCancelEdit,
//   });
//
//   @override
//   State<RepeatHistoryTab> createState() => _RepeatHistoryTabState();
// }
//
// class _RepeatHistoryTabState extends State<RepeatHistoryTab> {
//   static const int repeatListLimit = 50;
//
//   late Future<List<Map<String, dynamic>>> _future;
//
//   @override
//   void initState() {
//     super.initState();
//     _future = RepeatListService.getLists();
//   }
//
//   // 削除した時だけ _future を更新して setState
//   Future<void> _delete(String id) async {
//     await RepeatListService.deleteById(id);
//     if (!mounted) return;
//     setState(() => _future = RepeatListService.getLists());
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     final isDark = theme.brightness == Brightness.dark;
//
//     return FutureBuilder<List<Map<String, dynamic>>>(
//       future: _future,
//       builder: (_, snapshot) {
//         if (!snapshot.hasData) {
//           return const Center(child: CircularProgressIndicator());
//         }
//
//         final lists = snapshot.data!;
//
//         if (lists.isEmpty) {
//           return const Center(child: Text("保存された連続再生リストはありません"));
//         }
//
//         return ListView.builder(
//           padding: EdgeInsets.zero,
//           itemCount: lists.length + 2,
//           itemBuilder: (_, index) {
//             // 0行目：カウンター帯
//             if (index == 0) {
//               return Container(
//                 width: double.infinity,
//                 padding:
//                     const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
//                 decoration: BoxDecoration(
//                   color: isDark
//                       ? Colors.white.withValues(alpha: 0.06)
//                       : const Color(0xFFE4E8EC),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.end,
//                   children: [
//                     Text(
//                       "登録件数：${lists.length} / $repeatListLimit件",
//                       style: TextStyle(
//                         color:
//                             theme.colorScheme.onSurface.withValues(alpha: 0.8),
//                         fontSize: 13,
//                         fontWeight: FontWeight.w500,
//                       ),
//                     ),
//                   ],
//                 ),
//               );
//             }
//
//             // ✅ 最終行：SafeArea余白
//             if (index == lists.length + 1) {
//               return const SafeArea(
//                 top: false,
//                 child: SizedBox(height: 40),
//               );
//             }
//
//             // 実データ
//             final item = lists[index - 1];
//
//             final itemId = item["id"]?.toString();
//             final isEditing =
//                 itemId != null && itemId == widget.editingId; // ✅ 判定
//
//             final queue = (item["queue"] as List)
//                 .map<Map<String, dynamic>>(
//                     (e) => Map<String, dynamic>.from(e as Map))
//                 .toList();
//
//             final sortModeName = (() {
//               switch (item["sortMode"]) {
//                 case "asc":
//                   return "昇順";
//                 case "desc":
//                   return "降順";
//                 case "random":
//                   return "ランダム";
//                 default:
//                   return "-";
//               }
//             })();
//
//             final rangeLabel = (item["useFullRange"] == true)
//                 ? "全て"
//                 : "No.${item["startNo"]}〜No.${item["endNo"]}";
//
//             final String? firstId =
//                 queue.isNotEmpty ? queue.first["id"]?.toString() : null;
//
//             final thumbUrl = (firstId == null)
//                 ? null
//                 : "https://i.ytimg.com/vi/$firstId/hqdefault.jpg";
//
//             return Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
//               child: ClipRRect(
//                 borderRadius: BorderRadius.circular(18),
//                 child: Material(
//                   color: theme.cardTheme.color ?? theme.colorScheme.surface,
//
//                   // ✅ ここ重要：カード全体の onTap を無効化
//                   child: SizedBox(
//                     height: 220,
//                     child: Stack(
//                       fit: StackFit.expand,
//                       children: [
//                         // 背景サムネ
//                         if (thumbUrl != null)
//                           Image.network(
//                             thumbUrl,
//                             fit: BoxFit.cover,
//                             errorBuilder: (_, __, ___) => const ColoredBox(
//                               color: Color(0xFFE5E7EB),
//                             ),
//                           )
//                         else
//                           const ColoredBox(color: Color(0xFFE5E7EB)),
//
//                         // 黒透過マスク
//                         Container(
//                           color: Colors.black.withValues(alpha: 0.45),
//                         ),
//
//                         // 情報
//                         Padding(
//                           padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               // 1行目：リスト名＋メニュー or 編集中バッジ
//                               Row(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Expanded(
//                                     child: Text(
//                                       item["name"] ?? "",
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                       style: const TextStyle(
//                                         fontSize: 15,
//                                         fontWeight: FontWeight.w800,
//                                         color: Colors.white,
//                                         height: 1.15,
//                                       ),
//                                     ),
//                                   ),
//                                   if (isEditing)
//                                     _editingBadge(
//                                       onTap: widget.onCancelEdit,
//                                     )
//                                   else
//                                     PopupMenuButton<String>(
//                                       icon: const Icon(
//                                         Icons.more_vert,
//                                         color: Colors.white,
//                                       ),
//                                       onSelected: (value) async {
//                                         if (value == "edit") {
//                                           await widget.onEdit(item);
//                                         }
//                                         if (value == "delete") {
//                                           await _delete(item["id"]);
//                                         }
//                                       },
//                                       itemBuilder: (_) => const [
//                                         PopupMenuItem(
//                                           value: "edit",
//                                           child: Text("編集"),
//                                         ),
//                                         PopupMenuItem(
//                                           value: "delete",
//                                           child: Text("削除"),
//                                         ),
//                                       ],
//                                     ),
//                                 ],
//                               ),
//
//                               const Spacer(),
//
//                               // 2行目：情報テキスト
//                               Text(
//                                 "${queue.length} 本・$sortModeName・$rangeLabel",
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                                 style: const TextStyle(
//                                   fontSize: 12.5,
//                                   fontWeight: FontWeight.w600,
//                                   color: Colors.white,
//                                 ),
//                               ),
//
//                               const SizedBox(height: 6),
//
//                               // 3行目：小バッジ
//                               Row(
//                                 children: [
//                                   _miniBadge(text: sortModeName),
//                                   const SizedBox(width: 8),
//                                   _miniBadge(text: rangeLabel),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//
//                         // ✅ 右下：再生ボタン（ここだけタップ可能）
//                         Positioned(
//                           right: 12,
//                           bottom: 10,
//                           child: InkWell(
//                             borderRadius: BorderRadius.circular(999),
//                             onTap: () => widget.onPlay(queue),
//                             child: Container(
//                               padding: const EdgeInsets.all(8),
//                               decoration: BoxDecoration(
//                                 color: Colors.black.withValues(alpha: 0.35),
//                                 borderRadius: BorderRadius.circular(999),
//                                 border: Border.all(
//                                   color: Colors.white.withValues(alpha: 0.25),
//                                   width: 1,
//                                 ),
//                               ),
//                               child: const Icon(
//                                 Icons.play_arrow_rounded,
//                                 size: 22,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 ),
//               ),
//             );
//           },
//         );
//       },
//     );
//   }
//
//   Widget _editingBadge({required VoidCallback onTap}) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(999),
//       child: Container(
//         margin: const EdgeInsets.only(left: 6),
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: Colors.white.withValues(alpha: 0.18),
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(
//             color: Colors.white.withValues(alpha: 0.30),
//             width: 1,
//           ),
//         ),
//         child: const Text(
//           "編集中",
//           style: TextStyle(
//             fontSize: 11.5,
//             fontWeight: FontWeight.w800,
//             color: Colors.white,
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _miniBadge({required String text}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
//       decoration: BoxDecoration(
//         color: Colors.white.withValues(alpha: 0.18),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(
//           color: Colors.white.withValues(alpha: 0.30),
//           width: 1,
//         ),
//       ),
//       child: Text(
//         text,
//         style: const TextStyle(
//           fontSize: 11.5,
//           fontWeight: FontWeight.w700,
//           color: Colors.white,
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';

import '../../services/repeat_list_service.dart';

class RepeatHistoryTab extends StatefulWidget {
  final Color panelColor;

  final void Function(List<Map<String, dynamic>> queue) onPlay;
  final Future<void> Function(Map<String, dynamic> item) onEdit;

  // ✅ 親から渡される「編集中ID」
  final String? editingId;

  // ✅ 編集解除
  final VoidCallback onCancelEdit;

  const RepeatHistoryTab({
    super.key,
    required this.panelColor,
    required this.onPlay,
    required this.onEdit,
    required this.editingId,
    required this.onCancelEdit,
  });

  @override
  State<RepeatHistoryTab> createState() => _RepeatHistoryTabState();
}

class _RepeatHistoryTabState extends State<RepeatHistoryTab> {
  static const int repeatListLimit = 50;

  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = RepeatListService.getLists();
  }

  void _reload() {
    final f = RepeatListService.getLists(); // ✅ Futureは先に作る
    setState(() {
      _future = f; // ✅ setState内は同期代入のみ
    });
  }

  Future<void> _delete(String id) async {
    await RepeatListService.deleteById(id);
    if (!mounted) return;
    _reload(); // ✅ 即反映
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _future, // ✅ キャッシュFutureを使用
      builder: (_, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lists = snapshot.data!;
        if (lists.isEmpty) {
          return const Center(child: Text("保存された連続再生リストはありません"));
        }

        return Column(
          children: [
            // ✅ ヘッダ直下・全幅の帯（スクロールしない）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.06)
                    : const Color(0xFFE4E8EC),
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    "登録件数：${lists.length} / $repeatListLimit件",
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // ✅ ここから下だけスクロール
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  top: 0,
                  bottom: 16 + bottomInset,
                ),
                itemCount: lists.length,
                itemBuilder: (_, index) {
                  final item = lists[index];

                  final itemId = item["id"]?.toString();
                  final isEditing =
                      itemId != null && itemId == widget.editingId;

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

                  final String? firstId =
                      queue.isNotEmpty ? queue.first["id"]?.toString() : null;

                  final thumbUrl = (firstId == null)
                      ? null
                      : "https://i.ytimg.com/vi/$firstId/hqdefault.jpg";

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Material(
                        color:
                            theme.cardTheme.color ?? theme.colorScheme.surface,
                        child: SizedBox(
                          height: 220,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              if (thumbUrl != null)
                                Image.network(
                                  thumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                      const ColoredBox(
                                          color: Color(0xFFE5E7EB)),
                                )
                              else
                                const ColoredBox(color: Color(0xFFE5E7EB)),

                              Container(
                                  color: Colors.black.withValues(alpha: 0.45)),

                              // （以下、今のカード中身そのまま）
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(14, 12, 10, 12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            item["name"] ?? "",
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                              height: 1.15,
                                            ),
                                          ),
                                        ),
                                        if (isEditing)
                                          _editingBadge(
                                              onTap: widget.onCancelEdit)
                                        else
                                          PopupMenuButton<String>(
                                            icon: const Icon(
                                              Icons.more_vert,
                                              color: Colors.white,
                                            ),
                                            onSelected: (value) async {
                                              if (value == "edit") {
                                                await widget.onEdit(item);
                                              }
                                              if (value == "delete") {
                                                await _delete(item["id"]);
                                              }
                                            },
                                            itemBuilder: (_) => const [
                                              PopupMenuItem(
                                                  value: "edit",
                                                  child: Text("編集")),
                                              PopupMenuItem(
                                                  value: "delete",
                                                  child: Text("削除")),
                                            ],
                                          ),
                                      ],
                                    ),
                                    const Spacer(),
                                    Text(
                                      "${queue.length} 本・$sortModeName・$rangeLabel",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        _miniBadge(text: sortModeName),
                                        const SizedBox(width: 8),
                                        _miniBadge(text: rangeLabel),
                                      ],
                                    ),
                                  ],
                                ),
                              ),

                              Positioned(
                                right: 12,
                                bottom: 10,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(999),
                                  onTap: () => widget.onPlay(queue),
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color:
                                          Colors.black.withValues(alpha: 0.35),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white
                                            .withValues(alpha: 0.25),
                                        width: 1,
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      size: 22,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _editingBadge({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: const Text(
          "編集中",
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _miniBadge({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}
