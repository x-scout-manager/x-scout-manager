# 002 Firebaseプロジェクト基盤構築 レビュー

## セルフレビュー

- Firebase project idは `.firebaserc` で `x-scout-manager-prod` に固定されている。
- Hosting public directoryは Flutter Web の出力先 `build/web` を参照している。
- Firestore Rulesは未ログイン拒否、admin参照、重要書き込みFunctions限定の方針に沿っている。
- FunctionsはNode.js 20を指定し、TypeScript build/lint/testが通っている。
- グローバル `firebase` CLIはfirepitエラーのため、現時点では `npx firebase-tools` を利用する。
- Firebase CLIのログインユーザーが `attendanceappmeta@gmail.com` のため、deploy前に案件専用Googleアカウントへ切り替える必要がある。

## 残リスク

- Firebase Console側でAuthentication、Firestore、Functions、Hostingの有効化状態は未確認。
- Billing未確認のため、Functions deploy時に追加設定が必要になる可能性がある。
- ローカルNode.jsはv21.4.0で、Functions指定のNode.js 20と異なる。
