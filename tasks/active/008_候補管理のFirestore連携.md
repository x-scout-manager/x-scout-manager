# 008 候補管理のFirestore連携

## 現状の動作

候補一覧・詳細は静的表示のみ。

## 期待する動作

Firestoreの `candidates` を一覧・詳細表示できる。

## 操作フロー

1. 候補一覧を開く
2. 候補が表示される
3. 候補詳細を開く
4. ステータスや送信可否を確認する

## UI参考（既存画面）

- `CandidateListPage`
- `CandidateDetailPage`

## 技術方針

候補抽出API実装前でも、手動/ダミーデータで表示確認できるようにする。

## 対象ファイル（推定）

- `lib/features/candidates/**`
- `lib/features/histories/**`
- `lib/app/router/**`

## 完了条件

- 候補一覧がFirestoreから表示される
- 詳細画面に遷移できる
- empty/loading/error状態がある

## レビュー指摘

未記入。

## 備考

X API候補抽出は後続タスク。
