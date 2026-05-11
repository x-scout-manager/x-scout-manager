# 016 API DM送信

## 現状の動作

X APIによるDM送信は未実装。

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

## 対象ファイル（推定）

- `functions/src/**`
- `lib/features/send_queue/**`
- `lib/features/histories/**`

## 完了条件

- 1操作1送信のみ
- 二重クリックで重複送信されない
- 成功/失敗が履歴またはitem状態に残る
- `apiDmEnabled = false` の場合はUIで送信不可

## レビュー指摘

未記入。

## 備考

X API検証で不可なら実装しない、または無効化したままにする。
