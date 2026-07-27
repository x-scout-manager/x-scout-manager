# 033 候補抽出時のFirestore更新と再描画負荷削減

## 現状の動作

- `syncCandidates` は候補ごとにFirestore batchをcommitしている。
- 候補一覧のリアルタイム購読は各更新を受け、一覧全体をモデル化・再構築する。
- 候補抽出件数が多い場合、連続更新によって端末負荷が一時的に高くなる。

## 期待する動作

- 候補抽出時のFirestoreコミット回数を抑える。
- 候補一覧で必要以上の連続再取得・全体再描画を発生させない。
- 抽出結果、抽出差分、除外・既送信判定の整合性を維持する。

## 操作フロー

1. 管理者が候補一覧から候補抽出を実行する。
2. Functionsが候補を判定し、一定件数単位で安全に保存する。
3. 抽出完了後、候補一覧の必要なページだけを更新する。
4. 抽出結果と抽出履歴が表示される。

## UI参考（既存画面）

- `lib/features/candidates/view/pages/candidate_list_page.dart`
- `lib/features/candidates/vm/candidate_list_vm.dart`

## 技術方針

- Cloud Functionsの認証、X API通信、候補判定、Firestore更新の責務分離を維持する。
- Firestore batchの上限と `candidate_sync_runs/{runId}/changes` の同時保存を考慮してチャンク化する。
- 候補一覧はタスク032のページ単位取得を前提に、抽出完了後の明示更新を検討する。
- 送信履歴、除外対象、抽出解除用差分の整合性を崩さない。

## 対象ファイル（推定）

- `functions/src/candidates/sync_candidates.ts`
- `functions/src/candidates/candidate_sync_run_repository.ts`
- `lib/features/candidates/vm/candidate_list_vm.dart`
- Functionsテスト
- Flutterテスト
- 関連設計資料

## 完了条件

- 候補ごとの不要なcommitが削減される。
- 候補抽出結果と抽出解除用差分が従来どおり保存される。
- 送信済み・除外済み判定が維持される。
- 候補一覧が抽出完了後に更新される。
- Functions lint、build、testが通る。
- Flutterテストと `flutter analyze` が通る。

## レビュー指摘

- 候補抽出中の連続Firestore更新と一覧再構築がPWAの負荷を増幅する可能性がある。

## 備考

- タスク032完了後に、ページ取得方式に合わせて実装案を確定する。
