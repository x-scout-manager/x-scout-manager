# 016 API DM送信

## 現状の動作

X APIによるDM送信は実装済み。

2026-06-10時点で、デバッグXアカウントのOAuthアクセストークンで管理画面からの実送信を確認済み。
本番用Xアカウントでの送信確認は納品前必須にしない。

## 期待する動作

X API検証で利用可能と判断された場合のみ、管理者操作1回につき1件のDM送信ができる。

## 操作フロー

1. 送信キューを開く
2. テンプレートと本文を確認
3. APIでDM送信
4. X API送信成功
5. send_historiesへ保存
6. candidate/item/queueを更新

## UI参考（既存画面）

- `SendQueuePage`

## 技術方針

`sendDirectMessage` はtransactionで送信中ロックし、X API呼び出しはtransaction外で行う。

X API DM送信では `X_USER_ACCESS_TOKEN` と `X_USER_REFRESH_TOKEN` をSecret Managerから取得する。
アクセストークン期限切れ時はrefresh tokenで更新して再送信する。
失敗したqueue itemは `failed` にし、手動送信済み登録の対象に戻せるようにする。

## 対象ファイル（推定）

- `functions/src/**`
- `lib/features/send_queue/**`
- `lib/features/histories/**`

## 完了条件

- 1操作1送信のみ
- 二重クリックで重複送信されない
- 成功/失敗が履歴またはitem状態に残る
- `apiDmEnabled = false` の場合はUIで送信不可
- デバッグXアカウントで管理画面からDM送信できる

## レビュー指摘

2026-06-09: デバッグXアカウントでの実送信確認を先に行う。本番Xアカウント差し替えは引き継ぎ手順へ明記する。
2026-06-10: アクセストークン期限切れによりUnauthorizedが発生。refresh tokenによる再取得を追加した。

## 備考

X API検証で不可なら実装しない、または無効化したままにする。
