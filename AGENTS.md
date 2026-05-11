# AGENTS.md

## 実装ルール

- 実装を行うときは `docs/ARCHITECTURE_flutter_core_features_mvvm.md` に則ったファイル構造にすること。
- 要件は `docs/x_scout_tool_requirements.md` を正とすること。
- 基本設計は `docs/x_scout_tool_basic_design.md` を正とすること。
- Firestore実装は `docs/DETAIL_firestore_design.md` に従うこと。
- Cloud Functions実装は `docs/DETAIL_cloud_functions_design.md` に従うこと。
- Flutter画面実装は `docs/DETAIL_flutter_screen_design.md` に従うこと。
- X API検証は `docs/DETAIL_x_api_verification.md` に従うこと。
- MVPの実装順序は `docs/MVP_implementation_plan.md` に従うこと。
- アカウント、Gitリポジトリ、Firebase、Google Cloud、X Developer Appの所有・移管方針は `docs/account_repository_handover_policy.md` に従うこと。
- 既存のタスクは `docs/残タスク一覧.md` を参照すること。
- 実装に入る前に、対象コードと関連ドキュメントを調査し、実行方針をユーザーへ出力すること。
- 実装前フェーズでは「調査結果」「実装方針」「確認方法の提案」の出力までで止め、ユーザーの合意または指摘反映後に実装へ進むこと。
- 実装後はセルフレビューを行うこと。
- Flutter実装後は `flutter analyze` を行い、コマンドが通らない場合は原因を確認すること。
- Cloud Functions実装後は該当するTypeScriptのlint、build、testを実行すること。

## Xスカウトツール固有ルール

- DMの確認なし自動一括送信は実装しないこと。
- 一定時間間隔による自動連続DM送信は実装しないこと。
- 初期MVPでは、API送信よりも本文コピーと手動送信済み登録を優先すること。
- X APIによるDM送信は、疎通確認、権限確認、運用リスク確認が完了した場合のみ有効化すること。
- X APIトークン、シークレット、アクセストークンをFlutter Web側に保持しないこと。
- 開発者個人の普段使いGoogle/GitHub/Xアカウントで本番資産を作成しないこと。
- 納品先所有アカウントがない場合は、案件専用アカウントを新規作成し、納品時にクライアント管理へ移す前提にすること。
- 送信履歴、成果証跡、除外対象の作成・更新は原則Cloud Functions経由にすること。
- 二重送信防止はUIだけでなく、Cloud FunctionsとFirestore transactionで担保すること。
- `send_histories` は送信証跡の正本として扱うこと。
- `excluded_accounts` は除外対象の正本として扱うこと。

## タスク管理ルール

- タスク追加時は `docs/残タスク一覧.md` に追記すること。
- タスク追加時は `tasks/active/` 配下に `NNN_タスク名.md` を作成すること。
- `tasks/active/NNN_タスク名.md` には以下の見出しを必ず含めること。
  - 現状の動作
  - 期待する動作
  - 操作フロー
  - UI参考（既存画面）
  - 技術方針
  - 対象ファイル（推定）
  - 完了条件
  - レビュー指摘
  - 備考
- タスク追加時は `task-review/NNN_タスク名.md` の空ファイルを作成すること。
- ユーザーからの指摘は `task-review/NNN_タスク名.md` に記録し、対応時に `tasks/active/NNN_タスク名.md` の「レビュー指摘」へ反映すること。
- 修正後は再レビューを行い、同じタスク番号でレビューサイクルを継続すること。
- タスク完了時は `tasks/active/NNN_タスク名.md` を `tasks/done/NNN_タスク名.md` へ移動して保管すること。

## 実装フロー

1. 事前確認
2. 調査・実行方針の出力
3. 実装
4. セルフレビュー
5. 解析・確認
6. ドキュメント更新

### 1. 事前確認

- 対象タスクが `docs/残タスク一覧.md` にあることを確認する。
- 変更対象の責務が `docs/ARCHITECTURE_flutter_core_features_mvvm.md` のレイヤー定義と一致するか確認する。
- X API、Firebase、Firestore Rules、Cloud Functionsに関わる変更は `docs/x_scout_tool_basic_design.md` の補強設計と矛盾しないことを確認する。

### 2. 調査・実行方針の出力

- 実装対象ファイルと関連ファイルを調査し、現状挙動と制約を整理する。
- 実装前に、少なくとも以下をユーザーへ提示する。
  - 影響範囲（対象ファイル/関連機能）
  - 実行方針（実装順・採用案・代替案があれば理由）
  - 検証方針（最低限実行する確認コマンド）
  - 操作確認方法（どの画面で何を操作すれば確認できるか）
  - 仕様確認方法（期待値・判定観点・正常/異常系の確認ポイント）
- 仕様の未確定点や運用判断が必要な点がある場合は、「確認したいこと」として明示する。

### 3. 実装

- `view / vm / usecase / data / model` の責務分離を守る。
- FirestoreやCloud FunctionsへのアクセスはRepositoryに閉じる。
- 一時的な回避実装を入れる場合は、削除条件をコメントで残す。

### 4. セルフレビュー

- 仕様との乖離がないか確認する。
- 既存機能の回帰リスクがないか確認する。
- 命名、責務、依存方向がアーキテクチャ方針に反していないか確認する。
- 例外時のユーザー向けエラー表示が破綻していないか確認する。
- DM送信、送信履歴、成果証跡、除外状態の整合性が崩れていないか確認する。

### 5. 解析・確認

- Flutter実装では `flutter analyze` を実行する。
- Cloud Functions実装ではTypeScriptのlint、build、testを実行する。
- 解析エラーが残っている状態で完了扱いにしない。

### 6. ドキュメント更新

- 実装した内容は `docs/lib_function_roles_full.md` に追記する。
- 要件または設計に影響する変更は、該当する要件定義・基本設計・アーキテクチャ文書を更新する。
- タスク完了時は `docs/残タスク一覧.md` から該当項目を削除し、対応タスクを `tasks/done/` へ移動する。
