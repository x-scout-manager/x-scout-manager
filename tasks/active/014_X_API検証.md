# 014 X API検証

## 現状の動作

X APIの利用可否が未検証。

## 期待する動作

投稿検索、ユーザー取得、DM送信可否を判断できる。

## 操作フロー

1. X Developer Appを準備
2. OAuth 2.0 PKCEを検証
3. 投稿検索を検証
4. ユーザー取得を検証
5. DM送信を検証
6. API送信有効化可否を判断

## UI参考（既存画面）

なし。

## 技術方針

`docs/DETAIL_x_api_verification.md` に従う。

## 対象ファイル（推定）

- `docs/DETAIL_x_api_verification.md`
- `functions/src/**`
- 検証用スクリプト

## 完了条件

- 検証結果が記録されている
- `apiDmEnabled` の判断ができる
- 失敗時のMVP分岐が明確

## レビュー指摘

未記入。

## 備考

API DM送信はMVP必須にしない。
