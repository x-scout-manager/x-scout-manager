# 002 Firebaseプロジェクト基盤構築

## 現状の動作

Firebaseプロジェクト `x-scout-manager-prod` は作成済み。

Hosting、Firestore、Functionsのローカル設定ファイルは作成済み。

Firebase CLIはグローバルの `firebase` コマンドがfirepitエラーになるため、現時点では `npx firebase-tools` を利用する。

2026-05-11時点でFirebase CLIは案件専用Googleアカウント `xscout.manager.owner@gmail.com` へ切り替え済み。

Firebase Authenticationはメールアドレス/パスワードで有効化済み。

Firestoreは本番モード、東京リージョン `asia-northeast1` で作成済み。`npx firebase-tools firestore:databases:list --project x-scout-manager-prod` で `(default)` データベースを確認済み。

Firebase Web App `x-scout-manager-web` は作成済み。

Firebase Hostingはdefault site `x-scout-manager-prod` として有効化済み。URLは `https://x-scout-manager-prod.web.app`。

Firebase Hosting初回deployは完了済み。

Cloud Functions APIは有効化済み。

Blazeプランへアップグレード済み。

Cloud Build API、Artifact Registry API、Cloud Run API、Eventarc API、Firebase Extensions APIはFunctions初回deploy時に有効化済み。

Cloud Functions初回deployは完了済み。`healthCheck` と `adminHealthCheck` は `asia-northeast1` の 2nd Gen callable function として ACTIVE。

Artifact Registryの `gcf-artifacts` にはFirebase Functions用cleanup policyを設定済み。

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
- [x] Firebase CLIログインを案件専用Googleアカウントへ切り替え
- [x] Firebase ConsoleでAuthenticationをメールアドレス/パスワード有効化
- [x] Firebase ConsoleでFirestoreを本番モード・東京リージョンで有効化
- [x] Firebase Web App `x-scout-manager-web` を作成
- [x] Firebase Hosting default site `x-scout-manager-prod` を確認
- [x] Firebase Hosting初回deployを確認
- [x] Blazeプランへアップグレード
- [x] Cloud Functions APIを有効化
- [x] `npx firebase-tools functions:list` 成功
- [x] Cloud Build APIを有効化
- [x] Artifact Registry APIを有効化
- [x] Cloud Run APIを有効化
- [x] Eventarc APIを有効化
- [x] Firebase Extensions APIを有効化
- [x] Cloud Functions初回deploy成功
- [x] `healthCheck` と `adminHealthCheck` の ACTIVE を確認
- [x] Artifact Registry cleanup policyを設定

## 残作業

なし。

## レビュー指摘

未記入。

## 備考

クライアント所有または案件専用アカウントで作成する。

Cloud FunctionsはNode.js 20を指定する。ローカルNode.jsはv21.4.0のため `npm install` でengine警告が出るが、Functionsの実行環境は `functions/package.json` の `engines.node = 20` を正とする。

2026-05-11時点のdeployで、Node.js 20のdeprecation警告と `firebase-functions` の更新警告が出ている。後続のFunctions本実装前にNode.js 22移行と `firebase-functions` 更新を検討する。
