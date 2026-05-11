# 002 Firebaseプロジェクト基盤構築

## 現状の動作

Firebaseプロジェクト、Hosting、Firestore、Functions環境が未作成。

## 期待する動作

Firebase基盤が作成され、Flutter WebとCloud Functionsを接続できる準備が整う。

## 操作フロー

1. Firebaseプロジェクト作成
2. Authentication/Firestore/Hosting/Functions有効化
3. `.firebaserc` と `firebase.json` 作成
4. Emulator利用方針を決定

## UI参考（既存画面）

なし。

## 技術方針

`docs/MVP_implementation_plan.md` フェーズ1に従う。

## 対象ファイル（推定）

- `.firebaserc`
- `firebase.json`
- `firestore.rules`
- `firestore.indexes.json`
- `functions/`
- `docs/lib_function_roles_full.md`

## 完了条件

- Firebase CLIで対象プロジェクトを参照できる
- Hosting/Firestore/Functionsの初期設定がある
- 空Functionsまたは初期Functionsをbuildできる

## レビュー指摘

未記入。

## 備考

クライアント所有または案件専用アカウントで作成する。
