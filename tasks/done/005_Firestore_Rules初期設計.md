# 005 Firestore Rules初期設計

## 現状の動作

Firestore Rulesと複合インデックスは初期MVP方針で整備済み。

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

## 実施済み

- [x] 未ログインユーザーを拒否するRulesを作成
- [x] `users/{uid}` の `role = admin` かつ `isActive = true` でadmin判定
- [x] 管理者本人の `users/{uid}` 読み取りを許可
- [x] 重要コレクションのクライアント直接書き込みを拒否
- [x] `settings` / `templates` はadminのみread/write許可
- [x] 初期MVP向け複合インデックスを `firestore.indexes.json` に定義
- [x] 単一フィールド検索はFirestore標準単一フィールドインデックス利用に整理
- [x] Firebase CLIでRulesコンパイル成功
- [x] Firebase CLIでFirestore Rules/Indexesデプロイ成功

## レビュー指摘

未記入。

## 備考

Rulesを緩くしすぎない。

2026-05-12時点で複合インデックスは作成開始済み。Firestore側でREADYになるまで数分かかる場合がある。
