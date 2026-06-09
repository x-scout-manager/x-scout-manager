# 023 Cloud Functions構成整理

## 現状の動作

- `functions/src/index.ts` にCloud Functionsの処理本体、型定義、認証、入力検証、X API通信、Firestore更新処理が集約されている。
- `functions/src/index.ts` は1,300行を超えており、`syncCandidates`、`revertCandidateSyncRun`、送信キュー、送信済み登録、除外、成果登録が同一ファイルに混在している。
- 新しいFunctionsを追加するたびに `index.ts` がさらに肥大化する状態になっている。

## 期待する動作

- `functions/src/index.ts` はCallable Functionsのexport集約を主責務にする。
- 処理本体は機能別ディレクトリへ分離する。
- 認証、入力検証、X API通信、Firestore更新、差分記録などの共通処理を責務別に分ける。
- 既存のCallable名と外部仕様は変更しない。

## 操作フロー

1. 管理者が既存画面から候補抽出、抽出解除、送信キュー作成、手動送信済み登録、除外、復元、成果登録を実行する。
2. Flutter側の呼び出し先Callable名は変更しない。
3. 内部実装のみ責務別ファイルへ移動する。

## UI参考（既存画面）

- 候補一覧
- 送信キュー
- 送信履歴
- 除外リスト
- 成果記録画面

## 技術方針

- `functions/src/index.ts` はexport集約に寄せる。
- 新規または移動後の構成案:

```text
functions/src/
  index.ts
  app.ts
  auth/
    require_admin.ts
  shared/
    firebase.ts
    validators.ts
    errors.ts
    types.ts
  x/
    x_search.ts
  candidates/
    sync_candidates.ts
    revert_candidate_sync_run.ts
    candidate_sync_run_repository.ts
  send_queue/
    create_send_queue.ts
    mark_as_manually_sent.ts
  exclusions/
    exclude_candidate.ts
    restore_candidate.ts
  conversions/
    create_conversion.ts
```

- 既存の外部公開名は維持する。
  - `healthCheck`
  - `adminHealthCheck`
  - `syncCandidates`
  - `revertCandidateSyncRun`
  - `createSendQueue`
  - `markAsManuallySent`
  - `excludeCandidate`
  - `restoreCandidate`
  - `createConversion`
- まずは候補抽出系を優先して分離し、その後に送信キュー、除外、成果登録を分離する。
- 挙動変更を含めず、純粋な構成整理として進める。

## 対象ファイル（推定）

- `functions/src/index.ts`
- `functions/src/app.ts`
- `functions/src/auth/require_admin.ts`
- `functions/src/shared/firebase.ts`
- `functions/src/shared/types.ts`
- `functions/src/shared/validators.ts`
- `functions/src/shared/errors.ts`
- `functions/src/x/x_search.ts`
- `functions/src/candidates/sync_candidates.ts`
- `functions/src/candidates/revert_candidate_sync_run.ts`
- `functions/src/candidates/candidate_sync_run_repository.ts`
- `functions/src/send_queue/create_send_queue.ts`
- `functions/src/send_queue/mark_as_manually_sent.ts`
- `functions/src/exclusions/exclude_candidate.ts`
- `functions/src/exclusions/restore_candidate.ts`
- `functions/src/conversions/create_conversion.ts`
- `docs/DETAIL_cloud_functions_design.md`
- `docs/lib_function_roles_full.md`

## 完了条件

- [x] `functions/src/index.ts` がexport中心のファイルになっている。
- [x] 新規Functions実装方針が `AGENTS.md` に反映されている。
- [x] 既存のCallable名とFlutter側呼び出しが変更されていない。
- [x] Cloud FunctionsのTypeScript buildが通る。
- [x] 可能であればlint/testを実行し、結果を記録する。
- [x] ドキュメントにFunctions構成方針を反映する。

## レビュー指摘

- 2026-05-18: `functions/src/index.ts` が肥大化しているため、以後追加するFunctionsは外部ファイルへ配置する方針にしたい。
- 2026-05-18: `functions/src/index.ts` を8行のexport集約へ整理。各Callable本体を機能別ファイルへ分離。
- 2026-05-18: `npm --prefix functions run build`、`npm --prefix functions run lint`、`npm --prefix functions run test` 通過。
- 2026-05-18: `firebase deploy --only functions` 実行。9 Functions deployed、0 errored。

## 備考

- 本タスクは仕様追加ではなく保守性改善。
- 大きな差分になるため、まずは構成整理のみを行い、機能変更は別タスクで扱う。
