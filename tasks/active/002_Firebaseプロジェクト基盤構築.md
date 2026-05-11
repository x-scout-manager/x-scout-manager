# 002 Firebaseプロジェクト基盤構築

## 現状の動作

Firebaseプロジェクト `x-scout-manager-prod` は作成済み。

Hosting、Firestore、Functionsのローカル設定ファイルは作成済み。

Firebase CLIはグローバルの `firebase` コマンドがfirepitエラーになるため、現時点では `npx firebase-tools` を利用する。

2026-05-11時点でFirebase CLIは `attendanceappmeta@gmail.com` でログインされている。デプロイ前に案件専用Googleアカウントへログインを切り替える必要がある。

## 期待する動作

Firebase基盤が作成され、Flutter WebとCloud Functionsを接続できる準備が整う。

## 操作フロー

1. Firebaseプロジェクト作成
2. Authentication/Firestore/Hosting/Functions有効化
3. `.firebaserc` と `firebase.json` 作成
4. Emulator利用方針を決定
5. Functions TypeScript環境を作成
6. Firestore Rules/Indexesを作成
7. `npx firebase-tools use` で対象プロジェクトを確認

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

## 実施済み

- [x] `.firebaserc` 作成
- [x] `firebase.json` 作成
- [x] `firestore.rules` 作成
- [x] `firestore.indexes.json` 作成
- [x] `functions/` TypeScript構成作成
- [x] `functions` の依存関係をインストール
- [x] `npm run build` 成功
- [x] `npm run lint` 成功
- [x] `npm run test` 成功
- [x] `npx firebase-tools use` で `x-scout-manager-prod` を確認

## 残作業

- [ ] Firebase CLIログインを案件専用Googleアカウントへ切り替える
- [ ] Firebase ConsoleでAuthenticationを有効化する
- [ ] Firebase ConsoleでFirestoreを有効化する
- [ ] Firebase ConsoleでFunctions利用条件を確認する
- [ ] Firebase Hostingの初回deployを確認する

## レビュー指摘

未記入。

## 備考

クライアント所有または案件専用アカウントで作成する。

Cloud FunctionsはNode.js 20を指定する。ローカルNode.jsはv21.4.0のため `npm install` でengine警告が出るが、Functionsの実行環境は `functions/package.json` の `engines.node = 20` を正とする。
