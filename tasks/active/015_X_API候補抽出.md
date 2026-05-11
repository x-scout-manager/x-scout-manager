# 015 X API候補抽出

## 現状の動作

X APIから候補を抽出する `syncCandidates` が未実装。

## 期待する動作

指定タグから投稿主を抽出し、候補としてFirestoreへ保存できる。

## 操作フロー

1. タグ設定を保存
2. 候補抽出を実行
3. X APIで投稿検索
4. 投稿主ユーザーを取得
5. 除外・既送信・重複判定
6. candidatesへ保存

## UI参考（既存画面）

- `CandidateListPage`

## 技術方針

既送信者と除外対象を再候補化しない。

## 対象ファイル（推定）

- `functions/src/**`
- `lib/features/candidates/**`
- `docs/DETAIL_cloud_functions_design.md`

## 完了条件

- 指定タグから候補保存できる
- 除外キーワードが反映される
- function_logsに実行結果が残る

## レビュー指摘

未記入。

## 備考

X API検証完了後に着手。
