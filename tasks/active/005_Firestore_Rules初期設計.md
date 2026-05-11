# 005 Firestore Rules初期設計

## 現状の動作

Firestore Rulesが未整備。

## 期待する動作

未ログインを拒否し、管理者のみ必要データを参照できる。

## 操作フロー

1. Rulesを作成
2. admin判定を追加
3. 重要コレクションの直接書き込みを制限
4. EmulatorまたはRules testで確認

## UI参考（既存画面）

なし。

## 技術方針

`docs/DETAIL_firestore_design.md` のSecurity Rules方針に従う。

## 対象ファイル（推定）

- `firestore.rules`
- `firestore.indexes.json`
- `docs/DETAIL_firestore_design.md`

## 完了条件

- 未ログインアクセスが拒否される
- adminユーザーのみreadできる
- `send_histories` 等の重要作成はFunctions経由方針になる

## レビュー指摘

未記入。

## 備考

Rulesを緩くしすぎない。
