# TUBE＋

# TODO_PHASE2.md

Phase2以降で実装・改善したいアイデアメモ
（リリース優先のため Phase1では触らない）

---

## 1. Header / AppBar のCool化（AppBar常設廃止案）

### 目的

- 画面の没入感UP
- Glass UIの統一感UP
- 「情報を主役」にして高級感を出す

### 案：タイトルは常設しない（アクションで表現）

- 画面遷移時に「人気急上昇」などのタイトル文字を表示
    - 背景透過
    - 下線付き
    - Slide in → 一定時間表示 → Slide out
- タイトル表示時間：0.8〜1.2秒程度
- タイトルは SafeArea を考慮し上部に配置

#### 追加案（任意）

- 上部タップ/引っ張りでタイトル再表示
- スクロール停止で一瞬だけタイトル再表示

---

## 2. Refresh UI の刷新（TikTok方式）

### 目的

- ヘッダから refresh ボタンを排除してUIをスッキリさせる
- 操作体験の統一（タブ再タップで更新）

### 仕様案

- BottomNavigationBar の「現在選択中タブ」を再タップすると refresh
- refresh中は、そのタブのアイコンがインジケータ表示に変化
- refresh完了後、通常アイコンに戻す

#### 追加案（任意）

- 1回目の再タップ：トップへスクロール
- すでにトップにいる状態での再タップ：更新

---

## 3. Header部品のOverlay化（Floating Widgets）

### 目的

- AppBar（横幅全体）をやめて、必要UIだけをガラスコンテナで浮かす
- 「必要なUIだけ見せる」方向へ

### 仕様案

- 画面上部に小さな黒透過コンテナを表示
    - 幅：中身のウィジェット幅 + margin
    - 角丸 + blur + border（薄め）
- そこに配置する候補：
    - 検索ボタン
    - フィルタ / 並び替え
    - 地域（JP/US）
    - info（更新日時）

### スクロール挙動

- スクロール中はフェードアウト or スライドアウトして消える
- スクロール停止でフェードイン（もしくは常時表示のままでも可）

---

## 4. 実装方針（Flutter）

### 構造案

- Stack 構成
    - 下：ListView / CustomScrollView
    - 上：Header Overlay（Positioned）

### アニメーション案

- AnimatedOpacity + SlideTransition
- ScrollController の offset で表示/非表示を制御

### 注意点

- SafeArea 必須（通知領域と被らない）
- iPhone SE等の小型端末での表示調整必須
- rebuild/アニメ過多で発熱しないように注意

---

## 5. リリース後の検討

- Phase1の実装との差分が大きいので段階導入する
- まずPopular画面のみ先行で導入 → 全画面へ展開

---
