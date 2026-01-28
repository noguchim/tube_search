// Phase2対応(連続再生)
// SliverToBoxAdapter(
//   child: Padding(
//     padding: const EdgeInsets.only(top: 12, bottom: 8),
//     // ✅ 上下Margin
//     child: Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       // ✅ 横余白
//       child: SizedBox(
//         width: double.infinity, // ✅ 幅を広げる（親幅いっぱい）
//         child: ElevatedButton.icon(
//           onPressed: () async {
//             await showRepeatSettingsPanel(
//               context: context,
//               videos: videos,
//             );
//           },
//           icon: const Icon(
//             Icons.play_circle_fill_rounded, // ✅ アイコン
//             size: 22,
//           ),
//           label: const Text(
//             "連続再生を始める",
//             style: TextStyle(
//               fontSize: 16,
//               fontWeight: FontWeight.w800,
//               letterSpacing: 0.4,
//             ),
//           ),
//           style: ElevatedButton.styleFrom(
//             backgroundColor: const Color(0xFFE67E22),
//             // ✅ ボタン色
//             foregroundColor: Colors.white,
//             padding: const EdgeInsets.symmetric(vertical: 14),
//             // ✅ 高さ
//             elevation: 0,
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(12),
//             ),
//           ),
//         ),
//       ),
//     ),
//   ),
// ),
