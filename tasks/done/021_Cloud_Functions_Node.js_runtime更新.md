# 021 Cloud Functions Node.js runtime更新

## 現状の動作

Cloud Functionsは `functions/package.json` で Node.js 20 runtime を指定している。

2026-05-18のFunctions deploy時に、Node.js 20 runtime が 2026-04-30 に非推奨化され、2026-10-30 に廃止予定である警告が出ている。

また、`firebase-functions` のバージョンが古いという警告も出ている。

## 期待する動作

Cloud Functionsを廃止予定ではないNode.js runtimeへ更新し、今後もFunctions deployできる状態にする。

## 操作フロー

1. Firebase/Google Cloud Functionsで利用可能なNode.js runtimeを確認する
2. `functions/package.json` の `engines.node` を更新する
3. `firebase-functions` 更新要否と破壊的変更を確認する
4. TypeScript build/lint/testを実行する
5. Functionsをdeployする
6. 主要Callable Functionの疎通を確認する

## UI参考（既存画面）

UI変更なし。

## 技術方針

Functions runtime更新は業務ロジック変更と分けて単独で行う。

Node.js 20廃止予定日は2026-10-30のため、期限前にNode.js 22以降へ更新する。

`firebase-functions` の更新は破壊的変更があり得るため、リリースノート確認後に実施する。

2026-05-18対応では、まず `engines.node` のみ `22` へ更新する。
`firebase-functions` の依存更新は破壊的変更リスクを避けるため、本タスクでは実施しない。

## 対象ファイル（推定）

- `functions/package.json`
- `functions/package-lock.json`
- `functions/src/index.ts`
- `docs/DETAIL_cloud_functions_design.md`
- `docs/lib_function_roles_full.md`

## 完了条件

- [x] Node.js runtimeが廃止予定ではないバージョンへ更新されている
- [x] `npm --prefix functions run build` が通る
- [x] `npm --prefix functions run lint` または同等のTypeScript確認が通る
- [x] `npm --prefix functions test` が通る
- [x] Functions deployが成功する
- [x] 主要Callable Functionの疎通確認が完了している

## レビュー指摘

- 2026-05-18: Functions deploy時にNode.js 20 runtimeの非推奨警告を確認。2026-10-30廃止予定のため後続タスク化。
- 2026-05-18: `functions/package.json` / `functions/package-lock.json` の `engines.node` を `22` へ更新。
- 2026-05-18: `npm --prefix functions run build`、`npm --prefix functions run lint`、`npm --prefix functions run test` が成功。
- 2026-05-18: `firebase deploy --only functions` が成功。9 functions deployed、0 functions errored。
- 2026-05-18: `healthCheck` のURLへ直接curlした場合は403。Callable Functionとしての画面経由疎通は別途確認する。
- 2026-05-18: アプリ画面から再度候補抽出と抽出解除が成功したため、主要Callable Functionの疎通確認完了。

## 備考

現時点のdeployは成功しているため、緊急障害ではない。
ただし廃止日以降はdeployできなくなる可能性があるため、016/020の前後で早めに実施する。
